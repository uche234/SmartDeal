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

function checkQuietPeriods(metrics = {}) {
  const salesData = Array.isArray(metrics.salesData) ? metrics.salesData : [];
  const inventoryData = Array.isArray(metrics.inventoryData)
    ? metrics.inventoryData
    : [];

  const hourlyTotals = new Array(24).fill(0);
  const dayTotals = new Array(7).fill(0);

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

  const cutoff = new Date(Date.now() - days * oneDayMs);
  const snap = await db
    .collection('businesses')
    .doc(businessId)
    .collection('customers')
    .where('lastPurchase', '<=', cutoff)
    .get();

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
