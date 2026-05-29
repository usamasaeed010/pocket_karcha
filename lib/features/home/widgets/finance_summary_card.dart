import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_theme.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';

class FinanceSummaryCard extends ConsumerWidget {
  const FinanceSummaryCard({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(selectedCurrencyProvider);
    final period = ref.watch(dashboardPeriodProvider);
    final spent = ref.watch(periodTotalProvider);
    final income = ref.watch(periodIncomeProvider);
    final balance = ref.watch(periodBalanceProvider);
    final budgetUsage = ref.watch(budgetUsageProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            strings.periodSummaryTitle(period).toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.1,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(balance, currencyCode: currencyCode),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 32,
                color: balance >= 0
                    ? AppColors.textPrimary
                    : AppColors.expense,
              ),
            ),
          ),
          Text(
            strings.balance,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  look: lookFor(TransactionType.got, strings),
                  amount: income,
                  currencyCode: currencyCode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatPill(
                  look: lookFor(TransactionType.gave, strings),
                  amount: spent,
                  currencyCode: currencyCode,
                ),
              ),
            ],
          ),
          if (period == DashboardPeriod.month && budgetUsage > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(
                  strings.spent,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${budgetUsage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.spentBar,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (budgetUsage / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: const Color(0xFFF1F5F9),
                color: AppColors.spentBar,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: look.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: look.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: look.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(look.icon, size: 16, color: look.onColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      look.title,
                      style: TextStyle(
                        color: look.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      look.subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.format(amount, currencyCode: currencyCode),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: look.color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
