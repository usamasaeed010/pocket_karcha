import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/presentation/add_expense_screen.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_selector.dart';
import 'package:pocket_karcha/features/expenses/widgets/expense_list_tile.dart';
import 'package:pocket_karcha/features/home/widgets/finance_summary_card.dart';
import 'package:pocket_karcha/features/home/widgets/recent_transaction_tile.dart';
import 'package:pocket_karcha/features/shell/widgets/add_transaction_sheet.dart';
import 'package:pocket_karcha/shared/widgets/animated_list_item.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/empty_state_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final period = ref.watch(dashboardPeriodProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);
    final recent = ref.watch(dashboardRecentExpensesProvider);
    final currencyCode = ref.watch(selectedCurrencyProvider);
    final showInitialLoader =
        expensesAsync.isLoading && !expensesAsync.hasValue;

    return ColoredBox(
      color: AppColors.dashboardSurface,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(expensesStreamProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            FinanceSummaryCard(strings: s),
            const SizedBox(height: AppSpacing.lg),
            TransactionTypeQuickActions(
              strings: s,
              onGave: () => _openAdd(context, TransactionType.gave),
              onGot: () => _openAdd(context, TransactionType.got),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    s.recentTransactions,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const Spacer(),
                  if (recent.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          ref.read(mainTabIndexProvider.notifier).state = 1,
                      child: Text(
                        s.viewAll,
                        style: const TextStyle(
                          color: AppColors.navActive,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (expensesAsync.hasError && !expensesAsync.hasValue)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${expensesAsync.error}'),
              )
            else if (showInitialLoader)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (recent.isEmpty)
              EmptyStateCard(
                icon: Icons.receipt_long_outlined,
                title: s.noExpenses,
                subtitle: s.periodEmptyHint(period),
                actionLabel: s.add,
                onAction: () => showAddTransactionSheet(context, strings: s),
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < recent.length; i++) ...[
                      AnimatedListItem(
                        index: i,
                        child: RecentTransactionTile(
                          expense: recent[i],
                          currencyCode: currencyCode,
                          onTap: recent[i].hasReceipt
                              ? () => showReceiptDialog(
                                    context,
                                    recent[i].receiptUrl!,
                                    s,
                                  )
                              : null,
                        ),
                      ),
                      if (i < recent.length - 1)
                        const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Color(0xFFF1F5F9),
                        ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _openAdd(BuildContext context, TransactionType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddExpenseScreen(initialType: type),
      ),
    );
  }
}
