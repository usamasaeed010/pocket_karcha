import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/shared/widgets/app_bottom_sheet.dart';

Future<bool?> showConfirmationBottomSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  required Color confirmColor,
  IconData icon = Icons.info_outline_rounded,
  Color iconColor = AppColors.textSecondary,
  Color messageBackground = const Color(0xFFF8FAFC),
  Color messageBorder = const Color(0xFFE2E8F0),
  double maxHeightFraction = 0.44,
}) {
  return showAppBottomSheet<bool>(
    context: context,
    title: title,
    subtitle: subtitle,
    maxHeightFraction: maxHeightFraction,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: messageBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: messageBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      height: 1.45,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(cancelLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: confirmColor,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
