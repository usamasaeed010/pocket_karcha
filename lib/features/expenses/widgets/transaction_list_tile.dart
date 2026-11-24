import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/stock_units.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/core/utils/date_utils.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_theme.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';

/// Home + History row: category icon, item / note, qty × rate, amount.
class TransactionListTile extends ConsumerWidget {
  const TransactionListTile({
    super.key,
    required this.expense,
    required this.currencyCode,
    // Image attachments are disabled for now.
    // this.onViewReceipt,
    this.onOptions,
    this.showTypeLabel = false,
  });

  final ExpenseModel expense;
  final String currencyCode;
  // final VoidCallback? onViewReceipt;
  final VoidCallback? onOptions;

  /// Shows the Sale / Purchase / Expense badge and full date (History).
  final bool showTypeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urdu = ref.watch(localeUrduProvider);
    final s = ref.watch(appStringsProvider);
    final cat = ref.watch(categoryByIdProvider(expense.categoryId));
    final categoryLabel = cat.label(urdu);
    final type = TransactionType.fromRecord(expense.type);
    final look = lookFor(type, s);

    final title = expense.hasItemName
        ? expense.itemName!.trim()
        : (expense.note.isNotEmpty ? expense.note : categoryLabel);

    final details = <String>[];
    if (expense.hasQuantity) {
      final unit = StockUnits.byKey(expense.unit);
      final qty = '${StockUnits.formatQty(expense.quantity!)} ${unit.short(urdu)}';
      details.add(
        expense.unitPrice != null
            ? '$qty × ${CurrencyFormatter.format(expense.unitPrice!, currencyCode: currencyCode)}'
            : qty,
      );
    }
    if (title != categoryLabel) details.add(categoryLabel);
    details.add(
      showTypeLabel
          ? _formatDate(expense.date)
          : AppDateUtils.formatShort(expense.date),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOptions,
        onLongPress: onOptions,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _CategoryIcon(
                icon: cat.icon,
                color: cat.color,
                look: look,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      details.join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    // Image attachments are disabled for now — no receipt badge.
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${look.sign}${CurrencyFormatter.format(expense.amount, currencyCode: currencyCode)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: look.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (showTypeLabel)
                    _TypeBadge(look: look)
                  else if (onOptions != null)
                    Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d-$m-${date.year}';
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({
    required this.icon,
    required this.color,
    required this.look,
  });

  final IconData icon;
  final Color color;
  final TransactionTypeLook look;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                color: look.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                look.type.isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.look});

  final TransactionTypeLook look;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: look.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: look.border),
      ),
      child: Text(
        look.title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: look.color,
        ),
      ),
    );
  }
}
