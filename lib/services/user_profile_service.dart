import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:pocket_karcha/services/firebase_service.dart';
import 'package:pocket_karcha/data/models/user_profile_model.dart';
import 'package:pocket_karcha/services/firestore_service.dart';
import 'package:pocket_karcha/services/preferences_service.dart';
import 'package:pocket_karcha/services/storage_service.dart';

class UserProfileService {
  UserProfileService({
    required FirestoreService firestore,
    required PreferencesService prefs,
  })  : _firestore = firestore,
        _prefs = prefs;

  final FirestoreService _firestore;
  final PreferencesService _prefs;

  Future<UserProfileModel?> fetchProfile(String uid) =>
      _firestore.getUserProfile(uid);

  Future<bool> isProfileComplete(String uid) async {
    if (_prefs.profileComplete && _prefs.sessionUserId == uid) {
      return true;
    }
    final profile = await _firestore.getUserProfile(uid);
    return profile?.profileComplete ?? false;
  }

  Future<void> createInitialProfile({
    required User user,
    String? displayName,
    bool urdu = false,
  }) async {
    final profile = UserProfileModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName ?? user.displayName,
      locale: urdu ? 'ur' : 'en',
      profileComplete: false,
    );
    await _firestore.createUserProfile(profile);
  }

  Future<void> disableAccount(String uid) async {
    final existing = await _firestore.getUserProfile(uid);
    if (existing == null) return;
    await _firestore.saveUserProfile(existing.copyWith(isDisabled: true));
  }

  Future<void> completeProfile({
    required String uid,
    required String phone,
    required String countryCode,
    required String dialCode,
    required String currency,
    required bool urdu,
    String? displayName,
  }) async {
    final existing = await _firestore.getUserProfile(uid);
    final profile = (existing ??
            UserProfileModel(
              uid: uid,
              email: _prefs.userEmail ?? '',
            ))
        .copyWith(
      displayName: displayName ?? existing?.displayName,
      phone: phone,
      countryCode: countryCode,
      dialCode: dialCode,
      currency: currency,
      locale: urdu ? 'ur' : 'en',
      profileComplete: true,
    );

    await _firestore.saveUserProfile(profile);
    await _prefs.saveProfileMeta(
      userId: uid,
      phone: phone,
      countryCode: countryCode,
      dialCode: dialCode,
      currency: currency,
      profileComplete: true,
    );
  }

  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;

    final existing = await _firestore.getUserProfile(uid);
    final profile = (existing ??
            UserProfileModel(
              uid: uid,
              email: _prefs.userEmail ?? '',
            ))
        .copyWith(displayName: trimmed);

    await _firestore.saveUserProfile(profile);
    await _prefs.setUserName(trimmed);

    if (FirebaseService.isReady) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        await user.updateDisplayName(trimmed);
      }
    }
  }

  Future<String> updateAvatar({
    required String uid,
    required File file,
    required StorageService storage,
  }) async {
    final url = await storage.uploadAvatar(uid: uid, file: file);
    final existing = await _firestore.getUserProfile(uid);
    final profile = (existing ??
            UserProfileModel(
              uid: uid,
              email: _prefs.userEmail ?? '',
            ))
        .copyWith(avatarUrl: url);
    await _firestore.saveUserProfile(profile);
    await _prefs.setAvatarUrl(url);
    return url;
  }
}
