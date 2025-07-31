const SquareAdapter = require('./square');

const adapters = {
  square: SquareAdapter,
};

function createAdapter(provider) {
  const AdapterClass = adapters[provider];
  if (!AdapterClass) {
    throw new Error(`Unsupported EPOS provider: ${provider}`);
  }
  return new AdapterClass();
}

module.exports = { createAdapter };
