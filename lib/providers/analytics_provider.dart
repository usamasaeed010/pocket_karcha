import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/services/firebase_service.dart';

/// Keeps Analytics user ID in sync with Firebase Auth (no PII beyond uid).
final analyticsUserSyncProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (_, next) {
    final uid = next.valueOrNull?.uid;
    FirebaseService.setAnalyticsUserId(uid);
  });
});
