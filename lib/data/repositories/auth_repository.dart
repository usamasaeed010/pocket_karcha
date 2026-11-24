import 'package:firebase_auth/firebase_auth.dart';
import 'package:pocket_karcha/data/models/auth_result.dart';
import 'package:pocket_karcha/services/auth_service.dart';
import 'package:pocket_karcha/services/push_service.dart';
import 'package:pocket_karcha/services/user_profile_service.dart';

class AuthRepository {
  AuthRepository({
    AuthService? auth,
    UserProfileService? profiles,
  })  : _auth = auth,
        _profiles = profiles;

  final AuthService? _auth;
  final UserProfileService? _profiles;

  bool get isAvailable => _auth != null;

  Stream<User?> authState() =>
      _auth?.authStateChanges() ?? const Stream.empty();

  User? get currentUser => _auth?.currentUser;

  Future<AuthResult> signIn({
    required String email,
    required String password,
    required bool urdu,
  }) async {
    if (_auth == null) {
      return const AuthResult(errorCode: 'firebase_not_ready');
    }
    try {
      final cred = await _auth.signInWithEmail(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        return const AuthResult(errorCode: 'unknown');
      }

      var needsSetup = true;
      if (_profiles != null) {
        final profile = await _profiles.fetchProfile(user.uid);
        if (profile?.isDisabled == true) {
          await _auth.signOut();
          return const AuthResult(errorCode: 'account_disabled', accountDisabled: true);
        }
        needsSetup = !(await _profiles.isProfileComplete(user.uid));
      }

      return AuthResult(user: user, needsProfileSetup: needsSetup);
    } on FirebaseAuthException catch (e) {
      return AuthResult(errorCode: _mapCode(e));
    }
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    required bool urdu,
  }) async {
    if (_auth == null) {
      return const AuthResult(errorCode: 'firebase_not_ready');
    }
    try {
      final cred = await _auth.registerWithEmail(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        return const AuthResult(errorCode: 'unknown');
      }

      if (name.trim().isNotEmpty) {
        await _auth.updateDisplayName(name.trim());
      }

      await _profiles?.createInitialProfile(
        user: user,
        displayName: name.trim(),
        urdu: urdu,
      );

      return AuthResult(user: user, needsProfileSetup: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(errorCode: _mapCode(e));
    }
  }

  Future<void> signOut() async {
    final uid = _auth?.currentUser?.uid;
    if (uid != null) {
      // Stop new-order alerts on this phone while still signed in. Waits a
      // few seconds at most so logging out offline is not blocked.
      await PushService.instance
          .unregisterDevice(uid)
          .timeout(const Duration(seconds: 4), onTimeout: () {});
    }
    await _auth?.signOut();
  }

  String _mapCode(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'email_in_use';
      case 'invalid-email':
        return 'invalid_email';
      case 'weak-password':
        return 'password_short';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'invalid_credentials';
      default:
        return e.code;
    }
  }
}
