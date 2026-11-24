import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_theme.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/history_provider.dart';

/// History summary: net profit / loss plus Sale · Purchase · Expense totals
/// for the filtered list.
class HistoryBalanceCard extends ConsumerWidget {
  const HistoryBalanceCard({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final currencyCode = ref.watch(selectedCurrencyProvider);
    final sales = ref.watch(historyYouGotProvider);
    final purchases = ref.watch(historyPurchasesProvider);
    final expenses = ref.watch(historyExpensesOnlyProvider);
    final profit = ref.watch(historyClosingBalanceProvider);
    final isLoss = profit < 0;
    final resultColor = isLoss ? AppColors.expense : AppColors.sale;
    String fmt(double v) =>
        CurrencyFormatter.format(v, currencyCode: currencyCode);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isLoss
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
                  color: resultColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoss ? s.netLoss : s.netProfit,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        '${isLoss ? '-' : ''}${fmt(profit.abs())}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: resultColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  look: lookFor(TransactionType.got, s),
                  value: fmt(sales),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  look: lookFor(TransactionType.purchase, s),
                  value: fmt(purchases),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  look: lookFor(TransactionType.gave, s),
                  value: fmt(expenses),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.look, required this.value});

  final TransactionTypeLook look;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: look.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(look.icon, size: 14, color: look.color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  look.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: look.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
