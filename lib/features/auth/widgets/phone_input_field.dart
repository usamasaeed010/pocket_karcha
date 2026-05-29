import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/core/constants/phone_hints.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/features/auth/providers/complete_profile_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';

class PhoneInputField extends ConsumerWidget {
  const PhoneInputField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urdu = ref.watch(localeUrduProvider);
    final s = AppStrings(urdu);
    final profile = ref.watch(completeProfileProvider);
    final hint = PhoneHints.hintForCountry(profile.countryCode, urdu);
    final maxLen = PhoneHints.maxLengthForCountry(profile.countryCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          PhoneHints.label(urdu),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              CountryCodePicker(
                onChanged: (code) => ref
                    .read(completeProfileProvider.notifier)
                    .onCountryChanged(code),
                initialSelection: profile.countryCode,
                favorite: const ['+92', 'PK'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(fontSize: 15),
              ),
              Container(
                width: 1,
                height: 32,
                color: const Color(0xFFE2E8F0),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(maxLen),
                  ],
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${s.isUrdu ? 'ملک' : 'Country'}: ${profile.countryCode} · ${profile.dialCode}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
