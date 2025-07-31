const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const xml2js = require('xml2js');
const csv = require('csv-parser');
const {Storage} = require('@google-cloud/storage');
const {v4: uuidv4} = require('uuid');

admin.initializeApp();
const storage = new Storage();

exports.fetchExternalData = functions.https.onRequest(async (req, res) => {
  try {
    const response = await axios.get('https://example.com/data.xml');
    const parsed = await xml2js.parseStringPromise(response.data);
    res.json(parsed);
  } catch (err) {
    console.error('fetchExternalData error:', err);
    res.status(500).send(err.message);
  }
});

exports.processCsvUpload = functions.storage.object().onFinalize(async (object) => {
  if (!object.name.endsWith('.csv')) return null;
  const rows = [];
  const bucket = storage.bucket(object.bucket);
  return new Promise((resolve, reject) => {
    bucket
      .file(object.name)
      .createReadStream()
      .pipe(csv())
      .on('data', (data) => rows.push(data))
      .on('end', () => {
        console.log('Processed CSV rows:', rows.length);
        resolve();
      })
      .on('error', reject);
  });
});

exports.evaluateSmartDeals = functions.https.onCall(async (data, context) => {
  const deals = data.deals || [];
  const evaluated = deals.map((deal) => ({
    ...deal,
    id: uuidv4(),
    score: Math.random(),
  }));
  return { evaluated };
});

exports.generateAISmartDealSuggestion = functions.https.onCall(async (data, context) => {
  const keywords = data.keywords || [];
  const suggestions = keywords.map((word) => ({
    id: uuidv4(),
    title: `Smart deal for ${word}`,
    description: `Automatically generated suggestion for ${word}`,
  }));
  return { suggestions };
});

exports.dispatchNotifications = functions.firestore
  .document('PendingDeals/{dealId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    if (!before.approved && after.approved) {
      const tokensSnap = await admin
        .firestore()
        .collection('Tokens')
        .where('type', '==', 'customer')
        .get();
      const tokens = tokensSnap.docs
        .map((doc) => doc.data().token)
        .filter((t) => !!t);
      if (tokens.length > 0) {
        const message = {
          notification: {
            title: after.promotion || 'New Deal',
            body: after.description || '',
          },
          tokens,
        };
        await admin.messaging().sendMulticast(message);
      }
      await admin.firestore().collection('Deals').doc(change.after.id).set(after);
      await change.after.ref.delete();
    }
    return null;
  });
