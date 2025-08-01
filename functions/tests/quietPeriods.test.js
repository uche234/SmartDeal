const test = require('node:test');
const assert = require('assert');
const { checkQuietPeriods } = require('../triggerHandlers');

test('detect quiet hours and low sales items', () => {
  const baseDate = new Date(Date.UTC(2023, 0, 1, 0, 0, 0));
  const salesData = [];
  for (let h = 0; h < 24; h++) {
    let total = 100;
    if (h === 4) total = 10;
    if (h === 20) total = 15;
    salesData.push({
      timestamp: new Date(baseDate.getTime() + h * 3600000),
      total,
      items: h < 12 ? [{ id: 'a', quantity: 1 }] : [],
    });
  }
  const inventoryData = [
    { id: 'a', quantity: 100 },
    { id: 'b', quantity: 20 },
  ];
  const result = checkQuietPeriods({ salesData, inventoryData });
  assert.deepEqual(result.quietHours.sort((a, b) => a - b), [4, 20]);
  const suggestedIds = result.suggestedItems.map((i) => i.itemId);
  assert.deepEqual(suggestedIds, ['b']);
});
