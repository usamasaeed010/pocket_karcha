import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_currencies.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/core/navigation/app_navigator.dart';
import 'package:pocket_karcha/features/auth/providers/complete_profile_provider.dart';
import 'package:pocket_karcha/features/auth/widgets/currency_bottom_sheet.dart';
import 'package:pocket_karcha/features/auth/widgets/phone_input_field.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_button.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/app_text_field.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends ConsumerState<CompleteProfileScreen> {
  late final TextEditingController _phone;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController();
    _name = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final displayName =
          ref.read(authRepositoryProvider).currentUser?.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        _name.text = displayName;
      }
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickCurrency() async {
    final urdu = ref.read(localeUrduProvider);
    final code = ref.read(completeProfileProvider).currencyCode;
    final picked = await showCurrencyBottomSheet(
      context,
      selectedCode: code,
      urdu: urdu,
    );
    if (picked != null) {
      ref.read(completeProfileProvider.notifier).setCurrency(picked);
    }
  }

  Future<void> _submit() async {
    final s = ref.read(appStringsProvider);
    final ok = await ref.read(completeProfileProvider.notifier).submit(
          phone: _phone.text,
          displayName: _name.text.trim().isEmpty ? null : _name.text.trim(),
        );
    if (!mounted) return;

    if (ok) {
      AppNavigator.toHome(context);
      return;
    }

    final err = ref.read(completeProfileProvider).error;
    if (err != null) {
      context.showErrorSnack(_errorText(s, err) ?? err);
    }
  }

  String? _errorText(AppStrings s, String? code) {
    if (code == null) return null;
    if (code == 'invalid_phone') {
      return s.isUrdu ? 'درست موبائل نمبر درج کریں' : 'Enter a valid mobile number';
    }
    return code;
  }

  @override
  Widget build(BuildContext context) {
    final urdu = ref.watch(localeUrduProvider);
    final s = AppStrings(urdu);
    final form = ref.watch(completeProfileProvider);
    final currency = AppCurrencies.byCode(form.currencyCode);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.completeProfile),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.completeProfileSubtitle,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  controller: _name,
                  label: s.name,
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                PhoneInputField(controller: _phone),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  s.selectCurrency,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: InkWell(
                    onTap: _pickCurrency,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Text(currency.flag,
                              style: const TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currency.name(urdu),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${currency.code} · ${currency.symbol}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: s.continueToApp,
                  loading: form.loading,
                  onPressed: _submit,
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
