const { checkLoyaltyGap } = require('./triggerHandlers');

/**
 * Run smart deal triggers and return generated deals.
 * Each trigger execution is logged with the business id and
 * number of deals created. Errors are captured via console.error.
 */
async function runSmartDealTriggers(metrics = {}, context = {}) {
  const businessId = context.businessId || 'unknown';

  const triggers = [
    {
      name: 'loyalty_gap',
      async run() {
        return checkLoyaltyGap(businessId);
      },
    },
  ];

  const allDeals = [];

  for (const trigger of triggers) {
    try {
      const deals = await trigger.run(metrics, context);
      const count = Array.isArray(deals) ? deals.length : 0;
      console.log(
        `Trigger ${trigger.name} fired for ${businessId}, generated ${count} deals`
      );
      if (count > 0) {
        allDeals.push(...deals);
      }
    } catch (err) {
      console.error(`Trigger ${trigger.name} failed for ${businessId}:`, err);
    }
  }

  return allDeals;
}

module.exports = { runSmartDealTriggers };
