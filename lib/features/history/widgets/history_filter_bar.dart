import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';
import 'package:pocket_karcha/providers/history_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_bottom_sheet.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';

class HistoryFilterBar extends ConsumerWidget {
  const HistoryFilterBar({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(dashboardPeriodProvider);
    final dateLabel = DateFormat('d-MMM-yyyy').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _WhiteBox(
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _WhiteBox(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DashboardPeriod>(
                value: period,
                isDense: true,
                items: DashboardPeriod.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(_periodLabel(strings, p),
                            style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(dashboardPeriodProvider.notifier).state = v;
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          _IconBox(
            icon: Icons.sort_rounded,
            onTap: () => _showSortSheet(context, ref),
          ),
          const SizedBox(width: 8),
          _IconBox(
            icon: Icons.tune_rounded,
            onTap: () => context.showInfoSnack(strings.filters),
          ),
        ],
      ),
    );
  }

  String _periodLabel(AppStrings s, DashboardPeriod p) {
    switch (p) {
      case DashboardPeriod.day:
        return s.day;
      case DashboardPeriod.week:
        return s.week;
      case DashboardPeriod.month:
        return s.month;
    }
  }

  Future<void> _showSortSheet(BuildContext context, WidgetRef ref) async {
    final s = strings;
    final current = ref.read(historySortProvider);
    final picked = await showAppOptionsBottomSheet<HistorySort>(
      context: context,
      title: s.sortBy,
      options: HistorySort.values
          .map(
            (sort) => AppBottomSheetOption(
              value: sort,
              label: _sortLabel(s, sort),
              selected: current == sort,
            ),
          )
          .toList(),
    );
    if (picked != null) {
      ref.read(historySortProvider.notifier).state = picked;
    }
  }

  String _sortLabel(AppStrings s, HistorySort sort) {
    switch (sort) {
      case HistorySort.newest:
        return s.newestFirst;
      case HistorySort.oldest:
        return s.oldestFirst;
      case HistorySort.amountHigh:
        return s.amountHighToLow;
      case HistorySort.amountLow:
        return s.amountLowToHigh;
    }
  }
}

class _WhiteBox extends StatelessWidget {
  const _WhiteBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}
