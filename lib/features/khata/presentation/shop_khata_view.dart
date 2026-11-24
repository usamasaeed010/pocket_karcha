import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/time_ago.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/presentation/add_expense_screen.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_options_sheet.dart';
import 'package:pocket_karcha/features/khata/entry_status.dart';
import 'package:pocket_karcha/features/khata/widgets/khata_widgets.dart';
import 'package:pocket_karcha/features/shell/presentation/main_shell_screen.dart';
import 'package:pocket_karcha/features/voice/voice_entry_sheet.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';
import 'package:pocket_karcha/providers/khata_providers.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Colour for a shop entry: sale green, purchase amber, expense red.
Color shopEntryColor(ExpenseRecordType type) => switch (type) {
      ExpenseRecordType.income => AppColors.sale,
      ExpenseRecordType.purchase => AppColors.purchase,
      ExpenseRecordType.expense => AppColors.expense,
    };

/// Shop book: this month's sales, purchases, expenses and profit, quick add
/// buttons and the latest entries. The full khata (reports, budget, history)
/// opens from here.
class ShopKhataView extends ConsumerWidget {
  const ShopKhataView({super.key});

  void _add(BuildContext context, TransactionType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddExpenseScreen(initialType: type),
      ),
    );
  }

  void _openFullKhata(BuildContext context, WidgetRef ref, int tab) {
    ref.read(mainTabIndexProvider.notifier).state = tab;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MainShellScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);
    final month = ref.watch(shopMonthSummaryProvider);
    final recent = ref.watch(recentShopEntriesProvider);
    final pending = ref.watch(shopPendingProvider);
    final urdu = ss.isUrdu;
    final profit = month.profit;
    final loss = profit < 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        CreamCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CapsLabel(
                ss.thisMonth,
                trailing: SoftChip(
                  label: loss ? ss.khLoss : ss.khProfit,
                  background: loss ? AppColors.dangerSoft : AppColors.brandSoft,
                  foreground: loss ? AppColors.danger : AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                money(profit.abs()),
                style: AppFonts.display(
                  size: 30,
                  color: loss ? AppColors.danger : AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MonthStat(
                    label: ss.khSales,
                    value: money(month.sales),
                    color: AppColors.sale,
                  ),
                  _MonthStat(
                    label: ss.khPurchases,
                    value: money(month.purchases),
                    color: AppColors.purchase,
                  ),
                  _MonthStat(
                    label: ss.khExpenses,
                    value: money(month.expenses),
                    color: AppColors.expense,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAdd(
              label: ss.khAddSale,
              icon: Icons.south_west_rounded,
              color: AppColors.sale,
              onTap: () => _add(context, TransactionType.got),
            ),
            const SizedBox(width: 8),
            _QuickAdd(
              label: ss.khAddPurchase,
              icon: Icons.inventory_2_outlined,
              color: AppColors.purchase,
              onTap: () => _add(context, TransactionType.purchase),
            ),
            const SizedBox(width: 8),
            _QuickAdd(
              label: ss.khAddExpense,
              icon: Icons.north_east_rounded,
              color: AppColors.expense,
              onTap: () => _add(context, TransactionType.gave),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const VoiceEntryBar(),
        if (!pending.isEmpty) ...[
          const SizedBox(height: 20),
          CapsLabel(ss.pendingTitle),
          const SizedBox(height: 8),
          Row(
            children: [
              _PendingTotal(
                label: ss.toCollect,
                value: money(pending.toCollect),
                color: AppColors.sale,
              ),
              const SizedBox(width: 8),
              _PendingTotal(
                label: ss.toPayLabel,
                value: money(pending.toPay),
                color: AppColors.expense,
              ),
            ],
          ),
          const SizedBox(height: 8),
          KhataEntryCard(
            children: [
              for (final e in pending.entries)
                _ShopEntryTile(
                  entry: e,
                  urdu: urdu,
                  money: money,
                  ss: ss,
                  onTap: () => showTransactionOptions(context, ref, e),
                  onMarkPaid: () => markEntryPaid(ref, e),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        CreamCard(
          onTap: () => _openFullKhata(context, ref, ShellTabs.home),
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.brandDark,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ss.fullKhata,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ss.fullKhataSub,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkFaint,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CapsLabel(
          ss.recentEntries,
          trailing: recent.isEmpty
              ? null
              : TextButton(
                  onPressed: () =>
                      _openFullKhata(context, ref, ShellTabs.history),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(ss.seeAll),
                ),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          CreamCard(
            child: Text(
              ss.noShopEntries,
              style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
            ),
          )
        else
          KhataEntryCard(
            children: [
              for (final e in recent)
                _ShopEntryTile(
                  entry: e,
                  urdu: urdu,
                  money: money,
                  ss: ss,
                  onTap: () => showTransactionOptions(context, ref, e),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: AppColors.inkFaint,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                ss.ordersNotInKhata,
                style: const TextStyle(color: AppColors.inkFaint, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthStat extends StatelessWidget {
  const _MonthStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAdd extends StatelessWidget {
  const _QuickAdd({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.09),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withValues(alpha: 0.28)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 4),
                Text(
                  '+ $label',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingTotal extends StatelessWidget {
  const _PendingTotal({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CreamCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopEntryTile extends ConsumerWidget {
  const _ShopEntryTile({
    required this.entry,
    required this.urdu,
    required this.money,
    required this.ss,
    required this.onTap,
    this.onMarkPaid,
  });

  final ExpenseModel entry;
  final bool urdu;
  final String Function(num) money;
  final StoreStrings ss;
  final VoidCallback onTap;

  /// Shows a ✓ button on pending entries.
  final VoidCallback? onMarkPaid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = ref.watch(categoryByIdProvider(entry.categoryId));
    final color = shopEntryColor(entry.type);
    return KhataEntryTile(
      icon: cat.icon,
      iconColor: color,
      title: entry.hasItemName ? entry.itemName! : cat.label(urdu),
      subtitle: [
        TimeAgo.dayLabel(entry.date, urdu: urdu),
        if (entry.note.isNotEmpty) entry.note,
      ].join(' · '),
      amount: '${entry.isIncome ? '+' : '−'}${money(entry.amount)}',
      amountColor: color,
      tag: entry.isPending ? ss.statusPending : null,
      tagColor: pendingColor,
      trailing: onMarkPaid == null
          ? null
          : MarkPaidButton(tooltip: ss.markPaid, onTap: onMarkPaid!),
      onTap: onTap,
    );
  }
}
