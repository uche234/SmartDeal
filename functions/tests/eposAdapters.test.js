const test = require('node:test');
const assert = require('assert');
const path = require('path');
// Intercept requires for external deps like axios and return local mocks
const Module = require('module');
const originalLoad = Module._load;
Module._load = function(request, parent, isMain) {
  if (request === 'axios') {
    return require(path.join(__dirname, 'mocks', 'axios'));
  }
  return originalLoad(request, parent, isMain);
};
// Add mocks directory to search path for any other modules if needed
module.paths.push(path.join(__dirname, 'mocks'));
const { createAdapter } = require('../eposAdapters');

const providers = [
  'square',
  'lightspeed',
  'clover',
  'toast',
  'shopify',
  'vend',
  'eposnow',
];

for (const provider of providers) {
  test(`adapter ${provider} basic methods`, async () => {
    const adapter = createAdapter(provider);
    adapter.config = {};
    const sales = await adapter.fetchSales({});
    assert(Array.isArray(sales), `${provider} fetchSales should return array`);
    assert(sales.length > 0, `${provider} fetchSales should not be empty`);
    const inventory = await adapter.fetchInventory({});
    assert(Array.isArray(inventory), `${provider} fetchInventory should return array`);
    assert(inventory.length > 0, `${provider} fetchInventory should not be empty`);
    const dealRes = await adapter.pushDeal({ id: 1 });
    assert(dealRes && dealRes.success, `${provider} pushDeal should report success`);
    const ok = await adapter.testConnection();
    assert.strictEqual(typeof ok, 'boolean', `${provider} testConnection should return boolean`);
  });
}
