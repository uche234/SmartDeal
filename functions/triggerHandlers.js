/**
 * Trigger handler utilities for SmartDeal.
 *
 * Each rule evaluated by `evaluateRules` specifies a `triggerType` that
 * maps to one of the functions exported in `triggerHandlers` below. The
 * handler receives a `businessData` object with metrics gathered from
 * external services and the rule configuration. It returns `true` when the
 * conditions for that rule are met.
 *
 * `businessData` may contain values such as:
 *   - `publicHolidays`: array of `YYYY-MM-DD` strings or `isPublicHoliday` boolean
 *   - `temperature`: numeric weather reading
 *   - `newsHeadlines`: array of headline strings
 *   - `stock`: quantity on hand
 *   - `expirationDate`: date of item expiration
 *   - `sales`: numeric sales total
 *   - `birthday`: Date or ISO string for the customer being evaluated
 *
 * A rule object typically looks like:
 *   {
 *     documentId: 'abc123',     // identifier used in results
 *     triggerType: 'weather_cold',
 *     threshold: 5,             // optional trigger specific fields
 *     keyword: 'holiday'
 *   }
 * Other fields may be present depending on the trigger. The important
 * requirement is the `triggerType` key which selects the handler.
 */

const oneDayMs = 24 * 60 * 60 * 1000;

function daysBetween(dateA, dateB) {
  const diff = dateA.getTime() - dateB.getTime();
  return Math.ceil(diff / oneDayMs);
}

module.exports.triggerHandlers = {
  public_holiday(data, rule) {
    if (Array.isArray(data.publicHolidays)) {
      const today = new Date().toISOString().slice(0, 10);
      return data.publicHolidays.includes(today);
    }
    return !!data.isPublicHoliday;
  },

  weather_cold(data, rule) {
    const temp = data.temperature;
    const threshold = typeof rule.threshold === 'number' ? rule.threshold : 0;
    return typeof temp === 'number' && temp <= threshold;
  },

  news_keyword(data, rule) {
    const keyword = rule.keyword || rule.key;
    const headlines = data.newsHeadlines || [];
    if (!keyword) return false;
    const lower = String(keyword).toLowerCase();
    return headlines.some(h => String(h).toLowerCase().includes(lower));
  },

  surplus_stock(data, rule) {
    const stock = data.stock;
    const threshold = typeof rule.threshold === 'number' ? rule.threshold : 0;
    return typeof stock === 'number' && stock > threshold;
  },

  expiration_soon(data, rule) {
    const exp = data.expirationDate;
    const threshold = typeof rule.threshold === 'number' ? rule.threshold : 0;
    if (!exp) return false;
    const expDate = exp instanceof Date ? exp : new Date(exp);
    const diff = daysBetween(expDate, new Date());
    return diff >= 0 && diff <= threshold;
  },

  low_sales(data, rule) {
    const sales = data.sales;
    const threshold = typeof rule.threshold === 'number' ? rule.threshold : 0;
    return typeof sales === 'number' && sales < threshold;
  },

  birthday(data) {
    const birthday = data.birthday;
    if (!birthday) return false;
    const bDate = birthday instanceof Date ? birthday : new Date(birthday);
    const today = new Date();
    return (
      bDate.getUTCDate() === today.getUTCDate() &&
      bDate.getUTCMonth() === today.getUTCMonth()
    );
  },
};

// Analyze sales and inventory metrics to identify low activity periods
// and items that might benefit from promotions.
//
// `metrics.salesData` should be an array of objects containing at least a
// timestamp and total amount for each sale. `metrics.inventoryData` lists
// current stock levels. The function returns the hours and days with sales
// below average as well as inventory items that sold less than 10% of their
// stock.
function checkQuietPeriods(metrics = {}) {
  const salesData = Array.isArray(metrics.salesData) ? metrics.salesData : [];
  const inventoryData = Array.isArray(metrics.inventoryData)
    ? metrics.inventoryData
    : [];

  const hourlyTotals = new Array(24).fill(0);
  const dayTotals = new Array(7).fill(0);

  // Sum sales totals for every hour and day of the week
  for (const sale of salesData) {
    const ts =
      sale.timestamp || sale.date || sale.time || sale.createdAt || sale.created;
    const amount = sale.total || sale.amount || 0;
    if (!ts) continue;
    const d = ts instanceof Date ? ts : new Date(ts);
    const hr = d.getHours();
    const day = d.getDay();
    hourlyTotals[hr] += amount;
    dayTotals[day] += amount;
  }

  // Calculate averages used as baselines for "quiet" detection
  const totalSales = hourlyTotals.reduce((a, b) => a + b, 0);
  const avgHourly = totalSales / 24 || 0;
  const avgDaily = totalSales / 7 || 0;

  const quietHours = hourlyTotals
    .map((v, i) => ({ hour: i, total: v }))
    .filter((h) => h.total < avgHourly * 0.5)
    .map((h) => h.hour);

  const quietDays = dayTotals
    .map((v, i) => ({ day: i, total: v }))
    .filter((d) => d.total < avgDaily * 0.8)
    .map((d) => d.day);

  // Track how many of each inventory item has been sold
  const itemSalesMap = Object.create(null);
  for (const sale of salesData) {
    const items = Array.isArray(sale.items) ? sale.items : [];
    for (const item of items) {
      const id = item.id || item.sku;
      if (!id) continue;
      const qty = item.quantity || 1;
      itemSalesMap[id] = (itemSalesMap[id] || 0) + qty;
    }
  }

  // Suggest products that have sold less than 10% of current stock
  const lowSalesItems = [];
  for (const item of inventoryData) {
    const id = item.id || item.sku;
    if (!id) continue;
    const stock = item.quantity || 0;
    const sold = itemSalesMap[id] || 0;
    if (stock > 0 && sold < stock * 0.1) {
      lowSalesItems.push({ itemId: id, stock, sold });
    }
  }

  return { quietHours, quietDays, suggestedItems: lowSalesItems };
}

module.exports.checkQuietPeriods = checkQuietPeriods;

// Find customers who haven't purchased within the specified number of days
// and generate loyalty deals to entice them back. If no Firestore instance is
// supplied the function will attempt to initialise one on the fly.
async function checkLoyaltyGap(businessId, days = 14, db) {
  if (!db) {
    try {
      // Delay requiring admin until runtime so the module can be used without Firebase initialized
      const admin = require('firebase-admin');
      db = admin.firestore();
    } catch (err) {
      throw new Error('Firestore instance required');
    }
  }

  // Look for customers whose last purchase is older than the cutoff date
  const cutoff = new Date(Date.now() - days * oneDayMs);
  const snap = await db
    .collection('businesses')
    .doc(businessId)
    .collection('customers')
    .where('lastPurchase', '<=', cutoff)
    .get();

  // Build a simple incentive for each inactive customer returned
  const deals = [];
  snap.forEach((doc) => {
    deals.push({
      customerId: doc.id,
      discount: 0.1,
      bonusPoints: 50,
      message:
        'Thanks for being a customer! Enjoy 10% off and 50 bonus points on your next visit.',
    });
  });

  return deals;
}

module.exports.checkLoyaltyGap = checkLoyaltyGap;
