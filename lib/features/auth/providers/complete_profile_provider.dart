import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_currencies.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/firebase_providers.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/providers/session_provider.dart';

class CompleteProfileState {
  const CompleteProfileState({
    this.countryCode = 'PK',
    this.dialCode = '+92',
    this.currencyCode = 'PKR',
    this.loading = false,
    this.error,
  });

  final String countryCode;
  final String dialCode;
  final String currencyCode;
  final bool loading;
  final String? error;

  CompleteProfileState copyWith({
    String? countryCode,
    String? dialCode,
    String? currencyCode,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return CompleteProfileState(
      countryCode: countryCode ?? this.countryCode,
      dialCode: dialCode ?? this.dialCode,
      currencyCode: currencyCode ?? this.currencyCode,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CompleteProfileNotifier extends Notifier<CompleteProfileState> {
  @override
  CompleteProfileState build() => const CompleteProfileState();

  void onCountryChanged(CountryCode code) {
    final currency = AppCurrencies.forCountryCode(code.code ?? 'PK');
    state = state.copyWith(
      countryCode: code.code ?? 'PK',
      dialCode: code.dialCode ?? '+92',
      currencyCode: currency.code,
      clearError: true,
    );
  }

  void setCurrency(String code) {
    state = state.copyWith(currencyCode: code, clearError: true);
  }

  Future<bool> submit({
    required String phone,
    String? displayName,
  }) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) {
      state = state.copyWith(error: 'invalid_phone');
      return false;
    }

    final uid = ref.read(currentUserIdProvider);
    final profiles = ref.read(userProfileServiceProvider);
    if (uid == null || profiles == null) {
      state = state.copyWith(error: 'firebase_not_ready');
      return false;
    }

    state = state.copyWith(loading: true, clearError: true);
    try {
      final urdu = ref.read(localeUrduProvider);
      await profiles.completeProfile(
        uid: uid,
        phone: digits,
        countryCode: state.countryCode,
        dialCode: state.dialCode,
        currency: state.currencyCode,
        urdu: urdu,
        displayName: displayName,
      );

      await ref.read(sessionProvider.notifier).markProfileComplete(
            phone: '${state.dialCode}$digits',
            currency: state.currencyCode,
          );

      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        await ref.read(sessionProvider.notifier).applyFirebaseUser(
              user,
              profileComplete: true,
              currency: state.currencyCode,
              phone: '${state.dialCode}$digits',
            );
      }

      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }
}

final completeProfileProvider =
    NotifierProvider<CompleteProfileNotifier, CompleteProfileState>(
  CompleteProfileNotifier.new,
);
