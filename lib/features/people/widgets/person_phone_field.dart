import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/phone_hints.dart';

class PersonPhoneField extends StatelessWidget {
  const PersonPhoneField({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.dialCode,
    required this.onCountryChanged,
    required this.urdu,
  });

  final TextEditingController controller;
  final String countryCode;
  final String dialCode;
  final ValueChanged<CountryCode> onCountryChanged;
  final bool urdu;

  @override
  Widget build(BuildContext context) {
    final hint = PhoneHints.hintForCountry(countryCode, urdu);
    final maxLen = PhoneHints.maxLengthForCountry(countryCode);

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
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              CountryCodePicker(
                onChanged: onCountryChanged,
                initialSelection: countryCode,
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
                    if (maxLen != null)
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
      ],
    );
  }
}
