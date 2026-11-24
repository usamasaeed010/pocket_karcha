import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/presentation/add_expense_screen.dart';
// import 'package:pocket_karcha/features/expenses/widgets/expense_list_tile.dart'; // receipts disabled
import 'package:pocket_karcha/features/expenses/widgets/transaction_options_sheet.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_selector.dart';
import 'package:pocket_karcha/features/home/widgets/budget_card.dart';
import 'package:pocket_karcha/features/home/widgets/finance_summary_card.dart';
import 'package:pocket_karcha/features/home/widgets/recent_transaction_tile.dart';
import 'package:pocket_karcha/features/shell/widgets/add_transaction_sheet.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/animated_list_item.dart';
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
          ref.invalidate(allEntriesStreamProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            AnimatedListItem(index: 0, child: FinanceSummaryCard(strings: s)),
            const SizedBox(height: 22),
            _SectionTitle(title: s.quickAdd),
            const SizedBox(height: 10),
            AnimatedListItem(
              index: 1,
              child: TransactionTypeQuickActions(
                strings: s,
                onSelected: (type) => _openAdd(context, type),
              ),
            ),
            const SizedBox(height: 22),
            AnimatedListItem(index: 2, child: BudgetCard(strings: s)),
            const SizedBox(height: 22),
            _SectionTitle(
              title: s.recentTransactions,
              action: recent.isEmpty ? null : s.viewAll,
              onAction: () => ref.read(mainTabIndexProvider.notifier).state =
                  ShellTabs.history,
            ),
            const SizedBox(height: 8),
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
                icon: Icons.storefront_rounded,
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
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < recent.length; i++) ...[
                      AnimatedListItem(
                        index: i + 3,
                        child: RecentTransactionTile(
                          expense: recent[i],
                          currencyCode: currencyCode,
                          onOptions: () =>
                              showTransactionOptions(context, ref, recent[i]),
                          // Image attachments are disabled for now.
                          // onTap: recent[i].hasReceipt
                          //     ? () => showReceiptDialog(
                          //           context,
                          //           recent[i].receiptUrl!,
                          //           s,
                          //         )
                          //     : null,
                        ),
                      ),
                      if (i < recent.length - 1)
                        const Divider(
                          height: 1,
                          indent: 72,
                          endIndent: 16,
                          color: AppColors.divider,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                action!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
