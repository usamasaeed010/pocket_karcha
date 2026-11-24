import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/features/auth/providers/auth_form_provider.dart';
import 'package:pocket_karcha/features/store_setup/store_gate.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/services/firebase_service.dart';
import 'package:pocket_karcha/shared/widgets/app_button.dart';
import 'package:pocket_karcha/shared/widgets/app_password_field.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/app_text_field.dart';

/// Email sign-in ("I already have a store") or sign-up (fallback when the
/// guest quick start is switched off).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.startInSignUp = false});

  final bool startInSignUp;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _confirm;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController();
    _password = TextEditingController();
    _confirm = TextEditingController();
    _name = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(authFormProvider.notifier)
          .setMode(widget.startInSignUp ? AuthMode.register : AuthMode.signIn);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _name.dispose();
    super.dispose();
  }

  String? _errorText(AppStrings s, String? code) {
    if (code == null) return null;
    switch (code) {
      case 'password_mismatch':
        return s.passwordsMismatch;
      case 'password_short':
        return s.passwordTooShort;
      case 'name_required':
        return s.nameRequired;
      case 'email_in_use':
        return s.isUrdu
            ? 'یہ ای میل پہلے سے رجسٹر ہے'
            : 'Email already registered';
      case 'invalid_email':
        return s.isUrdu ? 'غلط ای میل' : 'Invalid email';
      case 'invalid_credentials':
        return s.isUrdu
            ? 'ای میل یا پاس ورڈ غلط ہے'
            : 'Invalid email or password';
      case 'account_disabled':
        return s.accountDisabled;
      case 'firebase_not_ready':
        return s.firebaseNotReady;
      default:
        return code;
    }
  }

  Future<void> _submit() async {
    final s = ref.read(appStringsProvider);
    final form = ref.read(authFormProvider);
    final result = await ref
        .read(authFormProvider.notifier)
        .submit(
          email: _email.text,
          password: _password.text,
          confirmPassword: form.mode == AuthMode.register
              ? _confirm.text
              : null,
          name: form.mode == AuthMode.register ? _name.text : null,
        );

    if (!mounted) return;

    if (result == null) {
      final err = ref.read(authFormProvider).error;
      if (err != null) {
        context.showErrorSnack(_errorText(s, err) ?? err);
      }
      return;
    }

    // Signed in: open the store, or set one up if this account has none.
    await StoreGate.go(context, ref, result.user!.uid);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final ss = ref.watch(storeStringsProvider);
    final form = ref.watch(authFormProvider);
    final isRegister = form.mode == AuthMode.register;
    final firebaseReady = FirebaseService.isReady;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: canPop
          ? AppBar(backgroundColor: AppColors.cream, elevation: 0)
          : null,
      body: SafeArea(
        top: !canPop,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: canPop ? AppSpacing.sm : AppSpacing.xl),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 44,
                    color: AppColors.brand,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isRegister ? ss.signUpTitle : ss.signInTitle,
                textAlign: TextAlign.center,
                style: AppFonts.display(size: 26),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isRegister ? ss.signUpSub : ss.signInSub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (!firebaseReady) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    s.firebaseNotReady,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _AuthTab(
                        label: s.signIn,
                        selected: !isRegister,
                        onTap: () => ref
                            .read(authFormProvider.notifier)
                            .setMode(AuthMode.signIn),
                      ),
                    ),
                    Expanded(
                      child: _AuthTab(
                        label: s.signUp,
                        selected: isRegister,
                        onTap: () => ref
                            .read(authFormProvider.notifier)
                            .setMode(AuthMode.register),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (isRegister) ...[
                AppTextField(
                  controller: _name,
                  label: s.name,
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppTextField(
                controller: _email,
                label: s.email,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              AppPasswordField(
                controller: _password,
                label: s.password,
                textInputAction: isRegister
                    ? TextInputAction.next
                    : TextInputAction.done,
              ),
              if (isRegister) ...[
                const SizedBox(height: AppSpacing.md),
                AppPasswordField(
                  controller: _confirm,
                  label: s.confirmPassword,
                  textInputAction: TextInputAction.done,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: isRegister ? s.signUp : s.signIn,
                loading: form.loading,
                onPressed: firebaseReady ? _submit : null,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  const _AuthTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
