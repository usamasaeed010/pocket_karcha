import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_theme.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';

/// Gradient hero card: profit / loss for the selected period plus
/// Sale · Purchase · Expense totals.
class FinanceSummaryCard extends ConsumerWidget {
  const FinanceSummaryCard({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final currencyCode = ref.watch(selectedCurrencyProvider);
    final period = ref.watch(dashboardPeriodProvider);
    final sales = ref.watch(periodSalesProvider);
    final purchases = ref.watch(periodPurchasesProvider);
    final expenses = ref.watch(periodExpensesOnlyProvider);
    final profit = ref.watch(periodProfitProvider);
    final isLoss = profit < 0;
    final margin = sales > 0 ? (profit / sales * 100).round() : null;
    final colors = isLoss ? AppColors.lossGradient : AppColors.heroGradient;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: _Bubble(size: 160, opacity: 0.08),
            ),
            Positioned(
              right: 40,
              bottom: -70,
              child: _Bubble(size: 140, opacity: 0.06),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLoss
                                  ? Icons.trending_down_rounded
                                  : Icons.trending_up_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.periodResultTitle(period, loss: isLoss),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (margin != null)
                        Text(
                          s.marginLabel('$margin'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      '${isLoss ? '-' : ''}${CurrencyFormatter.format(profit.abs(), currencyCode: currencyCode)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 34,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${s.youGot} − ${s.purchase} − ${s.youGave}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStat(
                          look: lookFor(TransactionType.got, s),
                          amount: sales,
                          currencyCode: currencyCode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HeroStat(
                          look: lookFor(TransactionType.purchase, s),
                          amount: purchases,
                          currencyCode: currencyCode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HeroStat(
                          look: lookFor(TransactionType.gave, s),
                          amount: expenses,
                          currencyCode: currencyCode,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.look,
    required this.amount,
    required this.currencyCode,
  });

  final TransactionTypeLook look;
  final double amount;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(look.icon, size: 13, color: look.color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  look.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              CurrencyFormatter.format(amount, currencyCode: currencyCode),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
