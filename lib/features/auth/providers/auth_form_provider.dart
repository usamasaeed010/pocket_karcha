import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/data/models/auth_result.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/providers/session_provider.dart';
import 'package:pocket_karcha/services/firebase_service.dart';

enum AuthMode { signIn, register }

class AuthFormState {
  const AuthFormState({
    this.mode = AuthMode.signIn,
    this.loading = false,
    this.error,
    this.lastResult,
  });

  final AuthMode mode;
  final bool loading;
  final String? error;
  final AuthResult? lastResult;

  AuthFormState copyWith({
    AuthMode? mode,
    bool? loading,
    String? error,
    AuthResult? lastResult,
    bool clearError = false,
  }) {
    return AuthFormState(
      mode: mode ?? this.mode,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

class AuthFormNotifier extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void setMode(AuthMode mode) {
    state = state.copyWith(mode: mode, clearError: true);
  }

  Future<AuthResult?> submit({
    required String email,
    required String password,
    String? confirmPassword,
    String? name,
  }) async {
    final trimmedEmail = email.trim();
    if (!_isValidEmail(trimmedEmail)) {
      state = state.copyWith(error: 'invalid_email');
      return null;
    }

    if (!FirebaseService.isReady) {
      state = state.copyWith(error: 'firebase_not_ready');
      return null;
    }

    if (state.mode == AuthMode.register) {
      if ((name ?? '').trim().isEmpty) {
        state = state.copyWith(error: 'name_required');
        return null;
      }
      if (password.length < 6) {
        state = state.copyWith(error: 'password_short');
        return null;
      }
      if (password != confirmPassword) {
        state = state.copyWith(error: 'password_mismatch');
        return null;
      }
    } else if (password.isEmpty) {
      state = state.copyWith(error: 'invalid_credentials');
      return null;
    }

    state = state.copyWith(loading: true, clearError: true);

    final repo = ref.read(authRepositoryProvider);
    final urdu = ref.read(localeUrduProvider);

    AuthResult result;
    if (state.mode == AuthMode.signIn) {
      result = await repo.signIn(
        email: trimmedEmail,
        password: password,
        urdu: urdu,
      );
    } else {
      result = await repo.register(
        email: trimmedEmail,
        password: password,
        name: name!.trim(),
        urdu: urdu,
      );
    }

    if (result.isSuccess && result.user != null) {
      await ref.read(sessionProvider.notifier).applyFirebaseUser(
            result.user!,
            profileComplete: !result.needsProfileSetup,
          );
    }

    state = state.copyWith(
      loading: false,
      error: result.errorCode,
      lastResult: result,
    );

    return result.isSuccess ? result : null;
  }

  bool _isValidEmail(String email) =>
      email.contains('@') && email.contains('.');
}

final authFormProvider =
    NotifierProvider<AuthFormNotifier, AuthFormState>(AuthFormNotifier.new);
