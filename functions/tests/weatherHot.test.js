const test = require('node:test');
const assert = require('assert');
const { triggerHandlers } = require('../triggerHandlers');

test('weather_hot fires when temperature meets threshold', () => {
  const rule = { threshold: 25 };
  assert.strictEqual(
    triggerHandlers.weather_hot({ temperature: 30 }, rule),
    true
  );
  assert.strictEqual(
    triggerHandlers.weather_hot({ temperature: 20 }, rule),
    false
  );
});
