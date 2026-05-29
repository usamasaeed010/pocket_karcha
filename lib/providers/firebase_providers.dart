import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';
import 'package:pocket_karcha/services/auth_service.dart';
import 'package:pocket_karcha/services/firestore_service.dart';
import 'package:pocket_karcha/services/storage_service.dart';
import 'package:pocket_karcha/services/user_profile_service.dart';

final authServiceProvider = Provider<AuthService?>((ref) {
  return AuthService.instance;
});

final firestoreServiceProvider = Provider<FirestoreService?>((ref) {
  return FirestoreService.create();
});

final storageServiceProvider = Provider<StorageService?>((ref) {
  return StorageService.create();
});

final userProfileServiceProvider = Provider<UserProfileService?>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  if (firestore == null) return null;
  return UserProfileService(
    firestore: firestore,
    prefs: ref.watch(preferencesServiceProvider),
  );
});
