// Entry point for SmartDeal Cloud Functions. Provides initialization,
// scheduled tasks and helper utilities used across the project.
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const csv = require('csv-parser');
const {Storage} = require('@google-cloud/storage');
const {v4: uuidv4} = require('uuid');
const pLimit = require('p-limit');
const {triggerHandlers, checkQuietPeriods} = require('./triggerHandlers');
const {createAdapter} = require('./eposAdapters');
const {runSmartDealTriggers} = require('./smartDealTriggers');

admin.initializeApp();
const storage = new Storage();

/**
 * Load the EPOS adapter configured for a business.
 * @param {string} businessId - ID of the business document.
 * @returns {Promise<object|null>} Adapter instance or null if none configured.
 */
async function loadEposAdapter(businessId) {
  try {
    const snap = await admin
      .firestore()
      .doc(`businesses/${businessId}/settings`)
      .collection('eposConfig')
      .limit(1)
      .get();

    if (snap.empty) {
      return null;
    }

    const config = snap.docs[0].data() || {};
    const provider = config.provider;
    if (!provider) {
      return null;
    }

    const adapter = createAdapter(provider);
    adapter.config = config;
    return adapter;
  } catch (err) {
    console.error(`Failed to load EPOS adapter for ${businessId}:`, err);
    return null;
  }
}

/**
 * Fetch sales and inventory metrics for a business.
 * @param {string} businessId - ID of the business.
 * @param {number} [days=7] - Number of days of history to retrieve.
 * @returns {Promise<{salesData:Array,inventoryData:Array,salesTotal:number,inventoryTotal:number}>}
 */
async function fetchEposMetrics(businessId, days = 7) {
  const adapter = await loadEposAdapter(businessId);
  let salesData = [];
  let inventoryData = [];

  if (adapter) {
    try {
      const since = new Date();
      since.setDate(since.getDate() - days);
      if (typeof adapter.fetchSales === 'function') {
        salesData = await adapter.fetchSales({ since });
      }
      if (typeof adapter.fetchInventory === 'function') {
        inventoryData = await adapter.fetchInventory({ since });
      }
    } catch (err) {
      const provider = adapter.constructor?.name || 'unknown';
      const message = err?.response?.data || err.message;
      console.error(`EPOS adapter ${provider} failed for ${businessId}:`, message);
    }
  }

  const salesTotal = Array.isArray(salesData)
    ? salesData.reduce((sum, s) => sum + (s.total || s.amount || 0), 0)
    : 0;
  const inventoryTotal = Array.isArray(inventoryData)
    ? inventoryData.reduce((sum, i) => sum + (i.quantity || 0), 0)
    : 0;

  return { salesData, inventoryData, salesTotal, inventoryTotal };
}

/**
 * Record a deal history entry for analytics.
 * @param {string} businessId - ID of the business.
 * @param {object} entry - Data describing the event.
 * @returns {Promise<void>}
 */
async function writeDealHistoryEntry(businessId, entry) {
  try {
    await admin
      .firestore()
      .collection('businesses')
      .doc(businessId)
      .collection('analytics')
      .doc('deals')
      .collection('history')
      .add(entry);
  } catch (err) {
    console.error(`Failed to log deal history for ${businessId}:`, err);
  }
}

/**
 * Log that a deal has been activated for a business.
 * @param {string} businessId - ID of the business.
 * @param {object} [entry={}] - Additional data about the activation.
 * @returns {Promise<void>}
 */
async function logDealActivation(businessId, entry = {}) {
  const data = {
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    ...entry,
  };
  await writeDealHistoryEntry(businessId, data);
}

async function fetchWeather(lat, lon) {
  const url =
    `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current_weather=true`;
  try {
    const res = await axios.get(url);
    return res.data?.current_weather?.temperature ?? null;
  } catch (err) {
    console.error('fetchWeather error:', err.message);
    return null;
  }
}

async function fetchUkHolidays() {
  try {
    const res = await axios.get('https://www.gov.uk/bank-holidays.json');
    const holidays = [];
    const regions = res.data || {};
    for (const key of Object.keys(regions)) {
      const events = regions[key]?.events || [];
      for (const ev of events) {
        if (ev && ev.date) holidays.push(ev.date);
      }
    }
    return holidays;
  } catch (err) {
    console.error('fetchUkHolidays error:', err.message);
    return [];
  }
}

exports.initializeBusinessRules = functions.firestore
  .document('businesses/{businessId}')
  .onCreate(async (snap, context) => {
    const businessId = context.params.businessId;
    const adapter = await loadEposAdapter(businessId);
    if (!adapter) {
      console.error(`initializeBusinessRules: missing EPOS config for ${businessId}`);
      return null;
    }

    const { salesData, inventoryData, salesTotal, inventoryTotal } =
      await fetchEposMetrics(businessId, 30);
    const avgDailySales = salesData.length > 0 ? salesTotal / 30 : 0;
    const avgInventory =
      inventoryData.length > 0 ? inventoryTotal / inventoryData.length : 0;

    const data = snap.data() || {};
    let upcomingHoliday = null;
    let temperature = null;
    try {
      const holidays = await fetchUkHolidays();
      const today = new Date();
      const next = holidays
        .map((h) => new Date(h))
        .filter((d) => !isNaN(d) && d >= today)
        .sort((a, b) => a - b)[0];
      if (next) {
        upcomingHoliday = next.toISOString().slice(0, 10);
      }
    } catch (err) {
      console.error('initializeBusinessRules holiday fetch error:', err.message);
    }
    try {
      const loc = data.businessLocation || data.location || data.lastLocation || null;
      if (loc && (loc.latitude ?? loc._latitude) != null) {
        const lat = loc.latitude ?? loc._latitude ?? loc.lat;
        const lon = loc.longitude ?? loc._longitude ?? loc.lon;
        if (lat != null && lon != null) {
          temperature = await fetchWeather(lat, lon);
        }
      }
    } catch (err) {
      console.error('initializeBusinessRules weather fetch error:', err.message);
    }

    let expirationThreshold = 7;
    if (upcomingHoliday || (typeof temperature === 'number' && temperature < 0)) {
      expirationThreshold = 3;
    }

    const rules = [
      { triggerType: 'low_sales', threshold: Math.round(avgDailySales * 0.5) },
      { triggerType: 'surplus_stock', threshold: Math.round(avgInventory * 1.2) },
      { triggerType: 'expiration_soon', threshold: expirationThreshold },
    ];

    const db = admin.firestore();
    const batch = db.batch();
    const ref = db
      .collection('businesses')
      .doc(businessId)
      .collection('ruleApprovals');
    for (const rule of rules) {
      batch.set(ref.doc(), { ...rule, approved: false });
    }
    try {
      await batch.commit();
    } catch (err) {
      console.error(`initializeBusinessRules failed for ${businessId}:`, err);
    }
    return null;
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

/**
 * Evaluate a list of business rules using provided metrics.
 * @param {Array} rules - The rule documents to evaluate.
 * @param {object} businessData - Sales and inventory metrics.
 * @returns {Array} Evaluation results with trigger status.
 */
function evaluateRulesInternal(rules = [], businessData = {}) {
  return rules.map((rule) => {
    const handler = triggerHandlers[rule.triggerType];
    const triggered = handler ? handler(businessData, rule) : false;
    return {
      ruleId: rule.documentId || rule.id || null,
      triggerType: rule.triggerType,
      triggered,
    };
  });
}

exports.evaluateRules = functions.https.onCall(async (data, context) => {
  const rules = Array.isArray(data.rules) ? data.rules : [];
  const businessData = data.businessData || {};

  const results = evaluateRulesInternal(rules, businessData);
  return { results };
});

/**
 * Assign a newly created deal to customers based on their preferences.
 * @param {string} dealId - ID of the deal document.
 * @param {object} dealData - Data describing the deal.
 * @returns {Promise<void>}
 */
async function assignDealsToUsersByPreferenceInternal(dealId, dealData) {
  const category = dealData?.rule?.category;
  const businessType = dealData?.businessType;
  const db = admin.firestore();

  const userMatches = new Map();

  const queries = [];

  if (category) {
    const q = db
      .collectionGroup('preferences')
      .where('interests', 'array-contains', category)
      .get()
      .then((snap) => {
        snap.forEach((doc) => {
          const userId = doc.ref.parent.parent && doc.ref.parent.parent.id;
          if (userId && !userMatches.has(userId)) {
            userMatches.set(userId, 'interest');
          }
        });
      })
      .catch((err) => {
        console.error(`Failed fetching interest users for deal ${dealId}:`, err);
      });
    queries.push(q);
  }

  if (businessType) {
    const q = db
      .collectionGroup('preferences')
      .where('preferredBusinessTypes', 'array-contains', businessType)
      .get()
      .then((snap) => {
        snap.forEach((doc) => {
          const userId = doc.ref.parent.parent && doc.ref.parent.parent.id;
          if (userId && !userMatches.has(userId)) {
            userMatches.set(userId, 'businessType');
          }
        });
      })
      .catch((err) => {
        console.error(`Failed fetching business type users for deal ${dealId}:`, err);
      });
    queries.push(q);
  }

  await Promise.all(queries);

  const batch = db.batch();
  userMatches.forEach((matchedBy, userId) => {
    const ref = db
      .collection('customer')
      .doc(userId)
      .collection('availableDeals')
      .doc(dealId);
    batch.set(ref, { ...dealData, matchedBy });
  });

  if (userMatches.size > 0) {
    try {
      await batch.commit();
    } catch (err) {
      console.error(`Failed committing deal batch for ${dealId}:`, err);
    }
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
      const businessId = after.userId;
      if (businessId) {
        const metrics = await fetchEposMetrics(businessId);
        await logDealActivation(businessId, { ruleId: after.ruleId, ...metrics });
      }
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

exports.loadEposAdapter = loadEposAdapter;

/**
 * Scheduled task that evaluates business rules weekly and generates active deals.
 * @returns {Promise<null>}
 */
exports.scheduledRuleCheck = functions.pubsub
  .schedule('every 7 days')
  .onRun(async () => {
    const db = admin.firestore();
    const businessesSnap = await db.collection('businesses').get();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();
    const limit = pLimit(5);

    async function processBusiness(businessDoc) {
      const businessId = businessDoc.id;
      try {
        let businessData = businessDoc.data() || {};

        const { salesTotal, inventoryTotal } = await fetchEposMetrics(businessId);

        businessData = {
          temperature: businessData.temperature ?? null,
          publicHolidays: businessData.publicHolidays ?? [],
          ...businessData,
          sales: salesTotal,
          stock: inventoryTotal,
        };

      let rules = [];
      try {
        const rulesSnap = await db
          .collection('businesses')
          .doc(businessId)
          .collection('rules')
          .get();
        rules = rulesSnap.docs.map((d) => ({ ...d.data(), documentId: d.id }));
      } catch (err) {
        console.error(`Failed to fetch rules for ${businessId}:`, err);
      }
      const results = evaluateRulesInternal(rules, businessData);

      for (const result of results) {
        if (!result.triggered) continue;
        const dealData = {
          ruleId: result.ruleId,
          triggerType: result.triggerType,
          triggeredAt: timestamp,
          salesTotal,
          inventoryTotal,
        };
        try {
          await db
            .collection('businesses')
            .doc(businessId)
            .collection('activeDeal')
            .add(dealData);
          console.log(
            `Trigger ${result.triggerType} fired for ${businessId}, generated 1 deal`
          );
        } catch (err) {
          console.error(`Failed to create activeDeal for ${businessId}:`, err);
        }
        try {
          await logDealActivation(businessId, {
            ruleId: result.ruleId,
            salesTotal,
            inventoryTotal,
          });
        } catch (err) {
          console.error(`Failed to log deal activation for ${businessId}:`, err);
        }
      }
      } catch (err) {
        console.error(`Error processing business ${businessId}:`, err);
      }
    }

    const tasks = businessesSnap.docs.map((doc) => limit(() => processBusiness(doc)));
    await Promise.all(tasks);

    return null;
  });

/**
 * Scheduled task that recalculates rule thresholds based on recent metrics.
 * Creates adjustment requests for business owners to approve.
 * @returns {Promise<null>}
 */
exports.scheduledRuleAdjustment = functions.pubsub
  .schedule('every 7 days')
  .onRun(async () => {
    const db = admin.firestore();
    const businessesSnap = await db.collection('businesses').get();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();
    const limit = pLimit(5);

    async function processBusiness(businessDoc) {
      const businessId = businessDoc.id;
      const {
        salesData,
        inventoryData,
        salesTotal,
        inventoryTotal,
      } = await fetchEposMetrics(businessId, 30);
      const avgDailySales = salesData.length > 0 ? salesTotal / 30 : 0;
      const avgInventory =
        inventoryData.length > 0 ? inventoryTotal / inventoryData.length : 0;

      let rules = [];
      try {
        const rulesSnap = await db
          .collection('businesses')
          .doc(businessId)
          .collection('rules')
          .get();
        rules = rulesSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
      } catch (err) {
        console.error(`Failed fetching rules for ${businessId}:`, err);
      }

      const batch = db.batch();
      let createdAdjustment = false;

      for (const rule of rules) {
        let newThreshold = rule.threshold;
        if (rule.triggerType === 'low_sales') {
          newThreshold = Math.round(avgDailySales * 0.5);
        } else if (rule.triggerType === 'surplus_stock') {
          newThreshold = Math.round(avgInventory * 1.2);
        }

        if (newThreshold !== rule.threshold) {
          const adjustRef = db
            .collection('businesses')
            .doc(businessId)
            .collection('ruleAdjustments')
            .doc();
          batch.set(adjustRef, {
            ruleId: rule.id,
            oldThreshold: rule.threshold,
            newThreshold,
            salesTotal,
            inventoryTotal,
            approved: false,
            createdAt: timestamp,
          });

          const ruleRef = db
            .collection('businesses')
            .doc(businessId)
            .collection('rules')
            .doc(rule.id);
          batch.update(ruleRef, { threshold: newThreshold });
          createdAdjustment = true;
        }
      }

      if (createdAdjustment) {
        try {
          const notifRef = db
            .collection('businesses')
            .doc(businessId)
            .collection('notifications')
            .doc();
          batch.set(notifRef, {
            createdAt: timestamp,
            type: 'rule_update',
            message: 'New rule adjustments pending approval',
          });
        } catch (err) {
          console.error(`Failed creating notification for ${businessId}:`, err);
        }
      }

      if (!createdAdjustment) return;
      try {
        await batch.commit();
      } catch (err) {
        console.error(`Failed applying rule adjustments for ${businessId}:`, err);
      }
    }

    const tasks = businessesSnap.docs.map((doc) => limit(() => processBusiness(doc)));
    await Promise.all(tasks);

    return null;
  });

/**
 * Daily task that builds smart deal suggestions for each business using
 * collected metrics and trigger logic.
 * @returns {Promise<null>}
 */
exports.generateSmartDeals = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const db = admin.firestore();
    const businessesSnap = await db.collection('businesses').get();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();
    const limit = pLimit(5);

    async function processBusiness(doc) {
      const businessId = doc.id;
      try {
        const metrics = await fetchEposMetrics(businessId);
        const deals = await runSmartDealTriggers(metrics, { businessId });
        const quietInfo = checkQuietPeriods(metrics);
        await db
          .collection('smartDeals')
          .doc(businessId)
          .set({ deals, quietInfo, updatedAt: timestamp, status: 'pending' });
        console.log(
          `generateSmartDeals processed ${businessId}, generated ${deals.length} deals`
        );
      } catch (err) {
        console.error(`Failed generating smart deals for ${businessId}:`, err);
      }
    }

    const tasks = businessesSnap.docs.map((d) => limit(() => processBusiness(d)));
    await Promise.all(tasks);

    return null;
  });

exports.updateExternalMetrics = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const db = admin.firestore();
    const businessesSnap = await db.collection('businesses').get();
    const holidays = await fetchUkHolidays();
    const limit = pLimit(5);

    async function processBusiness(doc) {
      const businessId = doc.id;
      const data = doc.data() || {};
      const loc =
        data.businessLocation || data.location || data.lastLocation || null;
      let temperature = null;
      if (loc && (loc.latitude ?? loc._latitude) != null) {
        const lat = loc.latitude ?? loc._latitude ?? loc.lat;
        const lon = loc.longitude ?? loc._longitude ?? loc.lon;
        if (lat != null && lon != null) {
          temperature = await fetchWeather(lat, lon);
        }
      }

      try {
        await db
          .collection('businesses')
          .doc(businessId)
          .set(
            {
              temperature,
              publicHolidays: holidays,
            },
            { merge: true }
          );
      } catch (err) {
        console.error(`updateExternalMetrics failed for ${businessId}:`, err);
      }
    }

    const tasks = businessesSnap.docs.map((d) => limit(() => processBusiness(d)));
    await Promise.all(tasks);

    return null;
  });


/**
 * Generate birthday deals for customers with birthdays today.
 * @param {FirebaseFirestore.Firestore} db - Firestore instance.
 * @returns {Promise<void>}
 */
async function generateBirthdayDealsInternal(db) {
  const snap = await db.collection('Customers').get();
  const today = new Date();
  const d = today.getUTCDate();
  const m = today.getUTCMonth();
  const timestamp = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();
  let count = 0;
  snap.forEach((doc) => {
    const data = doc.data() || {};
    let bd = data.birthDate;
    if (!bd) return;
    if (bd.toDate) bd = bd.toDate();
    else bd = new Date(bd);
    if (bd.getUTCDate() === d && bd.getUTCMonth() === m) {
      const ref = db
        .collection('Customers')
        .doc(doc.id)
        .collection('availableDeals')
        .doc();
      batch.set(ref, {
        type: 'birthday',
        promotion: 'Happy Birthday! Enjoy 20% off your next purchase.',
        createdAt: timestamp,
      });
      count++;
    }
  });
  if (count > 0) {
    await batch.commit();
  }
}

exports.generateBirthdayDealsInternal = generateBirthdayDealsInternal;

exports.generateBirthdayDeals = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const db = admin.firestore();
    await generateBirthdayDealsInternal(db);
    return null;
  });
