import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pocket_karcha/services/firebase_service.dart';

/// New-order push notifications.
///
/// A phone that turns alerts on saves its FCM token at
/// `users/{uid}/devices/{token}`. The `notifyNewOrder` Cloud Function
/// (functions/index.js) sends to those tokens when a customer orders from
/// the store link. Tapping the notification opens that order.
class PushService {
  PushService._();

  static final instance = PushService._();

  final _openedOrders = StreamController<String>.broadcast();
  StreamSubscription<String>? _tokenRefresh;
  String? _initialOrderId;
  String? _uid;
  bool _urdu = false;

  FirebaseMessaging? get _messaging =>
      FirebaseService.isReady ? FirebaseMessaging.instance : null;

  /// Order ids from notifications tapped while the app was running.
  Stream<String> get openedOrderIds => _openedOrders.stream;

  /// Order id from the notification that started the app (given once).
  String? takeInitialOrderId() {
    final id = _initialOrderId;
    _initialOrderId = null;
    return id;
  }

  /// Call once after Firebase starts.
  Future<void> init() async {
    final fm = _messaging;
    if (fm == null) return;
    try {
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final id = _orderIdOf(message);
        if (id != null) _openedOrders.add(id);
      });
      _initialOrderId = _orderIdOf(await fm.getInitialMessage());
    } catch (e) {
      debugPrint('PushService.init: $e');
    }
  }

  static String? _orderIdOf(RemoteMessage? message) {
    if (message == null || message.data['type'] != 'new_order') return null;
    final id = message.data['orderId'];
    return id is String && id.isNotEmpty ? id : null;
  }

  static bool _granted(NotificationSettings s) =>
      s.authorizationStatus == AuthorizationStatus.authorized ||
      s.authorizationStatus == AuthorizationStatus.provisional;

  /// Whether this phone may show notifications from the app.
  Future<bool> isAllowed() async {
    final fm = _messaging;
    if (fm == null) return false;
    try {
      return _granted(await fm.getNotificationSettings());
    } catch (_) {
      return false;
    }
  }

  /// Asks the owner (Android 13+ / iOS). False when they say no, or blocked
  /// notifications before (then only phone settings can turn them on).
  Future<bool> requestPermission() async {
    final fm = _messaging;
    if (fm == null) return false;
    try {
      return _granted(await fm.requestPermission());
    } catch (_) {
      return false;
    }
  }

  /// This app's page in phone settings.
  Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Saves this phone so new-order alerts for [uid]'s store reach it.
  /// Safe to call often (one small write).
  Future<void> registerDevice(String uid, {required bool urdu}) async {
    final fm = _messaging;
    if (fm == null) return;
    _uid = uid;
    _urdu = urdu;
    try {
      final token = await fm.getToken();
      if (token != null) _save(uid, token);
      _tokenRefresh ??= fm.onTokenRefresh.listen((token) {
        final current = _uid;
        if (current != null) _save(current, token);
      });
    } catch (e) {
      debugPrint('PushService.registerDevice: $e');
    }
  }

  void _save(String uid, String token) {
    // Not awaited: Firestore keeps the write on the phone and sends it when
    // online.
    FirebaseFirestore.instance.doc('users/$uid/devices/$token').set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'lang': _urdu ? 'ur' : 'en',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((Object e) {
      debugPrint('PushService: could not save device — $e');
    });
  }

  /// Stops alerts for [uid] on this phone (log out). Call while still
  /// signed in.
  Future<void> unregisterDevice(String uid) async {
    final fm = _messaging;
    if (fm == null) return;
    _uid = null;
    try {
      final token = await fm.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .doc('users/$uid/devices/$token')
          .delete();
    } catch (e) {
      debugPrint('PushService.unregisterDevice: $e');
    }
  }
}

/// Whether new-order alerts can show on this phone.
final pushAllowedProvider = FutureProvider.autoDispose<bool>((ref) {
  return PushService.instance.isAllowed();
});
