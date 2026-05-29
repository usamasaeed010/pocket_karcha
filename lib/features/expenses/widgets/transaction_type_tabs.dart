import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_selector.dart';

/// Segmented You Gave / You Got bar below Add Transaction app bar.
class TransactionTypeTabs extends StatelessWidget {
  const TransactionTypeTabs({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.strings,
  });

  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: TransactionTypeSelector(
        selected: selected,
        onChanged: onChanged,
        strings: strings,
        layout: TransactionTypeSelectorLayout.segmented,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      ),
    );
  }
}
