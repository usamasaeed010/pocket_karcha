import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/data/repositories/auth_repository.dart';
import 'package:pocket_karcha/providers/firebase_providers.dart';
import 'package:pocket_karcha/providers/session_provider.dart';
import 'package:pocket_karcha/services/preferences_service.dart' show SessionType;
import 'package:pocket_karcha/services/firebase_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(authServiceProvider),
    profiles: ref.watch(userProfileServiceProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authState();
});

final currentUserIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionProvider);
  if (session.userId != null) return session.userId;
  if (FirebaseService.isReady) {
    return ref.watch(authStateProvider).valueOrNull?.uid;
  }
  return null;
});

final guestModeProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider).sessionType == SessionType.guest;
});

final selectedCurrencyProvider = Provider<String>((ref) {
  final session = ref.watch(sessionProvider);
  return session.currency ?? 'PKR';
});

/// Emits on sign-in/out AND on account linking (anonymous → email backup).
final firebaseUserProvider = StreamProvider<User?>((ref) {
  if (!FirebaseService.isReady) return Stream.value(null);
  return FirebaseAuth.instance.userChanges();
});
