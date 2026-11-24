'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { buildOrderNotification, formatMoney, isDeadTokenError } = require('../order_notification');

const order = {
  number: '1042',
  source: 'link',
  fulfillment: 'delivery',
  customer: { name: 'Ali', phone: '03001234567' },
  items: [
    { name: 'Zinger', price: 500, qty: 2 },
    { name: 'Fries', price: 200, qty: 1 },
  ],
  itemCount: 3,
  total: 1350,
};

test('money looks like the app', () => {
  assert.equal(formatMoney(1700, 'Rs'), 'Rs 1,700');
  assert.equal(formatMoney(1234567.5, 'Rs'), 'Rs 1,234,567.50');
  assert.equal(formatMoney(99.999, 'AED'), 'AED 100');
  assert.equal(formatMoney(undefined, ''), 'Rs 0');
  assert.equal(formatMoney(-5, 'Rs'), 'Rs 0');
});

test('normal order in English', () => {
  const n = buildOrderNotification(order, { currencySymbol: 'Rs', lang: 'en' });
  assert.equal(n.title, 'New order #1042 · Rs 1,350');
  assert.equal(n.body, 'Ali · 3 items · Delivery');
});

test('normal order in Urdu', () => {
  const n = buildOrderNotification(order, { currencySymbol: 'Rs', lang: 'ur' });
  assert.equal(n.title, 'نیا آرڈر #1042 · Rs 1,350');
  assert.equal(n.body, 'Ali · 3 آئٹم · ڈیلیوری');
});

test('one item, pickup, no itemCount field', () => {
  const n = buildOrderNotification(
    { ...order, fulfillment: 'pickup', itemCount: undefined, items: [{ name: 'Tea', qty: 1, price: 80 }], total: 80 },
    { lang: 'en' },
  );
  assert.equal(n.title, 'New order #1042 · Rs 80');
  assert.equal(n.body, 'Ali · 1 item · Pickup');
});

test('order request shows the request text', () => {
  const n = buildOrderNotification(
    { ...order, items: [], total: 0, fulfillment: 'pickup', requestText: '  2 kg mutton\nkeema please ' },
    { lang: 'en' },
  );
  assert.equal(n.title, 'New order request #1042');
  assert.equal(n.body, 'Ali · 2 kg mutton keema please · Pickup');
});

test('long request text and missing name are handled', () => {
  const n = buildOrderNotification(
    { number: '', items: [], requestText: 'x'.repeat(200), customer: { name: ' ' } },
    { lang: 'en' },
  );
  assert.equal(n.title, 'New order request');
  assert.ok(n.body.startsWith('Customer · '));
  assert.ok(n.body.includes('…'));
});

test('unknown language falls back to English', () => {
  const n = buildOrderNotification(order, { lang: 'fr' });
  assert.equal(n.title, 'New order #1042 · Rs 1,350');
});

test('only permanently broken tokens are removed', () => {
  assert.equal(isDeadTokenError({ code: 'messaging/registration-token-not-registered' }), true);
  assert.equal(isDeadTokenError({ code: 'messaging/invalid-registration-token' }), true);
  assert.equal(isDeadTokenError({ code: 'messaging/internal-error' }), false);
  assert.equal(isDeadTokenError(undefined), false);
});
