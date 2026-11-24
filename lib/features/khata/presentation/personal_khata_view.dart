import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/money.dart';
import 'package:pocket_karcha/core/utils/time_ago.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/features/khata/entry_status.dart';
import 'package:pocket_karcha/features/khata/personal_categories.dart';
import 'package:pocket_karcha/features/khata/widgets/entry_editor_sheet.dart';
import 'package:pocket_karcha/features/khata/widgets/khata_widgets.dart';
import 'package:pocket_karcha/providers/khata_providers.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Personal book: home and personal spending, kept apart from the shop.
/// Month by month, with an optional budget and a category breakdown.
class PersonalKhataView extends ConsumerWidget {
  const PersonalKhataView({super.key});

  void _add(BuildContext context) {
    showEntryEditor(context, book: EntryBook.personal);
  }

  void _shiftMonth(WidgetRef ref, int by) {
    final m = ref.read(personalMonthProvider);
    ref.read(personalMonthProvider.notifier).state =
        DateTime(m.year, m.month + by);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final all = ref.watch(personalEntriesProvider);
    final month = ref.watch(personalMonthProvider);
    final entries = ref.watch(personalMonthEntriesProvider);
    final total = ref.watch(personalMonthTotalProvider);
    final byCategory = ref.watch(personalCategoryTotalsProvider);
    final budget = ref.watch(personalBudgetProvider);
    final pending = ref.watch(personalPendingProvider);
    final money = ref.watch(moneyProvider);
    final urdu = ss.isUrdu;
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;

    if (all.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: KhataAddButton(
          label: ss.addPersonalExpense,
          onTap: () => _add(context),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            EmptyHint(
              icon: Icons.account_balance_wallet_outlined,
              title: ss.noPersonalTitle,
              body: ss.noPersonalBody,
              action: FilledButton.icon(
                onPressed: () => _add(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(ss.addPersonalExpense),
              ),
            ),
          ],
        ),
      );
    }

    // Entries grouped by day (already newest first).
    final days = <DateTime, List<ExpenseModel>>{};
    for (final e in entries) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      days.putIfAbsent(d, () => []).add(e);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: KhataAddButton(
        label: ss.addPersonalExpense,
        onTap: () => _add(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          MonthSwitcher(
            month: month,
            onPrev: () => _shiftMonth(ref, -1),
            onNext: isCurrentMonth ? null : () => _shiftMonth(ref, 1),
          ),
          _SpentCard(
            total: total,
            budget: budget,
            money: money,
            ss: ss,
            onBudget: () => _showBudgetSheet(context),
          ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 18),
            CapsLabel(
              ss.pendingTitle,
              trailing: Text(
                money(pending.fold<double>(0, (s, e) => s + e.amount)),
                style: const TextStyle(
                  color: pendingColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            KhataEntryCard(
              children: [
                for (final e in pending)
                  _PersonalEntryTile(
                    entry: e,
                    urdu: urdu,
                    money: money,
                    pendingLabel: ss.statusPending,
                    showDate: true,
                    trailing: MarkPaidButton(
                      tooltip: ss.markPaid,
                      onTap: () => markEntryPaid(ref, e),
                    ),
                    onTap: () => showEntryEditor(
                      context,
                      book: EntryBook.personal,
                      existing: e,
                    ),
                  ),
              ],
            ),
          ],
          if (byCategory.isNotEmpty) ...[
            const SizedBox(height: 18),
            CapsLabel(ss.byCategory),
            const SizedBox(height: 8),
            CreamCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Column(
                children: [
                  for (final c in byCategory)
                    _CategoryRow(
                      category: PersonalCategories.byId(c.categoryId),
                      amount: c.amount,
                      share: total <= 0 ? 0 : c.amount / total,
                      urdu: urdu,
                      money: money,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          CapsLabel(ss.entriesLabel),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            CreamCard(
              child: Text(
                ss.noEntriesThisMonth,
                style: const TextStyle(color: AppColors.inkSoft),
              ),
            )
          else
            for (final day in days.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                child: Row(
                  children: [
                    Text(
                      TimeAgo.dayLabel(day.key, urdu: urdu),
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      money(day.value.fold<double>(0, (s, e) => s + e.amount)),
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              KhataEntryCard(
                children: [
                  for (final e in day.value)
                    _PersonalEntryTile(
                      entry: e,
                      urdu: urdu,
                      money: money,
                      pendingLabel: ss.statusPending,
                      onTap: () => showEntryEditor(
                        context,
                        book: EntryBook.personal,
                        existing: e,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

Future<void> _showBudgetSheet(BuildContext context) {
  return showCreamSheet<void>(
    context,
    builder: (_) => const _BudgetSheet(),
  );
}

class _SpentCard extends StatelessWidget {
  const _SpentCard({
    required this.total,
    required this.budget,
    required this.money,
    required this.ss,
    required this.onBudget,
  });

  final double total;
  final double budget;
  final String Function(num) money;
  final StoreStrings ss;
  final VoidCallback onBudget;

  @override
  Widget build(BuildContext context) {
    final hasBudget = budget > 0;
    final ratio = hasBudget ? (total / budget) : 0.0;
    final over = hasBudget && total > budget;
    final barColor = over
        ? AppColors.danger
        : (ratio >= 0.8 ? AppColors.pending : AppColors.brand);

    return CreamCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CapsLabel(ss.spent),
          const SizedBox(height: 4),
          Text(money(total), style: AppFonts.display(size: 30)),
          if (hasBudget) ...[
            const SizedBox(height: 2),
            Text(
              ss.ofBudget(money(budget)),
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.creamDeep,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    over
                        ? ss.overBy(money(total - budget))
                        : ss.moneyLeft(money(budget - total)),
                    style: TextStyle(
                      color: over ? AppColors.danger : AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onBudget,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(ss.edit),
                ),
              ],
            ),
          ] else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onBudget,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: Text(ss.setBudget),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.share,
    required this.urdu,
    required this.money,
  });

  final PersonalCategory category;
  final double amount;
  final double share;
  final bool urdu;
  final String Function(num) money;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(category.icon, size: 18, color: category.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.label(urdu),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      money(amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: AppColors.creamDeep,
                    valueColor: AlwaysStoppedAnimation(category.color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalEntryTile extends StatelessWidget {
  const _PersonalEntryTile({
    required this.entry,
    required this.urdu,
    required this.money,
    required this.pendingLabel,
    required this.onTap,
    this.showDate = false,
    this.trailing,
  });

  final ExpenseModel entry;
  final bool urdu;
  final String Function(num) money;
  final String pendingLabel;
  final VoidCallback onTap;

  /// Adds the day to the subtitle (rows outside the day groups).
  final bool showDate;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cat = PersonalCategories.byId(entry.categoryId);
    final subtitle = entry.note.isNotEmpty
        ? cat.label(urdu)
        : TimeAgo.dayAndTime(entry.date, urdu: urdu);
    return KhataEntryTile(
      icon: cat.icon,
      iconColor: cat.color,
      title: entry.note.isNotEmpty ? entry.note : cat.label(urdu),
      subtitle: showDate && entry.note.isNotEmpty
          ? '$subtitle · ${TimeAgo.dayLabel(entry.date, urdu: urdu)}'
          : subtitle,
      amount: money(entry.amount),
      amountColor: entry.isPending ? pendingColor : AppColors.ink,
      tag: entry.isPending && trailing == null ? pendingLabel : null,
      tagColor: pendingColor,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _BudgetSheet extends ConsumerStatefulWidget {
  const _BudgetSheet();

  @override
  ConsumerState<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<_BudgetSheet> {
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    final current = ref.read(personalBudgetProvider);
    _amount = TextEditingController(
      text: current > 0 ? formatPlainNumber(current) : '',
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save(double value) {
    unawaited(ref.read(personalBudgetProvider.notifier).set(value));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final hasBudget = ref.watch(personalBudgetProvider) > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ss.budgetTitle, style: AppFonts.display(size: 20)),
          const SizedBox(height: 6),
          Text(
            ss.budgetHint,
            style: const TextStyle(color: AppColors.inkSoft, height: 1.35),
          ),
          const SizedBox(height: 14),
          MoneyInput(controller: _amount, symbol: symbol, autofocus: true),
          const SizedBox(height: 16),
          Row(
            children: [
              if (hasBudget) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _save(0),
                    child: Text(ss.removeBudget),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final v = parseAmount(_amount.text) ?? 0;
                    _save(v);
                  },
                  child: Text(ss.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
