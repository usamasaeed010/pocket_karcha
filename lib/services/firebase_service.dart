import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        await _useEmulatorsIfAsked();
        await _enableAnalytics();
        debugPrint('Firebase: already initialized');
        return true;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isReady = true;
      await _activateAppCheck();
      await _useEmulatorsIfAsked();
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

  /// App Check lets Firebase tell this app apart from scripts that copy its
  /// keys. Nothing is blocked until enforcement is switched on in the
  /// Firebase console, so shipping it first is safe. Debug builds use the
  /// debug provider: register the token printed in logcat to mark them as
  /// verified.
  static Future<void> _activateAppCheck() async {
    if (_useEmulator || kIsWeb) return;
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
        appleProvider:
            kReleaseMode ? AppleProvider.deviceCheck : AppleProvider.debug,
      );
    } catch (e) {
      debugPrint('App Check is off: $e');
    }
  }

  /// Local testing against the Firebase emulators:
  /// `--dart-define=USE_FIREBASE_EMULATOR=true` (and optionally
  /// `--dart-define=EMULATOR_HOST=…`; default 10.0.2.2 is this computer as
  /// seen from the Android emulator). Never set for release builds.
  static const _useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
  static const _emulatorHost =
      String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');
  static bool _emulatorsWired = false;

  static Future<void> _useEmulatorsIfAsked() async {
    if (!_useEmulator || _emulatorsWired) return;
    try {
      FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
      await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
      _emulatorsWired = true;
      debugPrint('Firebase: using emulators at $_emulatorHost');
    } catch (e) {
      // Hot restart: the native SDK keeps the earlier emulator settings.
      debugPrint('Firebase emulators: $e');
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
