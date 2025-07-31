class BaseAdapter {
  async fetchSales() {
    throw new Error('fetchSales not implemented');
  }

  async fetchInventory() {
    throw new Error('fetchInventory not implemented');
  }

  async pushDeal() {
    throw new Error('pushDeal not implemented');
  }

  async testConnection() {
    throw new Error('testConnection not implemented');
  }
}

module.exports = BaseAdapter;
