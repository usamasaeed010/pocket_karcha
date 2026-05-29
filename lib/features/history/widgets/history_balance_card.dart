import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/history_provider.dart';

class HistoryBalanceCard extends ConsumerWidget {
  const HistoryBalanceCard({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(selectedCurrencyProvider);
    const opening = 0.0;
    final closing = ref.watch(historyClosingBalanceProvider);
    final got = ref.watch(historyYouGotProvider);
    final gave = ref.watch(historyYouGaveProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                _BalanceRow(
                  label: strings.openingBalance,
                  amount: opening,
                  currencyCode: currencyCode,
                  bold: false,
                ),
                const SizedBox(height: 10),
                _BalanceRow(
                  label: strings.closingBalance,
                  amount: closing,
                  currencyCode: currencyCode,
                  bold: true,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              children: [
                _BalanceRow(
                  label: strings.youGot,
                  amount: got,
                  currencyCode: currencyCode,
                  valueColor: AppColors.success,
                ),
                const SizedBox(height: 10),
                _BalanceRow(
                  label: strings.youGave,
                  amount: gave,
                  currencyCode: currencyCode,
                  valueColor: AppColors.expense,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.label,
    required this.amount,
    required this.currencyCode,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final double amount;
  final String currencyCode;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? AppColors.textPrimary;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          CurrencyFormatter.format(amount.abs(), currencyCode: currencyCode),
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            fontSize: bold ? 16 : 15,
            color: color,
          ),
        ),
      ],
    );
  }
}
