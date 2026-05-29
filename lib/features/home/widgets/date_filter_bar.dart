import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';

class DateFilterBar extends ConsumerWidget {
  const DateFilterBar({super.key, required this.strings});

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
            child: _FilterChipBox(
              icon: Icons.calendar_today_rounded,
              label: dateLabel,
            ),
          ),
          const SizedBox(width: 12),
          _PeriodDropdown(
            period: period,
            strings: strings,
            onChanged: (p) =>
                ref.read(dashboardPeriodProvider.notifier).state = p,
          ),
        ],
      ),
    );
  }
}

class _FilterChipBox extends StatelessWidget {
  const _FilterChipBox({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({
    required this.period,
    required this.strings,
    required this.onChanged,
  });

  final DashboardPeriod period;
  final AppStrings strings;
  final ValueChanged<DashboardPeriod> onChanged;

  String _label(DashboardPeriod p) {
    switch (p) {
      case DashboardPeriod.day:
        return strings.day;
      case DashboardPeriod.week:
        return strings.week;
      case DashboardPeriod.month:
        return strings.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DashboardPeriod>(
          value: period,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          items: DashboardPeriod.values
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(
                    _label(p),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
