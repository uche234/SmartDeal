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
