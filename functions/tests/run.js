const assert = require('assert');
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

async function testAdapter(provider) {
  const adapter = createAdapter(provider);
  const sales = await adapter.fetchSales({});
  assert(Array.isArray(sales), `${provider} fetchSales should return array`);
  const inventory = await adapter.fetchInventory({});
  assert(Array.isArray(inventory), `${provider} fetchInventory should return array`);
  const dealRes = await adapter.pushDeal({ id: 1 });
  assert(dealRes && dealRes.success, `${provider} pushDeal should report success`);
  const ok = await adapter.testConnection();
  assert.strictEqual(typeof ok, 'boolean', `${provider} testConnection should return boolean`);
}

(async () => {
  for (const p of providers) {
    await testAdapter(p);
  }
  console.log('All adapter tests passed');
})();
