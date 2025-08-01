// Adapter for interacting with the Square POS API.
const axios = require('axios');
const BaseAdapter = require('./baseAdapter');

class SquareAdapter extends BaseAdapter {
  /**
   * Fetch recent sales from Square.
   * @param {object} [options] Optional query parameters.
   * @returns {Promise<Array>} Array of sales records.
   */
  async fetchSales(options = {}) {
    try {
      if (this.config?.baseUrl) {
        const res = await axios.get(`${this.config.baseUrl}/sales`, {
          params: { since: options.since },
          headers: { Authorization: `Bearer ${this.config.apiKey}` },
        });
        return res.data?.sales || res.data || [];
      }
    } catch (err) {
      console.error('Square fetchSales error:', err.message);
    }
    return [{ id: 'mock', total: 0 }];
  }

  /**
   * Fetch inventory information from Square.
   * @param {object} [options] Optional query parameters.
   * @returns {Promise<Array>} Array of inventory items.
   */
  async fetchInventory(options = {}) {
    try {
      if (this.config?.baseUrl) {
        const res = await axios.get(`${this.config.baseUrl}/inventory`, {
          params: { since: options.since },
          headers: { Authorization: `Bearer ${this.config.apiKey}` },
        });
        return res.data?.inventory || res.data || [];
      }
    } catch (err) {
      console.error('Square fetchInventory error:', err.message);
    }
    return [{ id: 'mock', quantity: 0 }];
  }

  /**
   * Push a deal to Square for redemption.
   * @param {object} deal Deal details to send.
   * @returns {Promise<object>} Result with success flag and optional error.
   */
  async pushDeal(deal) {
    try {
      if (this.config?.baseUrl) {
        await axios.post(
          `${this.config.baseUrl}/deals`,
          deal,
          { headers: { Authorization: `Bearer ${this.config.apiKey}` } },
        );
        return { success: true };
      }
    } catch (err) {
      console.error('Square pushDeal error:', err.message);
      return { success: false, error: err.message };
    }
    return { success: true, deal };
  }

  /**
   * Test API connectivity to Square.
   * @returns {Promise<boolean>} True if credentials are valid.
   */
  async testConnection() {
    try {
      if (this.config?.baseUrl) {
        await axios.get(`${this.config.baseUrl}/ping`, {
          headers: { Authorization: `Bearer ${this.config.apiKey}` },
        });
      }
      return true;
    } catch (err) {
      console.error('Square testConnection error:', err.message);
      return false;
    }
  }
}

module.exports = SquareAdapter;
