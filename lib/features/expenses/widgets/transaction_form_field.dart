import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';

const _fieldRadius = 12.0;
const _fieldFill = Color(0xFFF8FAFC);

/// Labelled text field used on the Add Transaction form.
class TransactionFormField extends StatelessWidget {
  const TransactionFormField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.prefixText,
    this.maxLines = 1,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final String? prefixText;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  static InputDecoration _decoration({
    String? hint,
    Widget? suffixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 15,
      ),
      // Always-visible prefix (prefixText hides itself until focus but
      // still takes space, leaving a gap before the hint).
      prefixIcon: prefixText == null
          ? null
          : Padding(
              padding: const EdgeInsetsDirectional.only(start: 14, end: 6),
              child: Text(
                prefixText.trim(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      prefixIconConstraints: const BoxConstraints(),
      filled: true,
      fillColor: _fieldFill,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: _decoration(
            hint: hint,
            suffixIcon: suffixIcon,
            prefixText: prefixText,
          ),
        ),
      ],
    );
  }
}

/// Tap-only field showing [value] instead of a controller.
class TransactionPickerField extends StatelessWidget {
  const TransactionPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.suffixIcon,
    required this.onTap,
    this.leading,
  });

  final String label;
  final String? value;
  final String hint;
  final Widget suffixIcon;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final display = value != null && value!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: _fieldFill,
          borderRadius: BorderRadius.circular(_fieldRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(_fieldRadius),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_fieldRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      display ? value! : hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: display
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  suffixIcon,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
