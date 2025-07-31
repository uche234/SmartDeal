const BaseAdapter = require('./baseAdapter');

class LightspeedAdapter extends BaseAdapter {
  async fetchSales(options = {}) {
    return [];
  }

  async fetchInventory(options = {}) {
    return [];
  }

  async pushDeal(deal) {
    return { success: true, deal };
  }

  async testConnection() {
    return true;
  }
}

module.exports = LightspeedAdapter;
