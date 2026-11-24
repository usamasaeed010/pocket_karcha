'use strict';

// Pocket Karcha Cloud Functions.
//
// notifyNewOrder: when a customer places an order from the store link
// (stores/{storeId}/orders/{orderId} with source "link"), send a push to
// every phone the owner turned alerts on for (users/{storeId}/devices).
// The store id is the owner's uid.

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { buildOrderNotification, isDeadTokenError } = require('./order_notification');

initializeApp();

exports.notifyNewOrder = onDocumentCreated(
  'stores/{storeId}/orders/{orderId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const order = snap.data() || {};
    // Orders the owner types in the app need no alert.
    if (order.source !== 'link') return;

    const { storeId, orderId } = event.params;
    const db = getFirestore();
    const [storeSnap, devicesSnap] = await Promise.all([
      db.doc(`stores/${storeId}`).get(),
      db.collection(`users/${storeId}/devices`).get(),
    ]);
    if (devicesSnap.empty) {
      logger.info('New order, but no phone has alerts on', { storeId, orderId });
      return;
    }
    const store = storeSnap.exists ? storeSnap.data() : {};

    // One message per language the owner's phones use.
    const byLang = new Map();
    for (const doc of devicesSnap.docs) {
      const token = doc.get('token') || doc.id;
      const lang = doc.get('lang') === 'ur' ? 'ur' : 'en';
      if (!byLang.has(lang)) byLang.set(lang, []);
      byLang.get(lang).push({ token, ref: doc.ref });
    }

    const dead = [];
    for (const [lang, devices] of byLang) {
      const { title, body } = buildOrderNotification(order, {
        currencySymbol: store.currencySymbol,
        lang,
      });
      try {
        const res = await getMessaging().sendEachForMulticast({
          tokens: devices.map((d) => d.token),
          notification: { title, body },
          data: { type: 'new_order', storeId, orderId },
          android: {
            priority: 'high',
            notification: { channelId: 'orders', tag: orderId, sound: 'default' },
          },
          apns: { payload: { aps: { sound: 'default' } } },
        });
        res.responses.forEach((r, i) => {
          if (!r.success && isDeadTokenError(r.error)) dead.push(devices[i].ref);
        });
        const counts = { storeId, orderId, lang, sent: res.successCount, failed: res.failureCount };
        if (res.successCount > 0) {
          logger.info('Order alert sent', counts);
        } else {
          logger.warn('Order alert not delivered', {
            ...counts,
            errors: res.responses.map((r) => r.error && r.error.code).filter(Boolean),
          });
        }
      } catch (error) {
        logger.error('Order alert failed', { storeId, orderId, lang, error: String(error) });
      }
    }
    // Forget phones that uninstalled the app or logged out.
    await Promise.all(dead.map((ref) => ref.delete()));
  },
);
