import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';

/// Colour of the "Pending" tag on udhaar entries.
const pendingColor = AppColors.pending;

/// Marks a pending (udhaar) entry as paid.
void markEntryPaid(WidgetRef ref, ExpenseModel entry) {
  final ss = ref.read(storeStringsProvider);
  // Firestore shows the change at once (even offline) and syncs later.
  unawaited(
    ref
        .read(expenseActionsProvider)
        .update(entry.copyWith(status: EntryStatus.paid))
        .catchError((Object _) {
      showRootSnack(message: ss.somethingWrong, type: AppSnackType.error);
    }),
  );
  showRootSnack(message: ss.markedPaid, type: AppSnackType.success);
}

/// Paid / Pending choice for one record.
class PaidPendingToggle extends StatelessWidget {
  const PaidPendingToggle({
    super.key,
    required this.pending,
    required this.onChanged,
    required this.paidLabel,
    required this.pendingLabel,
  });

  final bool pending;
  final ValueChanged<bool> onChanged;
  final String paidLabel;
  final String pendingLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatusChoice(
            label: paidLabel,
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.brand,
            selected: !pending,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatusChoice(
            label: pendingLabel,
            icon: Icons.schedule_rounded,
            color: pendingColor,
            selected: pending,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

/// One selectable status button (Paid, Pending, Personal …).
class StatusChoice extends StatelessWidget {
  const StatusChoice({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : AppColors.creamCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.creamBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: selected ? color : AppColors.inkSoft),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected ? color : AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
