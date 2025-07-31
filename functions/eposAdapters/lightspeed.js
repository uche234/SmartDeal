const axios = require('axios');
const BaseAdapter = require('./baseAdapter');

class LightspeedAdapter extends BaseAdapter {
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
      console.error('Lightspeed fetchSales error:', err.message);
    }
    return [{ id: 'mock', total: 0 }];
  }

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
      console.error('Lightspeed fetchInventory error:', err.message);
    }
    return [{ id: 'mock', quantity: 0 }];
  }

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
      console.error('Lightspeed pushDeal error:', err.message);
      return { success: false, error: err.message };
    }
    return { success: true, deal };
  }

  async testConnection() {
    try {
      if (this.config?.baseUrl) {
        await axios.get(`${this.config.baseUrl}/ping`, {
          headers: { Authorization: `Bearer ${this.config.apiKey}` },
        });
      }
      return true;
    } catch (err) {
      console.error('Lightspeed testConnection error:', err.message);
      return false;
    }
  }
}

module.exports = LightspeedAdapter;
