const BaseAdapter = require('./baseAdapter');

class SquareAdapter extends BaseAdapter {
  async fetchSales() {
    // return stubbed sales data
    return [];
  }

  async fetchInventory() {
    // return stubbed inventory data
    return [];
  }

  async pushDeal(deal) {
    // pretend to push a deal
    return { success: true, deal };
  }

  async testConnection() {
    // always succeed for stub
    return true;
  }
}

module.exports = SquareAdapter;
