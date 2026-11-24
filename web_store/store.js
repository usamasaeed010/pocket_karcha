// Pocket Karcha — customer order page.
// Reads a shop's public menu from Firestore, lets the buyer build a cart and
// sends the order to the shop (saved in Firestore + a WhatsApp message).

import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js';
import {
  getFirestore,
  connectFirestoreEmulator,
  doc,
  getDoc,
  collection,
  getDocs,
  writeBatch,
  updateDoc,
  increment,
  serverTimestamp,
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js';
import {
  getAuth,
  connectAuthEmulator,
  signInAnonymously,
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js';
import {
  initializeAppCheck,
  ReCaptchaEnterpriseProvider,
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-app-check.js';

const CONFIG = window.PK_CONFIG || {};
const PLAY_URL =
  CONFIG.playStoreUrl ||
  'https://play.google.com/store/apps/details?id=com.pocket.karcha.expense.manager';
const SLUG_RE = /^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$/;
// A shop's own Hosting site (e.g. chill-n-chaat.web.app) always opens that shop.
const SITE_SHOP = (() => {
  const map = CONFIG.siteShops;
  const slug = map && typeof map === 'object' ? map[location.hostname.toLowerCase()] : '';
  return typeof slug === 'string' && SLUG_RE.test(slug) ? slug : '';
})();
const EMULATOR_HOSTS = ['localhost', '127.0.0.1', '10.0.2.2'];
const MAX_QTY = 999;
const LAST_ORDER_TTL = 30 * 60 * 1000;
const params = new URLSearchParams(location.search);
// ?nowa=1 → do not jump to WhatsApp after sending (testing only).
const NO_WA = params.get('nowa') === '1';
// Spam limits, enforced by firestore.rules (orderGuards). Keep in sync.
const ORDER_COOLDOWN_MS = 30 * 1000;
const ORDER_DAY_MS = 24 * 60 * 60 * 1000;
const ORDERS_PER_DAY = 20;
// A person needs a few seconds to pick items and fill the form; bots don't.
const MIN_HUMAN_MS = 3000;
// The server checks the 30 s wait with its own clock; phone clocks drift a little.
const CLOCK_SLACK_MS = 3000;

// ---------------------------------------------------------------------------
// Strings
// ---------------------------------------------------------------------------

const STRINGS = {
  en: {
    secure: 'Your order goes straight to WhatsApp',
    delivery: 'Delivery',
    pickup: 'Pickup',
    minOrderChip: 'Min. order {x}',
    freeAboveChip: 'Free delivery over {x}',
    search: 'Search items',
    add: 'Add',
    added: '{n} added',
    outOfStock: 'Out of stock',
    from: 'from {x}',
    each: 'each',
    items: ({ n }) => (n === 1 ? '1 item' : `${n} items`),
    sendOrder: 'Send Order',
    writeOrder: 'Write your order',
    pausedTitle: 'Orders are paused',
    pausedDefault: "We're not taking orders right now. You can still look at the menu.",
    noMatch: 'No items match “{q}”',
    emptyMenu: 'No items yet. Please check back soon.',
    yourOrder: 'Your order',
    yourRequest: 'What would you like?',
    requestIntro: "Write what you'd like. The shop will confirm the price on WhatsApp.",
    requestPlaceholder: 'e.g. 2 mango shakes, 1 large fruit chaat',
    requestTotalNote: 'The shop will confirm the total on WhatsApp.',
    howGet: 'How do you want it?',
    deliveryDesc: 'We bring it to you',
    pickupDesc: 'You collect it from the shop',
    pickupFrom: 'Pick up from: {x}',
    deliveryArea: 'We deliver to: {x}',
    subtotal: 'Subtotal',
    deliveryFee: 'Delivery',
    free: 'Free',
    total: 'Total',
    freeUnlocked: 'You get free delivery 🎉',
    addForFree: 'Add {x} more for free delivery',
    minOrderNote: 'Minimum order is {x}. Add {y} more to send.',
    details: 'Your details',
    name: 'Your name',
    phone: 'Phone number',
    phoneHint: 'The shop will reply on this number',
    address: 'Delivery address',
    addressHint: 'House, street, area',
    note: 'Note for the shop',
    notePlaceholder: 'Anything the shop should know?',
    optional: 'optional',
    required: 'Please fill this in',
    invalidPhone: 'Enter a valid phone number',
    sendWhatsApp: 'Send order on WhatsApp',
    sendRequest: 'Send request on WhatsApp',
    sending: 'Sending…',
    fixFields: 'Please check the highlighted fields',
    orderSent: 'Order sent',
    requestSent: 'Request sent',
    orderNo: 'Order #{n}',
    sentHint: 'Finish sending the message in WhatsApp. The shop will reply to you there.',
    sentHintNoWa: 'The shop has your order and will contact you soon.',
    writeFailed:
      "We couldn't save the order online, but your WhatsApp message has all the details.",
    waitToSend: 'You just sent an order. Please wait {s} sec and send again.',
    tooManyOrders: 'Too many orders from this phone today. Please message the shop on WhatsApp.',
    openWhatsApp: 'Open WhatsApp again',
    backToStore: 'Back to store',
    chooseOption: 'Choose an option',
    done: 'Done',
    close: 'Close',
    decrease: 'Decrease',
    increase: 'Increase',
    notFoundTitle: 'Store not found',
    notFoundBody:
      'This link may be wrong, or the shop changed it. Ask the shop for their latest link.',
    landingTitle: 'Make your own order link',
    landingBody:
      'Add what you sell, share one link, and get neat orders on WhatsApp — with Pocket Karcha.',
    getApp: 'Get Pocket Karcha',
    loadError: "Couldn't load this store. Check your internet and try again.",
    retry: 'Try again',
    madeWith: 'Made with Pocket Karcha',
    orderOnline: 'Order online',
    // WhatsApp message
    waHello: "Hi {store}, I'd like to place an order 🛒",
    waOrder: 'Order #{n}',
    waSubtotal: 'Subtotal',
    waDelivery: 'Delivery',
    waTotal: 'Total',
    waDeliverTo: '🛵 Delivery to: {x}',
    waPickup: '🛍️ Pickup',
  },
  ur: {
    secure: 'آپ کا آرڈر سیدھا واٹس ایپ پر جاتا ہے',
    delivery: 'ڈیلیوری',
    pickup: 'پک اپ',
    minOrderChip: 'کم از کم آرڈر {x}',
    freeAboveChip: '{x} سے زیادہ پر مفت ڈیلیوری',
    search: 'آئٹم تلاش کریں',
    add: 'شامل کریں',
    added: '{n} شامل',
    outOfStock: 'ختم ہو گیا',
    from: '{x} سے شروع',
    each: 'فی عدد',
    items: ({ n }) => `${n} آئٹم`,
    sendOrder: 'آرڈر بھیجیں',
    writeOrder: 'اپنا آرڈر لکھیں',
    pausedTitle: 'آرڈر فی الحال بند ہیں',
    pausedDefault: 'ابھی ہم آرڈر نہیں لے رہے۔ آپ مینو دیکھ سکتے ہیں۔',
    noMatch: '“{q}” سے کوئی آئٹم نہیں ملا',
    emptyMenu: 'ابھی کوئی آئٹم نہیں۔ کچھ دیر بعد دوبارہ دیکھیں۔',
    yourOrder: 'آپ کا آرڈر',
    yourRequest: 'آپ کیا منگوانا چاہتے ہیں؟',
    requestIntro: 'جو چاہیے لکھ دیں۔ دکان واٹس ایپ پر قیمت کنفرم کرے گی۔',
    requestPlaceholder: 'مثلاً 2 مینگو شیک، 1 بڑی فروٹ چاٹ',
    requestTotalNote: 'کل رقم دکان واٹس ایپ پر کنفرم کرے گی۔',
    howGet: 'آرڈر کیسے لیں گے؟',
    deliveryDesc: 'ہم آپ تک پہنچائیں گے',
    pickupDesc: 'آپ دکان سے لے جائیں',
    pickupFrom: 'یہاں سے لیں: {x}',
    deliveryArea: 'ڈیلیوری علاقہ: {x}',
    subtotal: 'سب ٹوٹل',
    deliveryFee: 'ڈیلیوری',
    free: 'مفت',
    total: 'کل',
    freeUnlocked: 'آپ کو مفت ڈیلیوری مل گئی 🎉',
    addForFree: 'مفت ڈیلیوری کے لیے {x} کا اور شامل کریں',
    minOrderNote: 'کم از کم آرڈر {x} ہے۔ بھیجنے کے لیے {y} کا اور شامل کریں۔',
    details: 'آپ کی معلومات',
    name: 'آپ کا نام',
    phone: 'فون نمبر',
    phoneHint: 'دکان اسی نمبر پر جواب دے گی',
    address: 'ڈیلیوری کا پتہ',
    addressHint: 'مکان، گلی، علاقہ',
    note: 'دکان کے لیے نوٹ',
    notePlaceholder: 'کوئی خاص بات؟',
    optional: 'اختیاری',
    required: 'یہ لازمی ہے',
    invalidPhone: 'درست فون نمبر لکھیں',
    sendWhatsApp: 'واٹس ایپ پر آرڈر بھیجیں',
    sendRequest: 'واٹس ایپ پر درخواست بھیجیں',
    sending: 'بھیجا جا رہا ہے…',
    fixFields: 'نشان زدہ خانے درست کریں',
    orderSent: 'آرڈر بھیج دیا گیا',
    requestSent: 'درخواست بھیج دی گئی',
    orderNo: 'آرڈر #{n}',
    sentHint: 'واٹس ایپ میں پیغام بھیج دیں۔ دکان وہیں آپ کو جواب دے گی۔',
    sentHintNoWa: 'دکان کو آپ کا آرڈر مل گیا ہے، جلد رابطہ کریں گے۔',
    writeFailed: 'آرڈر آن لائن محفوظ نہیں ہو سکا، لیکن واٹس ایپ پیغام میں پوری تفصیل موجود ہے۔',
    waitToSend: 'آپ نے ابھی آرڈر بھیجا ہے۔ {s} سیکنڈ رک کر دوبارہ بھیجیں۔',
    tooManyOrders: 'آج اس فون سے بہت آرڈر آ چکے ہیں۔ دکان کو واٹس ایپ پر میسج کریں۔',
    openWhatsApp: 'واٹس ایپ دوبارہ کھولیں',
    backToStore: 'دکان پر واپس جائیں',
    chooseOption: 'ایک آپشن منتخب کریں',
    done: 'ٹھیک ہے',
    close: 'بند کریں',
    decrease: 'کم کریں',
    increase: 'بڑھائیں',
    notFoundTitle: 'دکان نہیں ملی',
    notFoundBody: 'یہ لنک غلط ہو سکتا ہے یا دکان نے بدل دیا ہے۔ دکان سے نیا لنک لیں۔',
    landingTitle: 'اپنا آرڈر لنک بنائیں',
    landingBody:
      'جو بیچتے ہیں وہ شامل کریں، ایک لنک شیئر کریں، اور واٹس ایپ پر صاف ستھرے آرڈر پائیں — Pocket Karcha کے ساتھ۔',
    getApp: 'Pocket Karcha حاصل کریں',
    loadError: 'دکان لوڈ نہیں ہو سکی۔ انٹرنیٹ چیک کر کے دوبارہ کوشش کریں۔',
    retry: 'دوبارہ کوشش کریں',
    madeWith: 'Pocket Karcha سے بنایا گیا',
    orderOnline: 'آن لائن آرڈر',
    waHello: 'السلام علیکم {store}، مجھے یہ آرڈر دینا ہے 🛒',
    waOrder: 'آرڈر #{n}',
    waSubtotal: 'سب ٹوٹل',
    waDelivery: 'ڈیلیوری',
    waTotal: 'کل',
    waDeliverTo: '🛵 ڈیلیوری کا پتہ: {x}',
    waPickup: '🛍️ دکان سے لیں گے',
  },
};

let lang = 'en';

function setLang(code) {
  lang = code === 'ur' ? 'ur' : 'en';
  document.documentElement.lang = lang;
  document.documentElement.dir = lang === 'ur' ? 'rtl' : 'ltr';
}

function t(key, vars = {}) {
  const dict = STRINGS[lang] || STRINGS.en;
  const value = dict[key] ?? STRINGS.en[key] ?? key;
  if (typeof value === 'function') return value(vars);
  return value.replace(/\{(\w+)\}/g, (m, k) => (vars[k] ?? m));
}

// ---------------------------------------------------------------------------
// DOM helpers (no innerHTML for shop data — everything is text nodes)
// ---------------------------------------------------------------------------

function h(tag, props, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(props || {})) {
    if (v == null || v === false) continue;
    if (k === 'class') el.className = v;
    else if (k === 'value') el.value = v;
    else if (k.startsWith('on') && typeof v === 'function') {
      el.addEventListener(k.slice(2).toLowerCase(), v);
    } else if (k in el && typeof v !== 'string') el[k] = v;
    else el.setAttribute(k, v === true ? '' : String(v));
  }
  for (const c of children.flat(Infinity)) {
    if (c == null || c === false) continue;
    el.append(c instanceof Node ? c : document.createTextNode(String(c)));
  }
  return el;
}

const ICONS = {
  search:
    '<path d="M10.5 3a7.5 7.5 0 0 1 5.96 12.05l4.25 4.24-1.42 1.42-4.24-4.25A7.5 7.5 0 1 1 10.5 3Zm0 2a5.5 5.5 0 1 0 0 11 5.5 5.5 0 0 0 0-11Z"/>',
  minus: '<path d="M5 11h14v2H5z"/>',
  plus: '<path d="M11 5h2v6h6v2h-6v6h-2v-6H5v-2h6z"/>',
  chevron: '<path d="M9.3 5.3 15.99 12l-6.7 6.7-1.4-1.42L13.17 12 7.88 6.7z"/>',
  close:
    '<path d="m6.4 5 5.6 5.6L17.6 5 19 6.4 13.4 12l5.6 5.6-1.4 1.4-5.6-5.6L6.4 19 5 17.6l5.6-5.6L5 6.4z"/>',
  check: '<path d="m9.5 16.2-4.2-4.2-1.4 1.4 5.6 5.6 11-11-1.4-1.4z"/>',
  send: '<path d="M3.4 20.4 21 12 3.4 3.6v6.4l12.6 2-12.6 2z"/>',
};

// Icons are constant markup (never shop data), so innerHTML is safe here.
function icon(name, size = 20) {
  const span = h('span', {
    class: 'ico',
    'aria-hidden': 'true',
    style: `display:inline-flex;width:${size}px;height:${size}px`,
  });
  span.innerHTML = `<svg viewBox="0 0 24 24" width="${size}" height="${size}" fill="currentColor">${ICONS[name]}</svg>`;
  return span;
}

const app = document.getElementById('app');

function mount(...nodes) {
  app.replaceChildren(...nodes);
  window.scrollTo(0, 0);
}

// ---------------------------------------------------------------------------
// Firebase
// ---------------------------------------------------------------------------

let db = null;
let auth = null;
let buyerPromise = null;

function initDb() {
  if (db) return db;
  const fb = CONFIG.firebase || {};
  const local = EMULATOR_HOSTS.includes(location.hostname);
  const firebaseApp = initializeApp({
    apiKey: fb.apiKey,
    authDomain: fb.authDomain,
    projectId: fb.projectId || 'pocket-karcha-new',
    ...(fb.appId ? { appId: fb.appId } : {}),
    ...(fb.messagingSenderId ? { messagingSenderId: fb.messagingSenderId } : {}),
  });
  // App Check proves requests come from this page in a real browser. It is
  // only on when a reCAPTCHA Enterprise site key is set in config.js (and
  // never on the emulators, which ignore it).
  if (!local && CONFIG.appCheckSiteKey && fb.appId) {
    try {
      initializeAppCheck(firebaseApp, {
        provider: new ReCaptchaEnterpriseProvider(CONFIG.appCheckSiteKey),
        isTokenAutoRefreshEnabled: true,
      });
    } catch (e) {
      console.warn('[pk] App Check is off', e);
    }
  }
  db = getFirestore(firebaseApp);
  auth = getAuth(firebaseApp);
  if (local) {
    connectFirestoreEmulator(db, location.hostname, 8080);
    connectAuthEmulator(auth, `http://${location.hostname}:9099`, { disableWarnings: true });
  }
  return db;
}

// The buyer's anonymous sign-in. It lets firestore.rules limit how often
// one buyer can order. The same uid comes back on later visits.
function ensureBuyer() {
  if (!buyerPromise) {
    buyerPromise = (async () => {
      await auth.authStateReady();
      if (auth.currentUser) return auth.currentUser;
      return (await signInAnonymously(auth)).user;
    })().catch((e) => {
      buyerPromise = null;
      throw e;
    });
  }
  return buyerPromise;
}

function withTimeout(promise, ms) {
  return Promise.race([
    promise,
    new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), ms)),
  ]);
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

const S = {
  storeId: null,
  store: null,
  products: [],
  cart: new Map(), // `${productId}::${variant}` -> { productId, name, variant, price, qty }
  fulfillment: 'pickup',
  search: '',
  sending: false,
  form: { name: '', phone: '', address: '', note: '', requestText: '', answers: {} },
  cardRefs: new Map(),
  groupRefs: [],
  ui: {},
  sheet: null,
  checkout: null,
  ignorePop: false,
};

const round2 = (n) => Math.round(n * 100) / 100;
const lineKey = (productId, variant = '') => `${productId}::${variant}`;

function money(value) {
  const n = round2(Number(value) || 0);
  const fractional = !Number.isInteger(n);
  const text = n.toLocaleString('en-US', {
    minimumFractionDigits: fractional ? 2 : 0,
    maximumFractionDigits: fractional ? 2 : 0,
  });
  const symbol = S.store ? S.store.currencySymbol : 'Rs';
  return `${symbol} ${text}`;
}

function normalizeStore(d, slug) {
  const num = (v) => (typeof v === 'number' && Number.isFinite(v) ? Math.max(0, v) : 0);
  const str = (v) => (typeof v === 'string' ? v.trim() : '');
  const customFields = Array.isArray(d.customFields)
    ? d.customFields
        .filter((f) => f && typeof f.label === 'string' && f.label.trim())
        .slice(0, 20)
        .map((f, i) => ({
          id: str(f.id) || `f${i}`,
          label: f.label.trim().slice(0, 80),
          required: f.required === true,
        }))
    : [];
  return {
    name: str(d.name) || 'Shop',
    slug: str(d.slug) || slug,
    about: str(d.about),
    whatsapp: str(d.whatsapp).replace(/\D/g, ''),
    currencySymbol: str(d.currencySymbol) || 'Rs',
    isLive: d.isLive === true,
    pausedMessage: str(d.pausedMessage),
    orderMode: d.orderMode === 'request' ? 'request' : 'cart',
    deliveryEnabled: d.deliveryEnabled === true,
    deliveryFee: num(d.deliveryFee),
    freeDeliveryAbove: num(d.freeDeliveryAbove),
    deliveryArea: str(d.deliveryArea),
    pickupEnabled: d.pickupEnabled === true,
    pickupAddress: str(d.pickupAddress),
    minOrder: num(d.minOrder),
    askNote: d.askNote === true,
    customFields,
    pageLanguage: d.pageLanguage === 'ur' ? 'ur' : 'en',
  };
}

function normalizeProduct(id, d) {
  const variants = Array.isArray(d.variants)
    ? d.variants
        .filter(
          (v) =>
            v &&
            typeof v.name === 'string' &&
            v.name.trim() &&
            typeof v.price === 'number' &&
            Number.isFinite(v.price),
        )
        .map((v) => ({ name: v.name.trim(), price: Math.max(0, v.price) }))
    : [];
  return {
    id,
    name: typeof d.name === 'string' && d.name.trim() ? d.name.trim() : 'Item',
    price: typeof d.price === 'number' && Number.isFinite(d.price) ? Math.max(0, d.price) : 0,
    description: typeof d.description === 'string' ? d.description.trim() : '',
    category: typeof d.category === 'string' ? d.category.trim() : '',
    inStock: d.inStock !== false,
    sortOrder: typeof d.sortOrder === 'number' ? d.sortOrder : 0,
    variants,
  };
}

// Same as the app's Firestore query: sortOrder, then document id.
function byOrder(a, b) {
  return a.sortOrder - b.sortOrder || (a.id < b.id ? -1 : a.id > b.id ? 1 : 0);
}

// ---------------------------------------------------------------------------
// Storage (per-viewer conveniences only; every access is guarded)
// ---------------------------------------------------------------------------

function storageGet(store, key) {
  try {
    return store.getItem(key);
  } catch (_) {
    return null;
  }
}

function storageSet(store, key, value) {
  try {
    store.setItem(key, value);
    return true;
  } catch (_) {
    return false;
  }
}

function storageRemove(store, key) {
  try {
    store.removeItem(key);
  } catch (_) {
    /* ignore */
  }
}

function session() {
  try {
    return window.sessionStorage;
  } catch (_) {
    return null;
  }
}

function local() {
  try {
    return window.localStorage;
  } catch (_) {
    return null;
  }
}

function restoreBuyer() {
  const ls = local();
  if (!ls) return;
  try {
    const saved = JSON.parse(storageGet(ls, 'pk_buyer') || 'null');
    if (saved && typeof saved === 'object') {
      S.form.name = typeof saved.name === 'string' ? saved.name : '';
      S.form.phone = typeof saved.phone === 'string' ? saved.phone : '';
      S.form.address = typeof saved.address === 'string' ? saved.address : '';
    }
  } catch (_) {
    /* ignore */
  }
}

function rememberBuyer() {
  const ls = local();
  if (!ls) return;
  storageSet(
    ls,
    'pk_buyer',
    JSON.stringify({ name: S.form.name, phone: S.form.phone, address: S.form.address }),
  );
}

function saveLastOrder(summary) {
  const ss = session();
  if (ss) storageSet(ss, `pk_last_${S.storeId}`, JSON.stringify(summary));
}

function readLastOrder() {
  const ss = session();
  if (!ss) return null;
  try {
    const v = JSON.parse(storageGet(ss, `pk_last_${S.storeId}`) || 'null');
    if (v && typeof v.at === 'number' && Date.now() - v.at < LAST_ORDER_TTL) return v;
  } catch (_) {
    /* ignore */
  }
  return null;
}

function clearLastOrder() {
  const ss = session();
  if (ss) storageRemove(ss, `pk_last_${S.storeId}`);
}

// ---------------------------------------------------------------------------
// Link counters (opens / carts / sent) — failures are ignored
// ---------------------------------------------------------------------------

function bump(field) {
  if (!db || !S.storeId) return;
  updateDoc(doc(db, 'storeStats', S.storeId), { [field]: increment(1) }).catch((e) =>
    console.debug('[pk] counter', field, e && e.code),
  );
}

function bumpOnce(field) {
  const ss = session();
  const key = `pk_${field}_${S.storeId}`;
  if (ss) {
    if (storageGet(ss, key)) return;
    storageSet(ss, key, '1');
  }
  bump(field);
}

// ---------------------------------------------------------------------------
// Boot
// ---------------------------------------------------------------------------

function readSlug() {
  if (SITE_SHOP) return SITE_SHOP;
  let fromPath = location.pathname.replace(/^\/+|\/+$/g, '').split('/')[0] || '';
  try {
    fromPath = decodeURIComponent(fromPath);
  } catch (_) {
    /* keep raw */
  }
  if (fromPath === 'index.html' || fromPath === 'index') fromPath = '';
  return (fromPath || params.get('s') || '').trim().toLowerCase();
}

async function main() {
  const slug = readSlug();
  if (!slug) {
    renderLanding();
    return;
  }
  if (!SLUG_RE.test(slug)) {
    renderNotFound(slug);
    return;
  }
  await loadStore(slug);
}

async function loadStore(slug) {
  renderLoading();
  try {
    initDb();
    const slugSnap = await getDoc(doc(db, 'slugs', slug));
    const storeId = slugSnap.exists() ? slugSnap.data().storeId : null;
    if (!storeId || typeof storeId !== 'string') {
      renderNotFound(slug);
      return;
    }
    const [storeSnap, productSnap] = await Promise.all([
      getDoc(doc(db, 'stores', storeId)),
      getDocs(collection(db, 'stores', storeId, 'products')),
    ]);
    if (!storeSnap.exists() || storeSnap.data().deleted === true) {
      renderNotFound(slug);
      return;
    }
    S.storeId = storeId;
    S.store = normalizeStore(storeSnap.data(), slug);
    S.products = productSnap.docs
      .map((d) => normalizeProduct(d.id, d.data()))
      .sort(byOrder);
  } catch (e) {
    console.error('[pk] could not load store', e);
    renderError(slug);
    return;
  }

  setLang(S.store.pageLanguage);
  document.title = `${S.store.name} · ${t('orderOnline')}`;
  restoreBuyer();
  S.fulfillment = availableModes()[0];
  const last = readLastOrder();
  if (last) renderSuccess(last);
  else renderStore();
  bumpOnce('opens');
  // Sign in early so sending the order is quick. Failures are handled when sending.
  ensureBuyer().catch((e) => console.debug('[pk] sign-in', e && e.code));
}

// ---------------------------------------------------------------------------
// Cart
// ---------------------------------------------------------------------------

function cartLines() {
  return [...S.cart.values()];
}

function cartCount() {
  return cartLines().reduce((sum, l) => sum + l.qty, 0);
}

function cartSubtotal() {
  return round2(cartLines().reduce((sum, l) => sum + l.price * l.qty, 0));
}

function qtyOf(productId, variant = '') {
  const line = S.cart.get(lineKey(productId, variant));
  return line ? line.qty : 0;
}

function productCount(productId) {
  let n = 0;
  for (const l of S.cart.values()) if (l.productId === productId) n += l.qty;
  return n;
}

function setQty(product, variant, qty, price) {
  const key = lineKey(product.id, variant);
  const q = Math.max(0, Math.min(MAX_QTY, Math.floor(qty)));
  if (q === 0) {
    S.cart.delete(key);
  } else {
    const line = S.cart.get(key);
    if (line) line.qty = q;
    else {
      S.cart.set(key, { productId: product.id, name: product.name, variant, price, qty: q });
      bumpOnce('carts');
    }
  }
  onCartChanged(product);
}

function onCartChanged(product) {
  if (product) renderCardAction(product);
  updateBar();
  if (S.sheet && typeof S.sheet.refresh === 'function') S.sheet.refresh();
}

function availableModes() {
  const modes = [];
  if (S.store.deliveryEnabled) modes.push('delivery');
  if (S.store.pickupEnabled) modes.push('pickup');
  return modes.length ? modes : ['pickup'];
}

function deliveryFeeFor(subtotal) {
  const st = S.store;
  if (st.orderMode === 'request' || S.fulfillment !== 'delivery') return 0;
  if (st.freeDeliveryAbove > 0 && subtotal >= st.freeDeliveryAbove) return 0;
  return round2(st.deliveryFee);
}

// ---------------------------------------------------------------------------
// Store page
// ---------------------------------------------------------------------------

function renderStore() {
  closeSheet({ silent: true });
  const st = S.store;
  S.cardRefs.clear();
  S.groupRefs = [];
  S.search = '';

  const wrap = h('div', { class: 'wrap' });
  const page = h('main', { class: 'page' }, wrap);

  wrap.append(
    h(
      'header',
      { class: 'store-head' },
      h('div', { class: 'secure-line' }, h('span', { 'aria-hidden': 'true' }, '🔒'), t('secure')),
      h('h1', { class: 'store-name' }, st.name),
      st.about ? h('p', { class: 'store-about' }, st.about) : null,
      renderChips(),
      h('div', { class: 'flourish', 'aria-hidden': 'true' }, '✦'),
    ),
  );

  if (!st.isLive) wrap.append(pausedBanner());

  const input = h('input', {
    type: 'search',
    placeholder: t('search'),
    'aria-label': t('search'),
    autocomplete: 'off',
    enterkeyhint: 'search',
  });
  input.addEventListener('input', () => {
    S.search = input.value;
    applySearch();
  });
  if (S.products.length > 3) {
    wrap.append(h('div', { class: 'search-row' }, h('label', { class: 'search' }, icon('search', 18), input)));
  }

  const menu = h('div', { class: 'menu' });
  buildMenu(menu);
  wrap.append(menu);

  S.ui.noMatch = h('p', { class: 'empty-note', hidden: true });
  wrap.append(S.ui.noMatch, footer());

  mount(page, buildBar());
  updateBar();
}

function renderChips() {
  const st = S.store;
  const chips = [];
  if (st.deliveryEnabled) chips.push(h('span', { class: 'chip' }, '🛵 ', t('delivery')));
  if (st.pickupEnabled) chips.push(h('span', { class: 'chip' }, '🛍️ ', t('pickup')));
  if (st.orderMode === 'cart' && st.minOrder > 0) {
    chips.push(h('span', { class: 'chip' }, t('minOrderChip', { x: money(st.minOrder) })));
  }
  if (st.orderMode === 'cart' && st.deliveryEnabled && st.freeDeliveryAbove > 0 && st.deliveryFee > 0) {
    chips.push(h('span', { class: 'chip' }, t('freeAboveChip', { x: money(st.freeDeliveryAbove) })));
  }
  return chips.length ? h('div', { class: 'chips' }, chips) : null;
}

function pausedBanner() {
  return h(
    'div',
    { class: 'paused', role: 'status' },
    h('div', { class: 'paused-icon', 'aria-hidden': 'true' }, '⏸'),
    h(
      'div',
      {},
      h('p', { class: 'paused-title' }, t('pausedTitle')),
      h('p', { class: 'paused-body' }, S.store.pausedMessage || t('pausedDefault')),
    ),
  );
}

// Same order as the owner's Menu in the app: a heading starts whenever the
// category changes, so no item moves.
function groupProducts(products) {
  const out = [];
  for (const p of products) {
    const key = p.category.toLowerCase();
    const last = out[out.length - 1];
    if (last && last.key === key) last.items.push(p);
    else out.push({ key, title: p.category, items: [p] });
  }
  return out;
}

function buildMenu(menu) {
  menu.replaceChildren();
  if (!S.products.length) {
    menu.append(h('p', { class: 'empty-note' }, t('emptyMenu')));
    return;
  }
  for (const g of groupProducts(S.products)) {
    const list = h('div', { class: 'list' }, g.items.map(buildCard));
    const section = h(
      'section',
      { class: 'group' },
      g.title ? h('h2', { class: 'group-title' }, g.title) : null,
      list,
    );
    S.groupRefs.push({ section, items: g.items });
    menu.append(section);
  }
}

function buildCard(p) {
  const action = h('div', { class: 'item-action' });
  const card = h(
    'article',
    { class: 'item' },
    h(
      'div',
      { class: 'item-main' },
      h('h3', { class: 'item-name' }, p.name),
      p.description ? h('p', { class: 'item-desc' }, p.description) : null,
      priceLine(p),
    ),
    action,
  );
  S.cardRefs.set(p.id, { card, action, product: p });
  renderCardAction(p);
  return card;
}

function priceLine(p) {
  if (p.variants.length) {
    const min = Math.min(...p.variants.map((v) => v.price));
    return h('p', { class: 'item-price' }, t('from', { x: money(min) }));
  }
  return h('p', { class: 'item-price' }, money(p.price), h('span', { class: 'unit' }, t('each')));
}

function renderCardAction(p) {
  const ref = S.cardRefs.get(p.id);
  if (!ref) return;
  const { card, action } = ref;
  const st = S.store;
  action.replaceChildren();
  card.classList.toggle('oos', !p.inStock);

  if (!p.inStock) {
    card.classList.remove('selected');
    action.append(h('span', { class: 'oos-tag' }, t('outOfStock')));
    return;
  }
  if (st.orderMode === 'request') {
    card.classList.remove('selected');
    return;
  }
  const count = productCount(p.id);
  card.classList.toggle('selected', count > 0);

  if (!st.isLive) {
    action.append(h('button', { class: 'btn-add', type: 'button', disabled: true }, t('add')));
    return;
  }
  if (p.variants.length) {
    action.append(
      count > 0
        ? h('button', { class: 'btn-added', type: 'button', onclick: () => openVariantSheet(p) }, t('added', { n: count }))
        : h(
            'button',
            { class: 'btn-add', type: 'button', 'aria-label': `${t('add')} ${p.name}`, onclick: () => openVariantSheet(p) },
            t('add'),
          ),
    );
    return;
  }
  if (count > 0) {
    action.append(stepper(count, (q) => setQty(p, '', q, p.price)));
  } else {
    action.append(
      h(
        'button',
        { class: 'btn-add', type: 'button', 'aria-label': `${t('add')} ${p.name}`, onclick: () => setQty(p, '', 1, p.price) },
        t('add'),
      ),
    );
  }
}

function stepper(qty, onChange, small = false) {
  return h(
    'div',
    { class: small ? 'stepper small' : 'stepper', role: 'group' },
    h('button', { type: 'button', 'aria-label': t('decrease'), onclick: () => onChange(qty - 1) }, icon('minus', 16)),
    h('span', { class: 'qty', 'aria-live': 'polite' }, String(qty)),
    h(
      'button',
      { type: 'button', 'aria-label': t('increase'), disabled: qty >= MAX_QTY, onclick: () => onChange(qty + 1) },
      icon('plus', 16),
    ),
  );
}

function applySearch() {
  const q = S.search.trim().toLowerCase();
  let visible = 0;
  for (const g of S.groupRefs) {
    let shown = 0;
    for (const p of g.items) {
      const ref = S.cardRefs.get(p.id);
      const match =
        !q ||
        p.name.toLowerCase().includes(q) ||
        p.description.toLowerCase().includes(q) ||
        p.category.toLowerCase().includes(q) ||
        p.variants.some((v) => v.name.toLowerCase().includes(q));
      if (ref) ref.card.hidden = !match;
      if (match) shown += 1;
    }
    g.section.hidden = shown === 0;
    visible += shown;
  }
  S.ui.noMatch.hidden = !(q && visible === 0);
  S.ui.noMatch.textContent = t('noMatch', { q: S.search.trim() });
}

function footer() {
  return h(
    'footer',
    { class: 'footer' },
    h('a', { href: PLAY_URL, target: '_blank', rel: 'noopener' }, t('madeWith')),
  );
}

// ---------------------------------------------------------------------------
// Bottom bar
// ---------------------------------------------------------------------------

function buildBar() {
  const info = h('div', { class: 'bar-info' });
  const label = h('span', {});
  const btn = h('button', { class: 'bar-btn', type: 'button', onclick: openCheckout }, label, icon('chevron', 18));
  const bar = h('div', { class: 'bar hidden', role: 'region', 'aria-label': t('yourOrder') }, info, btn);
  S.ui.bar = { bar, info, label };
  return h('div', { class: 'bar-holder' }, bar);
}

function updateBar() {
  const ui = S.ui.bar;
  if (!ui || !S.store) return;
  const st = S.store;
  if (st.orderMode === 'request') {
    ui.info.replaceChildren(h('div', { class: 'bar-hint' }, t('yourRequest')));
    ui.label.textContent = t('writeOrder');
    setBarHidden(ui.bar, !st.isLive);
    return;
  }
  const n = cartCount();
  ui.info.replaceChildren(
    h('div', { class: 'bar-count' }, t('items', { n })),
    h('div', { class: 'bar-total' }, money(cartSubtotal())),
  );
  ui.label.textContent = t('sendOrder');
  setBarHidden(ui.bar, n === 0 || !st.isLive);
}

// The bar slides off-screen when hidden; inert keeps its button out of the tab order.
function setBarHidden(bar, hide) {
  bar.classList.toggle('hidden', hide);
  bar.inert = hide;
}

// ---------------------------------------------------------------------------
// Sheets
// ---------------------------------------------------------------------------

function onEsc(e) {
  if (e.key === 'Escape') closeSheet();
}

window.addEventListener('popstate', () => {
  if (S.ignorePop) {
    S.ignorePop = false;
    return;
  }
  if (S.sheet) closeSheet({ fromHistory: true });
});

function openSheet({ title, body, foot }) {
  const returnFocus = S.sheet ? S.sheet.returnFocus : document.activeElement;
  closeSheet({ silent: true });
  const closeBtn = h(
    'button',
    { class: 'icon-btn', type: 'button', 'aria-label': t('close'), onclick: () => closeSheet() },
    icon('close', 18),
  );
  const sheet = h(
    'div',
    { class: 'sheet', role: 'dialog', 'aria-modal': 'true', 'aria-label': title },
    h('div', { class: 'sheet-grab', 'aria-hidden': 'true' }),
    h('div', { class: 'sheet-head' }, h('h2', { class: 'sheet-title' }, title), closeBtn),
    h('div', { class: 'sheet-body' }, body),
    foot ? h('div', { class: 'sheet-foot' }, foot) : null,
  );
  const overlay = h('div', { class: 'overlay' }, sheet);
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) closeSheet();
  });
  document.body.append(overlay);
  document.body.classList.add('sheet-open');
  app.inert = true; // the page behind the sheet is out of reach while it is open
  document.addEventListener('keydown', onEsc);
  try {
    history.pushState({ pkSheet: true }, '');
  } catch (_) {
    /* ignore */
  }
  S.sheet = { overlay, refresh: null, returnFocus };
  closeBtn.focus({ preventScroll: true });
  return S.sheet;
}

// silent: close without touching history (the entry is neutralised instead).
function closeSheet({ silent = false, fromHistory = false } = {}) {
  if (!S.sheet) return;
  const { returnFocus } = S.sheet;
  S.sheet.overlay.remove();
  S.sheet = null;
  S.checkout = null;
  document.body.classList.remove('sheet-open');
  app.inert = false;
  if (returnFocus && returnFocus.isConnected && typeof returnFocus.focus === 'function') {
    returnFocus.focus({ preventScroll: true });
  }
  document.removeEventListener('keydown', onEsc);
  if (fromHistory) return;
  const onSheetEntry = history.state && history.state.pkSheet;
  if (!onSheetEntry) return;
  if (silent) {
    try {
      history.replaceState(null, '');
    } catch (_) {
      /* ignore */
    }
  } else {
    S.ignorePop = true;
    history.back();
  }
}

function openVariantSheet(p) {
  const body = h('div', {});
  const render = () => {
    body.replaceChildren(
      h('p', { class: 'section-label' }, t('chooseOption')),
      h(
        'div',
        { class: 'card' },
        p.variants.map((v) => {
          const q = qtyOf(p.id, v.name);
          return h(
            'div',
            { class: 'variant' },
            h(
              'div',
              { class: 'variant-main' },
              h('p', { class: 'variant-name' }, v.name),
              h('p', { class: 'variant-price' }, money(v.price)),
            ),
            q > 0
              ? stepper(q, (nq) => setQty(p, v.name, nq, v.price), true)
              : h(
                  'button',
                  {
                    class: 'btn-add',
                    type: 'button',
                    'aria-label': `${t('add')} ${p.name} · ${v.name}`,
                    onclick: () => setQty(p, v.name, 1, v.price),
                  },
                  t('add'),
                ),
          );
        }),
      ),
    );
  };
  render();
  const sheet = openSheet({
    title: p.name,
    body,
    foot: h('button', { class: 'btn-primary', type: 'button', onclick: () => closeSheet() }, t('done')),
  });
  sheet.refresh = render;
}

// ---------------------------------------------------------------------------
// Checkout
// ---------------------------------------------------------------------------

function field(opts) {
  const {
    key,
    label,
    placeholder = '',
    hint = '',
    required = false,
    multiline = false,
    type = 'text',
    inputmode,
    autocomplete,
    max = 200,
    value = '',
    sanitize,
    onInput,
  } = opts;
  const id = `f-${key}`;
  const input = multiline
    ? h('textarea', { id, rows: 3, maxlength: max, placeholder })
    : h('input', { id, type, inputmode, autocomplete, maxlength: max, placeholder });
  input.value = value;
  const error = h('p', { class: 'error', hidden: true, role: 'alert' });
  const el = h(
    'div',
    { class: 'field' },
    label
      ? h(
          'label',
          { for: id },
          label,
          required
            ? h('span', { class: 'req', 'aria-hidden': 'true' }, '*')
            : h('span', { class: 'hint' }, ` (${t('optional')})`),
        )
      : null,
    input,
    hint ? h('p', { class: 'hint' }, hint) : null,
    error,
  );
  const setError = (msg) => {
    el.classList.toggle('invalid', Boolean(msg));
    error.hidden = !msg;
    error.textContent = msg || '';
    if (msg) input.setAttribute('aria-invalid', 'true');
    else input.removeAttribute('aria-invalid');
  };
  input.addEventListener('input', () => {
    if (sanitize) {
      const clean = sanitize(input.value);
      if (clean !== input.value) input.value = clean;
    }
    onInput(input.value);
    if (el.classList.contains('invalid')) setError(null);
    const c = S.checkout;
    if (c && c.footError && !c.footError.hidden && !document.querySelector('.sheet .field.invalid')) {
      c.footError.hidden = true;
    }
  });
  return { el, input, setError };
}

function totalsRow(label, valueEl, grand = false) {
  return h('div', { class: grand ? 'totals-row grand' : 'totals-row' }, h('span', {}, label), valueEl);
}

function setNote(el, note) {
  if (!note) {
    el.hidden = true;
    return;
  }
  el.hidden = false;
  el.className = `note-box ${note[0]}`;
  el.textContent = note[1];
}

function openCheckout() {
  const st = S.store;
  if (!st.isLive) return;
  const isRequest = st.orderMode === 'request';
  if (!isRequest && cartCount() === 0) return;

  const c = { refs: {} };
  const body = h('div', {});

  // 1 — what is being ordered
  if (isRequest) {
    const req = field({
      key: 'requestText',
      placeholder: t('requestPlaceholder'),
      hint: t('requestIntro'),
      multiline: true,
      required: true,
      max: 1000,
      value: S.form.requestText,
      onInput: (v) => {
        S.form.requestText = v;
        if (v.trim()) bumpOnce('carts'); // request mode has no cart: starting to write counts instead
      },
    });
    c.refs.requestText = req;
    body.append(h('p', { class: 'section-label' }, t('yourRequest')), h('div', { class: 'card' }, req.el));
  } else {
    c.linesBox = h('div', { class: 'card' });
    body.append(h('p', { class: 'section-label' }, t('yourOrder')), c.linesBox);
  }

  // 2 — delivery or pickup
  c.modeCard = h('div', { class: 'card' });
  body.append(h('p', { class: 'section-label' }, t('howGet')), c.modeCard);

  // 3 — buyer details
  const details = h('div', { class: 'card' });
  c.refs.name = field({
    key: 'name',
    label: t('name'),
    required: true,
    max: 80,
    autocomplete: 'name',
    value: S.form.name,
    onInput: (v) => {
      S.form.name = v;
    },
  });
  c.refs.phone = field({
    key: 'phone',
    label: t('phone'),
    required: true,
    type: 'tel',
    inputmode: 'numeric',
    autocomplete: 'tel',
    max: 15,
    hint: t('phoneHint'),
    value: S.form.phone,
    sanitize: (v) => v.replace(/\D/g, '').slice(0, 15),
    onInput: (v) => {
      S.form.phone = v;
    },
  });
  c.refs.address = field({
    key: 'address',
    label: t('address'),
    required: true,
    multiline: true,
    max: 300,
    autocomplete: 'street-address',
    placeholder: t('addressHint'),
    hint: st.deliveryArea ? t('deliveryArea', { x: st.deliveryArea }) : '',
    value: S.form.address,
    onInput: (v) => {
      S.form.address = v;
    },
  });
  details.append(c.refs.name.el, c.refs.phone.el, c.refs.address.el);
  // Bot trap: hidden from people and screen readers; form bots fill every field.
  c.trap = h('input', { type: 'text', name: 'website', tabindex: '-1', autocomplete: 'off' });
  details.append(h('div', { class: 'hp', 'aria-hidden': 'true' }, c.trap));
  for (const cf of st.customFields) {
    const f = field({
      key: `cf-${cf.id}`,
      label: cf.label,
      required: cf.required,
      max: 300,
      value: S.form.answers[cf.id] || '',
      onInput: (v) => {
        S.form.answers[cf.id] = v;
      },
    });
    c.refs[`cf_${cf.id}`] = f;
    details.append(f.el);
  }
  if (st.askNote) {
    c.refs.note = field({
      key: 'note',
      label: t('note'),
      multiline: true,
      max: 500,
      placeholder: t('notePlaceholder'),
      value: S.form.note,
      onInput: (v) => {
        S.form.note = v;
      },
    });
    details.append(c.refs.note.el);
  }
  body.append(h('p', { class: 'section-label' }, t('details')), details);

  // 4 — totals
  if (isRequest) {
    body.append(h('div', { class: 'note-box grey' }, t('requestTotalNote')));
  } else {
    c.subEl = h('span', {});
    c.feeEl = h('span', {});
    c.totalEl = h('span', {});
    c.feeRow = totalsRow(t('deliveryFee'), c.feeEl);
    c.freeNote = h('div', { class: 'note-box green', hidden: true });
    c.minNote = h('div', { class: 'note-box amber', hidden: true });
    body.append(
      c.freeNote,
      c.minNote,
      h('div', { class: 'card' }, totalsRow(t('subtotal'), c.subEl), c.feeRow, totalsRow(t('total'), c.totalEl, true)),
    );
  }

  // footer — send
  c.footError = h('p', { class: 'foot-error', hidden: true, role: 'alert' });
  c.sendLabel = h('span', {});
  c.sendBtn = h('button', { class: 'btn-primary', type: 'button', onclick: submitOrder }, icon('send', 20), c.sendLabel);
  const foot = h('div', {}, c.footError, c.sendBtn);

  const sheet = openSheet({ title: isRequest ? t('writeOrder') : t('yourOrder'), body, foot });
  S.checkout = c;
  sheet.refresh = () => {
    if (!isRequest && cartCount() === 0) {
      closeSheet();
      return;
    }
    updateCheckout();
  };
  renderModeCard();
  updateCheckout();
}

function renderModeCard() {
  const c = S.checkout;
  if (!c) return;
  const st = S.store;
  const modes = availableModes();
  const emoji = (m) => (m === 'delivery' ? '🛵' : '🛍️');
  c.modeCard.replaceChildren();
  if (modes.length > 1) {
    c.modeCard.append(
      h(
        'div',
        { class: 'segmented', role: 'radiogroup', 'aria-label': t('howGet') },
        modes.map((m) =>
          h(
            'button',
            {
              type: 'button',
              role: 'radio',
              'aria-checked': String(S.fulfillment === m),
              class: S.fulfillment === m ? 'on' : '',
              onclick: () => {
                S.fulfillment = m;
                renderModeCard();
                updateCheckout();
              },
            },
            h('span', { 'aria-hidden': 'true' }, emoji(m)),
            h('span', {}, t(m)),
          ),
        ),
      ),
    );
  } else {
    c.modeCard.append(
      h(
        'div',
        { class: 'fixed-mode' },
        h('span', { 'aria-hidden': 'true' }, emoji(modes[0])),
        h('span', {}, t(modes[0])),
        h('span', { class: 'line-sub' }, ` · ${t(modes[0] === 'delivery' ? 'deliveryDesc' : 'pickupDesc')}`),
      ),
    );
  }
  if (S.fulfillment === 'pickup' && st.pickupAddress) {
    c.modeCard.append(h('p', { class: 'line-sub', style: 'margin:8px 0 0' }, t('pickupFrom', { x: st.pickupAddress })));
  }
  c.refs.address.el.hidden = S.fulfillment !== 'delivery';
}

function renderLines() {
  const c = S.checkout;
  if (!c || !c.linesBox) return;
  c.linesBox.replaceChildren(
    ...cartLines().map((l) => {
      const product = S.products.find((p) => p.id === l.productId) || { id: l.productId, name: l.name };
      return h(
        'div',
        { class: 'line' },
        h(
          'div',
          { class: 'line-main' },
          h('p', { class: 'line-name' }, l.name),
          h('p', { class: 'line-sub' }, `${l.variant ? `${l.variant} · ` : ''}${money(l.price)} × ${l.qty}`),
        ),
        stepper(l.qty, (q) => setQty(product, l.variant, q, l.price), true),
        h('div', { class: 'line-total' }, money(l.price * l.qty)),
      );
    }),
  );
}

function updateCheckout() {
  const c = S.checkout;
  if (!c) return;
  const st = S.store;
  if (st.orderMode === 'cart') {
    renderLines();
    const sub = cartSubtotal();
    const fee = deliveryFeeFor(sub);
    c.subEl.textContent = money(sub);
    c.feeRow.hidden = S.fulfillment !== 'delivery';
    c.feeEl.textContent = fee === 0 ? t('free') : money(fee);
    c.totalEl.textContent = money(sub + fee);
    let freeNote = null;
    if (S.fulfillment === 'delivery' && st.freeDeliveryAbove > 0 && st.deliveryFee > 0) {
      freeNote =
        sub >= st.freeDeliveryAbove
          ? ['green', t('freeUnlocked')]
          : ['green', t('addForFree', { x: money(st.freeDeliveryAbove - sub) })];
    }
    setNote(c.freeNote, freeNote);
    const short = st.minOrder > 0 && sub < st.minOrder;
    setNote(
      c.minNote,
      short ? ['amber', t('minOrderNote', { x: money(st.minOrder), y: money(st.minOrder - sub) })] : null,
    );
    c.sendBtn.disabled = S.sending || short || cartCount() === 0;
  } else {
    c.sendBtn.disabled = S.sending;
  }
  c.sendLabel.textContent = S.sending
    ? t('sending')
    : t(st.orderMode === 'request' ? 'sendRequest' : 'sendWhatsApp');
}

function orderNumber() {
  const a = new Uint32Array(1);
  crypto.getRandomValues(a);
  return String(100000 + (a[0] % 900000));
}

function buildOrder() {
  const st = S.store;
  const isRequest = st.orderMode === 'request';
  const items = isRequest
    ? []
    : cartLines().map((l) => ({
        productId: l.productId,
        name: l.name,
        variant: l.variant || '',
        price: l.price,
        qty: l.qty,
      }));
  const subtotal = isRequest ? 0 : cartSubtotal();
  const deliveryFee = isRequest ? 0 : deliveryFeeFor(subtotal);
  const answers = st.customFields
    .map((cf) => ({ label: cf.label, value: (S.form.answers[cf.id] || '').trim().slice(0, 300) }))
    .filter((a) => a.value);
  return {
    number: orderNumber(),
    source: 'link',
    status: 'pending',
    fulfillment: S.fulfillment,
    customer: {
      name: S.form.name.trim().slice(0, 80),
      phone: S.form.phone.replace(/\D/g, '').slice(0, 20),
      address: S.fulfillment === 'delivery' ? S.form.address.trim().slice(0, 300) : '',
    },
    items,
    itemCount: items.reduce((sum, i) => sum + i.qty, 0),
    requestText: isRequest ? S.form.requestText.trim().slice(0, 1000) : '',
    subtotal,
    deliveryFee,
    total: subtotal + deliveryFee,
    paid: 0,
    payments: [],
    note: st.askNote ? S.form.note.trim().slice(0, 500) : '',
    answers,
    amountChanged: false,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}

function buildMessage(order) {
  const st = S.store;
  const lines = [t('waHello', { store: st.name }), t('waOrder', { n: order.number }), ''];
  if (order.requestText) {
    lines.push(order.requestText);
  } else {
    for (const i of order.items) {
      lines.push(`• ${i.qty} × ${i.name}${i.variant ? ` (${i.variant})` : ''} — ${money(i.price * i.qty)}`);
    }
    lines.push('');
    lines.push(`${t('waSubtotal')}: ${money(order.subtotal)}`);
    if (order.fulfillment === 'delivery') {
      lines.push(`${t('waDelivery')}: ${order.deliveryFee === 0 ? t('free') : money(order.deliveryFee)}`);
    }
    lines.push(`*${t('waTotal')}: ${money(order.total)}*`);
  }
  lines.push('');
  lines.push(order.fulfillment === 'delivery' ? t('waDeliverTo', { x: order.customer.address }) : t('waPickup'));
  lines.push(`👤 ${order.customer.name} · 📞 ${order.customer.phone}`);
  for (const a of order.answers) lines.push(`${a.label}: ${a.value}`);
  if (order.note) lines.push(`📝 ${order.note}`);
  return lines.join('\n');
}

function validate() {
  const c = S.checkout;
  const st = S.store;
  let first = null;
  const flag = (f, msg) => {
    if (!f) return;
    f.setError(msg);
    if (!first) first = f;
  };
  Object.values(c.refs).forEach((f) => f.setError(null));
  if (st.orderMode === 'request' && !S.form.requestText.trim()) flag(c.refs.requestText, t('required'));
  if (!S.form.name.trim()) flag(c.refs.name, t('required'));
  const phone = S.form.phone.replace(/\D/g, '');
  if (!phone) flag(c.refs.phone, t('required'));
  else if (phone.length < 7 || phone.length > 15) flag(c.refs.phone, t('invalidPhone'));
  if (S.fulfillment === 'delivery' && !S.form.address.trim()) flag(c.refs.address, t('required'));
  for (const cf of st.customFields) {
    if (cf.required && !(S.form.answers[cf.id] || '').trim()) flag(c.refs[`cf_${cf.id}`], t('required'));
  }
  return first;
}

function openWhatsApp(url) {
  const mobile = /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent);
  if (mobile) {
    location.href = url;
    return;
  }
  const w = window.open(url, '_blank');
  if (w) {
    try {
      w.opener = null;
    } catch (_) {
      /* ignore */
    }
  } else {
    location.href = url;
  }
}

async function submitOrder() {
  const c = S.checkout;
  const st = S.store;
  if (!c || S.sending || !st.isLive) return;

  const bad = validate();
  if (bad) {
    c.footError.hidden = false;
    c.footError.textContent = t('fixFields');
    bad.input.focus({ preventScroll: true });
    bad.el.scrollIntoView({ block: 'center', behavior: 'smooth' });
    return;
  }
  c.footError.hidden = true;
  const isRequest = st.orderMode === 'request';
  if (!isRequest) {
    const sub = cartSubtotal();
    if (cartCount() === 0 || (st.minOrder > 0 && sub < st.minOrder)) return;
  }

  S.sending = true;
  updateCheckout();

  // Bots fill the hidden field or send moments after the page opened. They
  // get the normal success screen, but nothing is saved or sent.
  const isBot = Boolean(c.trap && c.trap.value) || performance.now() < MIN_HUMAN_MS;

  let guard = null;
  if (!isBot) {
    try {
      guard = await withTimeout(readGuard(), 8000);
    } catch (e) {
      console.warn('[pk] could not check the order limit', e && e.code);
    }
    const stop = guard && guardStop(guard.data);
    if (stop) {
      S.sending = false;
      updateCheckout();
      c.footError.hidden = false;
      c.footError.textContent = stop;
      return;
    }
  }

  const order = buildOrder();
  const message = buildMessage(order);
  // api.whatsapp.com, not wa.me: the wa.me redirect turns emoji into "�".
  const waUrl = st.whatsapp
    ? `https://api.whatsapp.com/send?phone=${st.whatsapp}&text=${encodeURIComponent(message)}`
    : '';

  let writeOk = true;
  if (!isBot) {
    try {
      await saveOrder(order, guard);
      bump('sent');
    } catch (e) {
      writeOk = false;
      console.warn('[pk] order could not be saved', e);
    }
  }
  console.info('[pk] WhatsApp URL:', waUrl || '(this store has no WhatsApp number)');

  rememberBuyer();
  const summary = {
    number: order.number,
    isRequest,
    requestText: order.requestText,
    lines: order.items.map((i) => ({ name: i.name, variant: i.variant, qty: i.qty, total: i.price * i.qty })),
    subtotal: order.subtotal,
    deliveryFee: order.deliveryFee,
    total: order.total,
    fulfillment: order.fulfillment,
    waUrl,
    writeOk,
    at: Date.now(),
  };
  saveLastOrder(summary);

  S.cart.clear();
  S.form.requestText = '';
  S.form.note = '';
  S.form.answers = {};
  S.sending = false;
  closeSheet({ silent: true });
  renderSuccess(summary);
  if (waUrl && !NO_WA && !isBot) openWhatsApp(waUrl);
}

// ---------------------------------------------------------------------------
// Order limits (firestore.rules → orderGuards). Every public order is saved
// in one batch with the buyer's guard doc, and its id is "<uid>_<seq>".
// ---------------------------------------------------------------------------

async function readGuard() {
  const user = await ensureBuyer();
  const ref = doc(db, 'orderGuards', user.uid);
  const snap = await getDoc(ref);
  return { uid: user.uid, ref, data: snap.exists() ? snap.data() : null };
}

const millis = (ts) => (ts && typeof ts.toMillis === 'function' ? ts.toMillis() : 0);

// Why this buyer can't send right now (a message to show), or null.
function guardStop(g) {
  if (!g) return null;
  const now = Date.now();
  const wait = Math.ceil((ORDER_COOLDOWN_MS + CLOCK_SLACK_MS - (now - millis(g.lastAt))) / 1000);
  if (wait > 0) return t('waitToSend', { s: wait });
  if (now - millis(g.windowStart) < ORDER_DAY_MS && (g.count || 0) >= ORDERS_PER_DAY) {
    return t('tooManyOrders');
  }
  return null;
}

async function saveOrder(order, guard) {
  const g = guard || (await withTimeout(readGuard(), 8000));
  const prev = g.data;
  const sameWindow = Boolean(prev) && Date.now() - millis(prev.windowStart) < ORDER_DAY_MS;
  const write = (keepWindow) => {
    const seq = (prev ? prev.seq : 0) + 1;
    const batch = writeBatch(db);
    batch.set(g.ref, {
      seq,
      count: keepWindow ? prev.count + 1 : 1,
      windowStart: keepWindow ? prev.windowStart : serverTimestamp(),
      lastAt: serverTimestamp(),
      store: S.storeId,
    });
    batch.set(doc(db, 'stores', S.storeId, 'orders', `${g.uid}_${seq}`), { ...order, buyerUid: g.uid });
    return withTimeout(batch.commit(), 12000);
  };
  try {
    await write(sameWindow);
  } catch (e) {
    // The phone's clock chose the day window. If it was wrong, the other one is right.
    if (!prev || !e || e.code !== 'permission-denied') throw e;
    await write(!sameWindow);
  }
}

// ---------------------------------------------------------------------------
// Success / empty / error screens
// ---------------------------------------------------------------------------

function renderSuccess(sum) {
  closeSheet({ silent: true });
  const wrap = h('div', { class: 'wrap' });
  const box = h('div', { class: 'success' });

  box.append(
    h(
      'div',
      { class: 'success-top' },
      h('div', { class: 'success-check' }, icon('check', 36)),
      h('h1', { class: 'success-title' }, t(sum.isRequest ? 'requestSent' : 'orderSent')),
      h('p', { class: 'success-store' }, S.store.name),
      h('span', { class: 'order-pill' }, t('orderNo', { n: sum.number })),
    ),
    h('p', { class: 'success-hint' }, sum.waUrl ? t('sentHint') : t('sentHintNoWa')),
  );
  if (!sum.writeOk) box.append(h('div', { class: 'note-box amber' }, t('writeFailed')));

  const card = h('div', { class: 'card' });
  if (sum.isRequest) {
    card.append(h('p', { class: 'request-text' }, sum.requestText));
  } else {
    for (const l of sum.lines) {
      card.append(
        h(
          'div',
          { class: 'line' },
          h(
            'div',
            { class: 'line-main' },
            h('p', { class: 'line-name' }, `${l.qty} × ${l.name}`),
            l.variant ? h('p', { class: 'line-sub' }, l.variant) : null,
          ),
          h('div', { class: 'line-total' }, money(l.total)),
        ),
      );
    }
    card.append(
      h(
        'div',
        { style: 'margin-top:6px' },
        totalsRow(t('subtotal'), h('span', {}, money(sum.subtotal))),
        sum.fulfillment === 'delivery'
          ? totalsRow(t('deliveryFee'), h('span', {}, sum.deliveryFee === 0 ? t('free') : money(sum.deliveryFee)))
          : null,
        totalsRow(t('total'), h('span', {}, money(sum.total)), true),
      ),
    );
  }
  box.append(card);

  if (sum.waUrl) {
    box.append(
      h('a', { class: 'btn-primary', href: sum.waUrl, target: '_blank', rel: 'noopener' }, icon('send', 20), t('openWhatsApp')),
    );
  }
  box.append(
    h(
      'button',
      {
        class: 'btn-secondary',
        type: 'button',
        onclick: () => {
          clearLastOrder();
          renderStore();
        },
      },
      t('backToStore'),
    ),
  );
  wrap.append(box, footer());
  mount(h('main', { class: 'page no-bar' }, wrap));
}

function stateScreen(emoji, title, body, ...extra) {
  return h(
    'main',
    { class: 'state-screen' },
    h(
      'div',
      { class: 'state-card' },
      h('div', { class: 'state-icon', 'aria-hidden': 'true' }, emoji),
      h('h1', { class: 'state-title' }, title),
      body ? h('p', { class: 'state-body' }, body) : null,
      ...extra,
    ),
  );
}

function renderLoading() {
  mount(h('div', { class: 'state-screen', role: 'status' }, h('div', { class: 'spinner', 'aria-hidden': 'true' })));
}

function browserLang() {
  return (navigator.language || '').toLowerCase().startsWith('ur') ? 'ur' : 'en';
}

function renderLanding() {
  setLang(browserLang());
  document.title = 'Pocket Karcha · Order links';
  mount(
    stateScreen(
      '🛍️',
      t('landingTitle'),
      t('landingBody'),
      h('a', { class: 'btn-primary', href: PLAY_URL, rel: 'noopener', style: 'margin-top:10px' }, t('getApp')),
    ),
  );
}

function renderNotFound(slug) {
  setLang(browserLang());
  document.title = t('notFoundTitle');
  mount(
    stateScreen(
      '🔍',
      t('notFoundTitle'),
      t('notFoundBody'),
      slug
        ? h('span', { class: 'link-pill' }, SITE_SHOP ? location.host : `${location.host}/${slug}`)
        : null,
      h('a', { class: 'btn-secondary', href: PLAY_URL, rel: 'noopener', style: 'margin-top:10px' }, t('getApp')),
    ),
  );
}

function renderError(slug) {
  setLang(browserLang());
  mount(
    stateScreen(
      '⚠️',
      t('loadError'),
      '',
      h('button', { class: 'btn-primary', type: 'button', style: 'margin-top:6px', onclick: () => loadStore(slug) }, t('retry')),
    ),
  );
}

main();
