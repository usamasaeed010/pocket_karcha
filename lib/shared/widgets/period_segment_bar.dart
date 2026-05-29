import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';

class PeriodSegmentBar extends StatelessWidget {
  const PeriodSegmentBar({
    super.key,
    required this.period,
    required this.strings,
    required this.onChanged,
  });

  final DashboardPeriod period;
  final AppStrings strings;
  final ValueChanged<DashboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: DashboardPeriod.values.map((p) {
          final selected = period == p;
          return Expanded(
            child: _Segment(
              label: _label(strings, p),
              selected: selected,
              onTap: () => onChanged(p),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(AppStrings s, DashboardPeriod p) {
    switch (p) {
      case DashboardPeriod.day:
        return s.day;
      case DashboardPeriod.week:
        return s.week;
      case DashboardPeriod.month:
        return s.month;
    }
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.dashboardGreen : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
