import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pocket_karcha/firebase_options.dart';

abstract final class FirebaseService {
  static bool isReady = false;
  static FirebaseAnalytics? analytics;

  static Future<bool> initialize() async {
    isReady = false;
    analytics = null;
    try {
      if (Firebase.apps.isNotEmpty) {
        isReady = true;
        await _enableAnalytics();
        debugPrint('Firebase: already initialized');
        return true;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isReady = true;
      await _enableAnalytics();
      debugPrint('Firebase: initialized (${DefaultFirebaseOptions.currentPlatform.projectId})');
      return true;
    } catch (e, st) {
      debugPrint('Firebase init failed: $e\n$st');
      isReady = false;
      analytics = null;
      return false;
    }
  }

  static Future<void> _enableAnalytics() async {
    if (!isReady) return;
    try {
      final instance = FirebaseAnalytics.instance;
      await instance.setAnalyticsCollectionEnabled(true);
      analytics = instance;
      debugPrint('Firebase Analytics: enabled');
    } catch (e, st) {
      analytics = null;
      debugPrint('Firebase Analytics init failed: $e\n$st');
    }
  }

  static Future<void> setAnalyticsUserId(String? uid) async {
    final a = analytics;
    if (a == null) return;
    try {
      await a.setUserId(id: uid);
    } catch (e) {
      debugPrint('Firebase Analytics setUserId failed: $e');
    }
  }
}
