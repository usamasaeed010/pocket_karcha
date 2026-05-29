import 'package:firebase_auth/firebase_auth.dart';

class AuthResult {
  const AuthResult({
    this.user,
    this.needsProfileSetup = false,
    this.errorCode,
    this.accountDisabled = false,
  });

  final User? user;
  final bool needsProfileSetup;
  final String? errorCode;
  final bool accountDisabled;

  bool get isSuccess => user != null && errorCode == null && !accountDisabled;
}
