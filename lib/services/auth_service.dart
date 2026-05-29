import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pocket_karcha/services/firebase_service.dart';

class AuthService {
  AuthService._(this._auth);

  final FirebaseAuth _auth;

  static AuthService? _instance;

  static AuthService? get instance {
    if (!FirebaseService.isReady) return null;
    return _instance ??= AuthService._(FirebaseAuth.instance);
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => currentUser != null;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> updateDisplayName(String name) async {
    await currentUser?.updateDisplayName(name.trim());
    await currentUser?.reload();
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('AuthService: signed out');
  }
}
