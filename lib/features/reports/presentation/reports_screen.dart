import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/stock_units.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_theme.dart';
import 'package:pocket_karcha/features/shell/widgets/add_transaction_sheet.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/providers/reports_provider.dart';
import 'package:pocket_karcha/shared/widgets/animated_list_item.dart';
import 'package:pocket_karcha/shared/widgets/empty_state_card.dart';

/// Monthly profit & loss: summary, 6-month trend, category split, top items.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final summary = ref.watch(reportSummaryProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    var index = 0;
    Widget anim(Widget child) => AnimatedListItem(index: index++, child: child);

    final purchaseShares =
        ref.watch(reportCategoryBreakdownProvider(ExpenseRecordType.purchase));
    final expenseShares =
        ref.watch(reportCategoryBreakdownProvider(ExpenseRecordType.expense));
    final saleShares =
        ref.watch(reportCategoryBreakdownProvider(ExpenseRecordType.income));
    final topBought =
        ref.watch(reportTopItemsProvider(ExpenseRecordType.purchase));
    final topSold = ref.watch(reportTopItemsProvider(ExpenseRecordType.income));

    return ColoredBox(
      color: AppColors.dashboardSurface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
        children: [
          anim(const _MonthSwitcher()),
          const SizedBox(height: 12),
          anim(_SummaryCard(summary: summary, strings: s, currency: currency)),
          const SizedBox(height: 16),
          if (summary.isEmpty)
            anim(
              EmptyStateCard(
                icon: Icons.insights_rounded,
                title: s.noDataForMonth,
                subtitle: s.noDataForMonthHint,
                actionLabel: s.add,
                onAction: () => showAddTransactionSheet(context, strings: s),
              ),
            )
          else ...[
            anim(_TrendCard(strings: s, currency: currency)),
            if (purchaseShares.isNotEmpty) ...[
              const SizedBox(height: 16),
              anim(
                _BreakdownCard(
                  title: s.stockByCategory,
                  look: lookFor(TransactionType.purchase, s),
                  shares: purchaseShares,
                  currency: currency,
                ),
              ),
            ],
            if (topBought.isNotEmpty) ...[
              const SizedBox(height: 16),
              anim(
                _TopItemsCard(
                  title: s.topPurchasedItems,
                  look: lookFor(TransactionType.purchase, s),
                  items: topBought,
                  currency: currency,
                ),
              ),
            ],
            if (expenseShares.isNotEmpty) ...[
              const SizedBox(height: 16),
              anim(
                _BreakdownCard(
                  title: s.expensesByCategory,
                  look: lookFor(TransactionType.gave, s),
                  shares: expenseShares,
                  currency: currency,
                ),
              ),
            ],
            if (saleShares.isNotEmpty) ...[
              const SizedBox(height: 16),
              anim(
                _BreakdownCard(
                  title: s.salesByCategory,
                  look: lookFor(TransactionType.got, s),
                  shares: saleShares,
                  currency: currency,
                ),
              ),
            ],
            if (topSold.isNotEmpty) ...[
              const SizedBox(height: 16),
              anim(
                _TopItemsCard(
                  title: s.topSoldItems,
                  look: lookFor(TransactionType.got, s),
                  items: topSold,
                  currency: currency,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Month switcher ─────────────────────────────────────────────────────────

class _MonthSwitcher extends ConsumerWidget {
  const _MonthSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(reportMonthProvider);
    final urdu = ref.watch(localeUrduProvider);
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    final label = DateFormat('MMMM yyyy').format(month);

    void shift(int delta) {
      ref.read(reportMonthProvider.notifier).state =
          DateTime(month.year, month.month + delta);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _RoundIcon(
              icon: urdu
                  ? Icons.chevron_right_rounded
                  : Icons.chevron_left_rounded,
              onTap: () => shift(-1),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            _RoundIcon(
              icon: urdu
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              onTap: isCurrent ? null : () => shift(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? AppColors.primary.withValues(alpha: 0.08)
          : const Color(0xFFF8FAFC),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: enabled ? AppColors.primary : AppColors.navInactive,
          ),
        ),
      ),
    );
  }
}

// ── Summary ────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.strings,
    required this.currency,
  });

  final MonthSummary summary;
  final AppStrings strings;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    String fmt(double v) => CurrencyFormatter.format(v, currencyCode: currency);
    final colors =
        summary.isLoss ? AppColors.lossGradient : AppColors.heroGradient;
    final margin = summary.marginPercent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      summary.isLoss ? s.netLoss : s.netProfit,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    if (margin != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s.marginLabel(margin.toStringAsFixed(0)),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${summary.isLoss ? '-' : ''}${fmt(summary.profit.abs())}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.entriesCount(summary.count),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        look: lookFor(TransactionType.got, s),
                        label: s.youGot,
                        value: fmt(summary.sales),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        look: lookFor(TransactionType.purchase, s),
                        label: s.purchase,
                        value: fmt(summary.purchases),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        look: lookFor(TransactionType.gave, s),
                        label: s.youGave,
                        value: fmt(summary.expenses),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        icon: Icons.today_rounded,
                        color: AppColors.primary,
                        surface: const Color(0xFFF0FDFA),
                        label: s.avgDailySales,
                        value: fmt(summary.avgDailySales),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.look,
    this.icon,
    this.color,
    this.surface,
  });

  final String label;
  final String value;
  final TransactionTypeLook? look;
  final IconData? icon;
  final Color? color;
  final Color? surface;

  @override
  Widget build(BuildContext context) {
    final c = look?.color ?? color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: look?.surface ?? surface ?? const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(look?.icon ?? icon, size: 20, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: c,
                    ),
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

// ── 6-month trend ──────────────────────────────────────────────────────────

class _TrendCard extends ConsumerWidget {
  const _TrendCard({required this.strings, required this.currency});

  final AppStrings strings;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final trend = ref.watch(reportTrendProvider);
    final maxValue = trend.fold<double>(
      0,
      (m, t) => math.max(m, math.max(t.sales, t.spending)),
    );
    // Round axis steps (50, 100, 1K…) instead of odd values like 34.5.
    final step = maxValue <= 0 ? 25.0 : _niceStep(maxValue / 4);
    final top =
        maxValue <= 0 ? 100.0 : ((maxValue * 1.05) / step).ceil() * step;

    return _Card(
      title: s.last6Months,
      icon: Icons.bar_chart_rounded,
      child: Column(
        children: [
          Row(
            children: [
              _Legend(color: AppColors.sale, label: s.youGot),
              const SizedBox(width: 14),
              _Legend(color: AppColors.expense, label: s.spending),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                maxY: top,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: step,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: step,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value >= top) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          NumberFormat.compact().format(value),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= trend.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('MMM').format(trend[i].month),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == trend.length - 1
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: i == trend.length - 1
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final t = trend[group.x];
                      final label = rodIndex == 0 ? s.youGot : s.spending;
                      final value = rodIndex == 0 ? t.sales : t.spending;
                      return BarTooltipItem(
                        '$label\n${CurrencyFormatter.format(value, currencyCode: currency)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < trend.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: trend[i].sales,
                          width: 10,
                          color: AppColors.sale,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: trend[i].spending,
                          width: 10,
                          color: AppColors.expense,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          for (final t in trend.reversed.take(3))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      DateFormat('MMM yyyy').format(t.month),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t.isEmpty ? '—' : s.profitOrLoss(t.profit),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    t.isEmpty
                        ? '—'
                        : '${t.isLoss ? '-' : '+'}${CurrencyFormatter.format(t.profit.abs(), currencyCode: currency)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: t.isEmpty
                          ? AppColors.textSecondary
                          : t.isLoss
                              ? AppColors.expense
                              : AppColors.sale,
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

/// Rounds a raw axis step up to 1, 2, 2.5 or 5 × 10ⁿ so labels read cleanly.
double _niceStep(double raw) {
  if (raw <= 0) return 1;
  final magnitude =
      math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  for (final m in const [1.0, 2.0, 2.5, 5.0]) {
    if (m * magnitude >= raw) return m * magnitude;
  }
  return 10 * magnitude;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Category breakdown ─────────────────────────────────────────────────────

class _BreakdownCard extends ConsumerWidget {
  const _BreakdownCard({
    required this.title,
    required this.look,
    required this.shares,
    required this.currency,
  });

  final String title;
  final TransactionTypeLook look;
  final List<CategoryShare> shares;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urdu = ref.watch(localeUrduProvider);
    final total = shares.fold<double>(0, (t, e) => t + e.amount);

    return _Card(
      title: title,
      icon: look.icon,
      iconColor: look.color,
      trailing: Text(
        CurrencyFormatter.format(total, currencyCode: currency),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: look.color,
        ),
      ),
      child: Column(
        children: [
          for (final share in shares.take(8))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: share.category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      share.category.icon,
                      size: 19,
                      color: share.category.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                share.category.label(urdu),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                share.amount,
                                currencyCode: currency,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: share.fraction.clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  color: share.category.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 38,
                              child: Text(
                                '${(share.fraction * 100).round()}%',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
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
        ],
      ),
    );
  }
}

// ── Top items ──────────────────────────────────────────────────────────────

class _TopItemsCard extends ConsumerWidget {
  const _TopItemsCard({
    required this.title,
    required this.look,
    required this.items,
    required this.currency,
  });

  final String title;
  final TransactionTypeLook look;
  final List<ItemStat> items;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final urdu = ref.watch(localeUrduProvider);

    return _Card(
      title: title,
      icon: Icons.inventory_2_rounded,
      iconColor: look.color,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: look.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: look.border),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: look.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _detail(items[i], s, urdu),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.format(
                      items[i].amount,
                      currencyCode: currency,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: look.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _detail(ItemStat item, AppStrings s, bool urdu) {
    final parts = <String>[];
    if (item.quantity > 0) {
      final unit = StockUnits.byKey(item.unit);
      parts.add('${StockUnits.formatQty(item.quantity)} ${unit.short(urdu)}');
      final rate = item.avgRate;
      if (rate != null) {
        parts.add(
          s.avgRate(
            CurrencyFormatter.format(rate, currencyCode: currency),
            unit.short(urdu),
          ),
        );
      }
    }
    parts.add(s.timesCount(item.count));
    return parts.join('  ·  ');
  }
}

// ── Shared card shell ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.child,
    this.icon,
    this.iconColor,
    this.trailing,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
