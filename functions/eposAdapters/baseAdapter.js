class BaseAdapter {
  async fetchSales(options = {}) {
    void options;
    throw new Error('fetchSales not implemented');
  }

  async fetchInventory(options = {}) {
    void options;
    throw new Error('fetchInventory not implemented');
  }

  async pushDeal(deal, options = {}) {
    void deal;
    void options;
    throw new Error('pushDeal not implemented');
  }

  async testConnection(options = {}) {
    void options;
    throw new Error('testConnection not implemented');
  }
}

module.exports = BaseAdapter;
