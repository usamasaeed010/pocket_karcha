'use strict';

// Builds the text of the "new order" push for the shop owner. Kept free of
// Firebase so it can be unit tested (npm test).

const TEXT = {
  en: {
    newOrder: (n) => (n ? `New order #${n}` : 'New order'),
    newRequest: (n) => (n ? `New order request #${n}` : 'New order request'),
    items: (k) => (k === 1 ? '1 item' : `${k} items`),
    delivery: 'Delivery',
    pickup: 'Pickup',
    customer: 'Customer',
  },
  ur: {
    newOrder: (n) => (n ? `نیا آرڈر #${n}` : 'نیا آرڈر'),
    newRequest: (n) => (n ? `نئی آرڈر درخواست #${n}` : 'نئی آرڈر درخواست'),
    items: (k) => `${k} آئٹم`,
    delivery: 'ڈیلیوری',
    pickup: 'پک اپ',
    customer: 'گاہک',
  },
};

/** `Rs 1,700` / `Rs 99.50` — the same style as the app. */
function formatMoney(value, symbol) {
  const n = typeof value === 'number' && Number.isFinite(value) ? Math.max(0, value) : 0;
  const cents = Math.round(n * 100);
  const whole = Math.floor(cents / 100);
  const rest = cents % 100;
  const grouped = String(whole).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  const sym = typeof symbol === 'string' && symbol.trim() ? symbol.trim() : 'Rs';
  return rest === 0 ? `${sym} ${grouped}` : `${sym} ${grouped}.${String(rest).padStart(2, '0')}`;
}

function clip(text, max) {
  const t = String(text || '').replace(/\s+/g, ' ').trim();
  return t.length > max ? `${t.slice(0, max - 1)}…` : t;
}

/**
 * Title and body for one order, in the owner's language ('en' or 'ur').
 *
 * Normal order:  "New order #1042 · Rs 1,700" / "Ali · 3 items · Delivery"
 * Order request: "New order request #1043"    / "Ali · 2 kg mutton… · Pickup"
 */
function buildOrderNotification(order, { currencySymbol = 'Rs', lang = 'en' } = {}) {
  const t = TEXT[lang] || TEXT.en;
  const o = order || {};
  const number = String(o.number || '').trim();
  const items = Array.isArray(o.items) ? o.items : [];
  const isRequest = items.length === 0;
  const name = clip(o.customer && o.customer.name, 40) || t.customer;
  const way = o.fulfillment === 'delivery' ? t.delivery : t.pickup;

  if (isRequest) {
    return {
      title: t.newRequest(number),
      body: [name, clip(o.requestText, 80), way].filter(Boolean).join(' · '),
    };
  }
  const count =
    typeof o.itemCount === 'number' && o.itemCount > 0
      ? o.itemCount
      : items.reduce((sum, i) => sum + (Number(i && i.qty) || 0), 0);
  return {
    title: `${t.newOrder(number)} · ${formatMoney(o.total, currencySymbol)}`,
    body: [name, t.items(count), way].join(' · '),
  };
}

/** True when FCM says the token will never work again (app removed, etc.). */
function isDeadTokenError(error) {
  const code = error && (error.code || (error.errorInfo && error.errorInfo.code));
  return (
    code === 'messaging/registration-token-not-registered' ||
    code === 'messaging/invalid-registration-token'
  );
}

module.exports = { buildOrderNotification, formatMoney, isDeadTokenError };
