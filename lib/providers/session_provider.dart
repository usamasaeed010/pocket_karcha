import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/providers/firebase_providers.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';
import 'package:pocket_karcha/services/preferences_service.dart';

class SessionState {
  const SessionState({
    this.ready = false,
    this.onboardingComplete = false,
    this.profileComplete = false,
    this.sessionType = SessionType.none,
    this.userId,
    this.email,
    this.displayName,
    this.phone,
    this.currency,
    this.avatarUrl,
  });

  final bool ready;
  final bool onboardingComplete;
  final bool profileComplete;
  final SessionType sessionType;
  final String? userId;
  final String? email;
  final String? displayName;
  final String? phone;
  final String? currency;
  final String? avatarUrl;

  bool get canEnterHome =>
      hasAccount && profileComplete && sessionType != SessionType.none;

  bool get hasAccount =>
      sessionType == SessionType.firebase && userId != null;

  bool get needsProfileSetup => hasAccount && !profileComplete;

  SessionState copyWith({
    bool? ready,
    bool? onboardingComplete,
    bool? profileComplete,
    SessionType? sessionType,
    String? userId,
    String? email,
    String? displayName,
    String? phone,
    String? currency,
    String? avatarUrl,
  }) {
    return SessionState(
      ready: ready ?? this.ready,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      profileComplete: profileComplete ?? this.profileComplete,
      sessionType: sessionType ?? this.sessionType,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      currency: currency ?? this.currency,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState();

  PreferencesService get _prefs => ref.read(preferencesServiceProvider);

  Future<void> load({User? firebaseUser}) async {
    var type = _prefs.sessionType;
    var userId = _prefs.sessionUserId;
    var email = _prefs.userEmail;
    var name = _prefs.userName;
    var profileComplete = _prefs.profileComplete;
    var phone = _prefs.userPhone;
    var currency = _prefs.userCurrency;
    var avatarUrl = _prefs.avatarUrl;

    if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
      type = SessionType.firebase;
      userId = firebaseUser.uid;
      email = firebaseUser.email ?? email;
      name = firebaseUser.displayName ?? name;

      final profiles = ref.read(userProfileServiceProvider);
      if (profiles != null) {
        final p = await profiles.fetchProfile(firebaseUser.uid);
        if (p?.isDisabled == true) {
          await ref.read(authServiceProvider)?.signOut();
          await _prefs.clearSession();
          state = SessionState(
            ready: true,
            onboardingComplete: _prefs.onboardingComplete,
          );
          return;
        }
        phone = p?.phone ?? phone;
        currency = p?.currency ?? currency;
        avatarUrl = p?.avatarUrl ?? avatarUrl;
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          await _prefs.setAvatarUrl(avatarUrl);
        }
        if (!profileComplete) {
          profileComplete = await profiles.isProfileComplete(firebaseUser.uid);
        }
      }

      await _prefs.setFirebaseSession(
        uid: userId,
        email: email ?? '',
        name: name,
        profileComplete: profileComplete,
      );
    } else if (type == SessionType.firebase) {
      await _prefs.clearSession();
      type = SessionType.none;
      userId = null;
      email = null;
      name = null;
      profileComplete = false;
    }

    state = SessionState(
      ready: true,
      onboardingComplete: _prefs.onboardingComplete,
      profileComplete: profileComplete,
      sessionType: type,
      userId: userId,
      email: email,
      displayName: name,
      phone: phone,
      currency: currency ?? 'PKR',
      avatarUrl: avatarUrl,
    );
  }

  Future<void> completeOnboarding() async {
    await _prefs.setOnboardingComplete();
    state = state.copyWith(onboardingComplete: true);
  }

  Future<void> reload() => load();

  Future<void> applyFirebaseUser(
    User user, {
    required bool profileComplete,
    String? currency,
    String? phone,
  }) async {
    await _prefs.setFirebaseSession(
      uid: user.uid,
      email: user.email ?? '',
      name: user.displayName,
      profileComplete: profileComplete,
    );
    if (profileComplete && currency != null) {
      await _prefs.saveProfileMeta(
        userId: user.uid,
        phone: phone ?? '',
        countryCode: 'PK',
        dialCode: '+92',
        currency: currency,
        profileComplete: true,
      );
    }
    state = state.copyWith(
      sessionType: SessionType.firebase,
      userId: user.uid,
      email: user.email,
      displayName: user.displayName,
      profileComplete: profileComplete,
      phone: phone,
      currency: currency ?? state.currency,
    );
  }

  Future<void> markProfileComplete({
    required String phone,
    required String currency,
  }) async {
    state = state.copyWith(
      profileComplete: true,
      phone: phone,
      currency: currency,
    );
  }

  Future<void> updateCurrency(String currency) async {
    final uid = state.userId;
    if (uid == null) return;
    await _prefs.saveProfileMeta(
      userId: uid,
      phone: state.phone ?? '',
      countryCode: 'PK',
      dialCode: '+92',
      currency: currency,
      profileComplete: state.profileComplete,
    );
    state = state.copyWith(currency: currency);
  }

  Future<void> updateAvatarUrl(String url) async {
    await _prefs.setAvatarUrl(url);
    state = state.copyWith(avatarUrl: url);
  }

  Future<void> updateDisplayName(String name) async {
    final uid = state.userId;
    if (uid == null) return;
    final profiles = ref.read(userProfileServiceProvider);
    if (profiles != null) {
      await profiles.updateDisplayName(uid: uid, displayName: name);
    } else {
      await _prefs.setUserName(name.trim());
    }
    state = state.copyWith(displayName: name.trim());
  }

  Future<void> signOut() async {
    await _prefs.clearSession();
    state = const SessionState(ready: true, onboardingComplete: true);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);
