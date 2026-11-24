import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
// import 'package:pocket_karcha/features/expenses/widgets/expense_list_tile.dart'; // receipts disabled
import 'package:pocket_karcha/features/expenses/widgets/transaction_options_sheet.dart';
import 'package:pocket_karcha/features/history/widgets/history_balance_card.dart';
import 'package:pocket_karcha/features/history/widgets/history_toolbar.dart';
import 'package:pocket_karcha/features/history/widgets/history_transaction_tile.dart';
import 'package:pocket_karcha/features/shell/widgets/add_transaction_sheet.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/history_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/animated_list_item.dart';
import 'package:pocket_karcha/shared/widgets/empty_state_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final period = ref.watch(dashboardPeriodProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);
    final groups = ref.watch(historyGroupedExpensesProvider);
    final currencyCode = ref.watch(selectedCurrencyProvider);
    final showInitialLoader =
        expensesAsync.isLoading && !expensesAsync.hasValue;

    return ColoredBox(
      color: AppColors.dashboardSurface,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allEntriesStreamProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                AnimatedListItem(
                  index: 0,
                  child: HistoryBalanceCard(strings: s),
                ),
                AnimatedListItem(
                  index: 1,
                  child: HistoryToolbar(strings: s),
                ),
                if (expensesAsync.hasError && !expensesAsync.hasValue)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('${expensesAsync.error}'),
                  )
                else if (groups.isEmpty && !showInitialLoader)
                  AnimatedListItem(
                    index: 2,
                    child: EmptyStateCard(
                      icon: Icons.history_rounded,
                      title: s.noExpenses,
                      subtitle: s.periodEmptyHint(period),
                      actionLabel: s.add,
                      onAction: () =>
                          showAddTransactionSheet(context, strings: s),
                    ),
                  )
                else if (!showInitialLoader)
                  ..._animatedHistoryGroups(
                    context: context,
                    ref: ref,
                    groups: groups,
                    startIndex: 2,
                    currencyCode: currencyCode,
                    strings: s,
                    // Image attachments are disabled for now.
                    // onReceipt: (expense) {
                    //   if (!expense.hasReceipt) return null;
                    //   return () => showReceiptDialog(
                    //         context,
                    //         expense.receiptUrl!,
                    //         s,
                    //       );
                    // },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (showInitialLoader)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

const _kMaxHistoryAnimations = 24;

List<Widget> _animatedHistoryGroups({
  required BuildContext context,
  required WidgetRef ref,
  required List<({String label, List<ExpenseModel> items})> groups,
  required int startIndex,
  required String currencyCode,
  required AppStrings strings,
  // required VoidCallback? Function(ExpenseModel expense) onReceipt,
}) {
  var animIndex = startIndex;
  final widgets = <Widget>[];

  Widget maybeAnim(int index, Widget child) {
    if (index >= _kMaxHistoryAnimations) return child;
    return AnimatedListItem(index: index, child: child);
  }

  for (final group in groups) {
    widgets.add(
      maybeAnim(
        animIndex++,
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
          child: Text(
            group.label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );

    widgets.add(
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
            for (var i = 0; i < group.items.length; i++) ...[
              maybeAnim(
                animIndex++,
                HistoryTransactionTile(
                  expense: group.items[i],
                  currencyCode: currencyCode,
                  onOptions: () => showTransactionOptions(
                    context,
                    ref,
                    group.items[i],
                  ),
                  // onTap: onReceipt(group.items[i]), // receipts disabled
                ),
              ),
              if (i < group.items.length - 1)
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
    );
  }

  return widgets;
}
