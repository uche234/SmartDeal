/**
 * Export a factory for creating EPOS adapters based on the requested provider.
 */
const SquareAdapter = require('./square');
const LightspeedAdapter = require('./lightspeed');
const CloverAdapter = require('./clover');
const ToastAdapter = require('./toast');
const ShopifyAdapter = require('./shopify');
const VendAdapter = require('./vend');
const EposNowAdapter = require('./eposnow');

const adapters = {
  square: SquareAdapter,
  lightspeed: LightspeedAdapter,
  clover: CloverAdapter,
  toast: ToastAdapter,
  shopify: ShopifyAdapter,
  vend: VendAdapter,
  eposnow: EposNowAdapter,
};

function createAdapter(provider) {
  const AdapterClass = adapters[provider];
  if (!AdapterClass) {
    throw new Error(`Unsupported EPOS provider: ${provider}`);
  }
  return new AdapterClass();
}

module.exports = { createAdapter };
