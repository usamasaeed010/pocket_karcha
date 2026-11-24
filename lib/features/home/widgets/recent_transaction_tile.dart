import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_list_tile.dart';

/// Home recent transactions — uses shared [TransactionListTile].
class RecentTransactionTile extends ConsumerWidget {
  const RecentTransactionTile({
    super.key,
    required this.expense,
    required this.currencyCode,
    this.onOptions,
    // Image attachments are disabled for now (tap used to open the receipt).
    // this.onTap,
  });

  final ExpenseModel expense;
  final String currencyCode;
  final VoidCallback? onOptions;
  // final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TransactionListTile(
      expense: expense,
      currencyCode: currencyCode,
      // onViewReceipt: onTap, // Image attachments are disabled for now.
      onOptions: onOptions,
    );
  }
}
