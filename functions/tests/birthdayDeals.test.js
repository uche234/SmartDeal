const test = require('node:test');
const assert = require('assert');
const Module = require('module');
const originalLoad = Module._load;
Module._load = function(request, parent, isMain) {
  if (request === 'firebase-functions') {
    return {
      pubsub: { schedule: () => ({ onRun: () => {} }) },
      https: { onRequest: () => {}, onCall: () => {} },
      firestore: { document: () => ({ onCreate: () => {}, onWrite: () => {}, onUpdate: () => {} }) },
      storage: { object: () => ({ onFinalize: () => {} }) },
    };
  }
  if (request === 'firebase-admin') {
    return { initializeApp() {}, firestore: { FieldValue: { serverTimestamp: () => 'ts' } } };
  }
  if (request === '@google-cloud/storage') {
    return { Storage: class {} };
  }
  if (request === 'uuid') {
    return { v4: () => 'uuid' };
  }
  if (request === 'p-limit') {
    return () => (fn) => fn();
  }
  if (['axios', 'csv-parser'].includes(request)) {
    return {};
  }
  return originalLoad(request, parent, isMain);
};

const { generateBirthdayDealsInternal } = require('../index');

test('generate birthday deals for matching customers', async () => {
  const fixed = new Date('2023-05-12T00:00:00Z');
  const RealDate = Date;
  global.Date = class extends RealDate {
    constructor(...args) {
      if (args.length === 0) return new RealDate(fixed);
      return new RealDate(...args);
    }
    static now() { return fixed.getTime(); }
    static parse(str) { return RealDate.parse(str); }
    static UTC(...args) { return RealDate.UTC(...args); }
  };

  const customers = [
    { id: 'a', birthDate: new Date('1980-05-12') },
    { id: 'b', birthDate: new Date('1990-08-01') },
  ];
  const created = [];
  const db = {
    collection(name) {
      if (name !== 'Customers') throw new Error('unexpected collection');
      return {
        get: async () => ({
          forEach: (cb) => customers.forEach(c => cb({ id: c.id, data: () => c })),
        }),
        doc(id) {
          return {
            collection(sub) {
              return {
                doc() {
                  return { path: `Customers/${id}/${sub}/auto` };
                },
              };
            },
          };
        },
      };
    },
    batch() {
      const ops = [];
      return {
        set(ref, data) { ops.push({ ref, data }); },
        commit: async () => { created.push(...ops); },
      };
    },
  };

  await generateBirthdayDealsInternal(db);
  assert.strictEqual(created.length, 1);
  assert.strictEqual(created[0].ref.path, 'Customers/a/availableDeals/auto');
  assert.strictEqual(created[0].data.type, 'birthday');

  global.Date = RealDate;
});
