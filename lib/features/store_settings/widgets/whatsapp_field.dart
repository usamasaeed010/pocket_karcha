import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/phone_hints.dart';

/// Country code + local number, cream style. Used in setup and store details.
class WhatsAppField extends StatelessWidget {
  const WhatsAppField({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.onCountryChanged,
    required this.urdu,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<CountryCode> onCountryChanged;
  final ValueChanged<String>? onChanged;
  final bool urdu;
  final bool autofocus;

  /// Local part of a stored international number, e.g. "923001234567" with
  /// "+92" → "3001234567".
  static String localPart(String international, String dialCode) {
    final dial = dialCode.replaceAll(RegExp(r'\D'), '');
    if (dial.isNotEmpty && international.startsWith(dial)) {
      return international.substring(dial.length);
    }
    return international;
  }

  @override
  Widget build(BuildContext context) {
    final maxLen = PhoneHints.maxLengthForCountry(countryCode);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.creamCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.creamBorder),
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
            padding: const EdgeInsets.symmetric(horizontal: 6),
            textStyle: const TextStyle(fontSize: 15, color: AppColors.ink),
          ),
          Container(width: 1, height: 30, color: AppColors.creamBorder),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                if (maxLen != null) LengthLimitingTextInputFormatter(maxLen + 1),
              ],
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: PhoneHints.hintForCountry(countryCode, urdu),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
