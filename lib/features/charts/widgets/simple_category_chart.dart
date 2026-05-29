import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/providers/chart_provider.dart';

class SimpleCategoryChart extends StatelessWidget {
  const SimpleCategoryChart({
    super.key,
    required this.slices,
    required this.title,
    this.currencyCode = 'PKR',
  });

  final List<CategorySlice> slices;
  final String title;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    final total = slices.fold<double>(0, (s, e) => s + e.total);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: slices.map((slice) {
                    final pct = slice.total / total * 100;
                    return PieChartSectionData(
                      value: slice.total,
                      title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                      color: slice.color,
                      radius: 52,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...slices.take(4).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: s.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s.label)),
                        Text(CurrencyFormatter.format(
                          s.total,
                          currencyCode: currencyCode,
                        )),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
