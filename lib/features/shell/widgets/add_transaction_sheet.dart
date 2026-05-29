import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/presentation/add_expense_screen.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_theme.dart';
import 'package:pocket_karcha/shared/widgets/app_bottom_sheet.dart';

Future<void> showAddTransactionSheet(
  BuildContext context, {
  required AppStrings strings,
}) async {
  final type = await showAppBottomSheet<TransactionType>(
    context: context,
    title: strings.addTransaction,
    subtitle: strings.chooseTransactionType,
    maxHeightFraction: 0.52,
    child: _AddTransactionPicker(strings: strings),
  );

  if (type == null || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AddExpenseScreen(initialType: type),
    ),
  );
}

class _AddTransactionPicker extends StatelessWidget {
  const _AddTransactionPicker({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypeOptionTile(
            look: lookFor(TransactionType.gave, strings),
            onTap: () => Navigator.pop(context, TransactionType.gave),
          ),
          const SizedBox(height: 12),
          _TypeOptionTile(
            look: lookFor(TransactionType.got, strings),
            onTap: () => Navigator.pop(context, TransactionType.got),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
        ],
      ),
    );
  }
}

class _TypeOptionTile extends StatelessWidget {
  const _TypeOptionTile({
    required this.look,
    required this.onTap,
  });

  final TransactionTypeLook look;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: look.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: look.border, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: look.color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(look.icon, color: look.onColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        look.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: look.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        look.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: look.color,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
