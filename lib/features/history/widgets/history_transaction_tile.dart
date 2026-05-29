import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_list_tile.dart';

/// History list row — uses shared [TransactionListTile] with type label.
class HistoryTransactionTile extends ConsumerWidget {
  const HistoryTransactionTile({
    super.key,
    required this.expense,
    required this.currencyCode,
    this.onTap,
  });

  final ExpenseModel expense;
  final String currencyCode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TransactionListTile(
      expense: expense,
      currencyCode: currencyCode,
      onViewReceipt: onTap,
      showTypeLabel: true,
    );
  }
}
