const test = require('node:test');
const assert = require('assert');
const { checkLoyaltyGap } = require('../triggerHandlers');

test('loyalty gap deals for inactive customers', async () => {
  const now = new Date('2023-01-15T00:00:00Z');
  const originalNow = Date.now;
  Date.now = () => now.getTime();

  const customers = [
    { id: 'cust1', lastPurchase: new Date('2022-12-31') },
    { id: 'cust2', lastPurchase: new Date('2023-01-10') },
  ];

  const db = {
    collection: () => ({
      doc: () => ({
        collection: () => ({
          where: (field, op, val) => ({
            get: async () => ({
              forEach: (cb) => {
                customers
                  .filter((c) => c.lastPurchase <= val)
                  .forEach((c) => cb({ id: c.id, data: () => c }));
              },
            }),
          }),
        }),
      }),
    }),
  };

  const deals = await checkLoyaltyGap('biz1', 14, db);
  assert.strictEqual(deals.length, 1);
  assert.strictEqual(deals[0].customerId, 'cust1');

  Date.now = originalNow;
});
