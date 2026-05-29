import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/data/models/expense_suggestion.dart';

class SuggestionChipRow extends StatelessWidget {
  const SuggestionChipRow({
    super.key,
    required this.suggestions,
    required this.urdu,
    required this.onTap,
  });

  final List<ExpenseSuggestion> suggestions;
  final bool urdu;
  final void Function(ExpenseSuggestion) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final s = suggestions[index];
          return ActionChip(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            label: Text(
              '${s.title(urdu)} · ${CurrencyFormatter.format(s.amount)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            onPressed: () => onTap(s),
          );
        },
      ),
    );
  }
}
