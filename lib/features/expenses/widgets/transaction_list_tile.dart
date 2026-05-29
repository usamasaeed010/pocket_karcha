import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/core/utils/date_utils.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_theme.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';

/// Home + History transaction row — compact layout, clear receipt indicator.
class TransactionListTile extends ConsumerWidget {
  const TransactionListTile({
    super.key,
    required this.expense,
    required this.currencyCode,
    this.onViewReceipt,
    this.showTypeLabel = false,
  });

  final ExpenseModel expense;
  final String currencyCode;
  final VoidCallback? onViewReceipt;
  final bool showTypeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urdu = ref.watch(localeUrduProvider);
    final s = ref.watch(appStringsProvider);
    final cat = ref.watch(categoryByIdProvider(expense.categoryId));
    final categoryLabel = cat.label(urdu);
    final type =
        expense.isIncome ? TransactionType.got : TransactionType.gave;
    final look = lookFor(type, s);
    final hasReceipt = expense.hasReceipt && onViewReceipt != null;
    final title = expense.note.isNotEmpty ? expense.note : categoryLabel;
    final dateLabel = showTypeLabel
        ? _formatDate(expense.date)
        : '${categoryLabel} · ${AppDateUtils.formatShort(expense.date)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasReceipt ? onViewReceipt : null,
        child: Tooltip(
          message: hasReceipt ? s.tapReceiptHint : '',
          triggerMode: hasReceipt
              ? TooltipTriggerMode.longPress
              : TooltipTriggerMode.manual,
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _TypeIcon(look: look),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showTypeLabel) ...[
                      Text(
                        expense.isIncome ? s.youGot : s.youGave,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (expense.hasReceipt) ...[
                          const SizedBox(width: 6),
                          _ReceiptBadge(
                            label: s.receipt,
                            active: hasReceipt,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${expense.isIncome ? '+' : '-'}${CurrencyFormatter.format(expense.amount, currencyCode: currencyCode)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: look.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (hasReceipt) ...[
                    const SizedBox(height: 4),
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 16,
                      color: AppColors.navActive,
                    ),
                  ],
                ],
              ),
            ],
          ),
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

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.look});

  final TransactionTypeLook look;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: look.surface,
        shape: BoxShape.circle,
        border: Border.all(color: look.border),
      ),
      child: Icon(look.icon, color: look.color, size: 21),
    );
  }
}

class _ReceiptBadge extends StatelessWidget {
  const _ReceiptBadge({
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? AppColors.navActive.withValues(alpha: 0.12)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active
              ? AppColors.navActive.withValues(alpha: 0.35)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 12,
            color: active ? AppColors.navActive : AppColors.textSecondary,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.navActive : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
