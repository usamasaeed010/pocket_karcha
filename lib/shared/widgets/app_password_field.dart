import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';

class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputAction? textInputAction;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: widget.controller,
          obscureText: _obscure,
          textInputAction: widget.textInputAction,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
      ],
    );
  }
}
