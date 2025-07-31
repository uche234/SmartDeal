const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const xml2js = require('xml2js');
const csv = require('csv-parser');
const {Storage} = require('@google-cloud/storage');
const {v4: uuidv4} = require('uuid');
const {triggerHandlers} = require('./triggerHandlers');

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

function buildAiSuggestions(keywords = []) {
  return keywords.map((word) => ({
    id: uuidv4(),
    title: `Smart deal for ${word}`,
    description: `Automatically generated suggestion for ${word}`,
  }));
}

exports.generateAISmartDealSuggestion = functions.https.onCall(async (data, context) => {
  const suggestions = buildAiSuggestions(data.keywords || []);
  return { suggestions };
});

// Expose AI recommendation hook for future integration
exports.aiRecommendation = functions.https.onCall(async (data, context) => {
  const suggestions = buildAiSuggestions(data.keywords || []);
  return { suggestions };
});

exports.evaluateRules = functions.https.onCall(async (data, context) => {
  const rules = Array.isArray(data.rules) ? data.rules : [];
  const businessData = data.businessData || {};

  const results = rules.map((rule) => {
    const handler = triggerHandlers[rule.triggerType];
    const triggered = handler ? handler(businessData, rule) : false;
    return {
      ruleId: rule.documentId || rule.id || null,
      triggerType: rule.triggerType,
      triggered,
    };
  });

  return { results };
});

async function assignDealsToUsersByPreferenceInternal(dealId, dealData) {
  const category = dealData?.rule?.category;
  const businessType = dealData?.businessType;
  const db = admin.firestore();

  const userMatches = new Map();

  if (category) {
    const interestSnap = await db
      .collection('users')
      .where('preferences.interests', 'array-contains', category)
      .get();
    interestSnap.forEach((doc) => {
      if (!userMatches.has(doc.id)) {
        userMatches.set(doc.id, 'interest');
      }
    });
  }

  if (businessType) {
    const typeSnap = await db
      .collection('users')
      .where('preferences.preferredBusinessTypes', 'array-contains', businessType)
      .get();
    typeSnap.forEach((doc) => {
      if (!userMatches.has(doc.id)) {
        userMatches.set(doc.id, 'businessType');
      }
    });
  }

  const batch = db.batch();
  userMatches.forEach((matchedBy, userId) => {
    const ref = db
      .collection('users')
      .doc(userId)
      .collection('availableDeals')
      .doc(dealId);
    batch.set(ref, { ...dealData, matchedBy });
  });

  if (userMatches.size > 0) {
    await batch.commit();
  }
}

exports.assignDealsToUsersByPreference = functions.firestore
  .document('Deals/{dealId}')
  .onWrite(async (change, context) => {
    if (!change.after.exists) return null;
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    const created = !change.before.exists;
    const statusActivated =
      before.status !== 'active' && after.status === 'active';
    if (created || statusActivated) {
      await assignDealsToUsersByPreferenceInternal(context.params.dealId, after);
    }
    return null;
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
      await assignDealsToUsersByPreferenceInternal(change.after.id, after);
      await change.after.ref.delete();
    }
    return null;
  });
