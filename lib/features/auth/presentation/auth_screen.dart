import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/core/navigation/app_navigator.dart';
import 'package:pocket_karcha/core/navigation/app_routes.dart';
import 'package:pocket_karcha/features/auth/providers/auth_form_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/services/firebase_service.dart';
import 'package:pocket_karcha/shared/widgets/app_button.dart';
import 'package:pocket_karcha/shared/widgets/app_password_field.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/app_text_field.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

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
    final result = await ref.read(authFormProvider.notifier).submit(
          email: _email.text,
          password: _password.text,
          confirmPassword:
              form.mode == AuthMode.register ? _confirm.text : null,
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

    if (result.needsProfileSetup) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.completeProfile);
    } else {
      AppNavigator.toHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final form = ref.watch(authFormProvider);
    final isRegister = form.mode == AuthMode.register;
    final firebaseReady = FirebaseService.isReady;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  isRegister ? s.createAccountTitle : s.welcomeBack,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  s.loginHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
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
