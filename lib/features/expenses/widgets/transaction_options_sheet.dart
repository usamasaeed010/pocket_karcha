import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/features/expenses/presentation/add_expense_screen.dart';
import 'package:pocket_karcha/features/khata/entry_status.dart';
// import 'package:pocket_karcha/features/expenses/widgets/expense_list_tile.dart'; // receipts disabled
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_bottom_sheet.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/confirmation_bottom_sheet.dart';

enum _TransactionAction { markPaid, edit, /* viewReceipt, */ delete }

Future<void> showTransactionOptions(
  BuildContext context,
  WidgetRef ref,
  ExpenseModel expense,
) async {
  final s = ref.read(appStringsProvider);
  final ss = ref.read(storeStringsProvider);
  final action = await showAppOptionsBottomSheet<_TransactionAction>(
    context: context,
    title: s.transactionOptions,
    subtitle: expense.hasItemName
        ? expense.itemName!
        : (expense.note.isNotEmpty ? expense.note : s.transaction),
    options: [
      if (expense.isPending)
        AppBottomSheetOption(
          value: _TransactionAction.markPaid,
          label: ss.markPaid,
          leading: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.brand,
          ),
        ),
      AppBottomSheetOption(
        value: _TransactionAction.edit,
        label: s.editTransaction,
        leading: const Icon(Icons.edit_outlined, color: AppColors.navActive),
      ),
      // Image attachments are disabled for now.
      // if (expense.hasReceipt)
      //   AppBottomSheetOption(
      //     value: _TransactionAction.viewReceipt,
      //     label: s.viewReceipt,
      //     leading: const Icon(Icons.receipt_long_outlined,
      //         color: AppColors.dashboardGreen),
      //   ),
      AppBottomSheetOption(
        value: _TransactionAction.delete,
        label: s.deleteTransaction,
        leading: const Icon(Icons.delete_outline_rounded,
            color: AppColors.expense),
      ),
    ],
  );

  if (!context.mounted || action == null) return;

  switch (action) {
    case _TransactionAction.markPaid:
      markEntryPaid(ref, expense);
    case _TransactionAction.edit:
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AddExpenseScreen(editExpense: expense),
        ),
      );
    // Image attachments are disabled for now.
    // case _TransactionAction.viewReceipt:
    //   if (expense.receiptUrl != null) {
    //     showReceiptDialog(context, expense.receiptUrl!, s);
    //   }
    case _TransactionAction.delete:
      await _confirmDelete(context, ref, expense, s);
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  ExpenseModel expense,
  AppStrings s,
) async {
  final confirmed = await showConfirmationBottomSheet(
    context,
    title: s.deleteTransaction,
    subtitle: s.deleteTransactionConfirm,
    message: s.deleteTransactionWarning,
    confirmLabel: s.deleteTransaction,
    cancelLabel: s.cancel,
    confirmColor: AppColors.expense,
    icon: Icons.delete_outline_rounded,
    iconColor: AppColors.expense,
    messageBackground: const Color(0xFFFEF2F2),
    messageBorder: const Color(0xFFFECACA),
  );

  if (confirmed != true || !context.mounted) return;

  // Firestore removes it on the phone at once (even offline) and syncs later.
  unawaited(
    ref.read(expenseActionsProvider).delete(expense.id).catchError((Object e) {
      showRootSnack(message: e.toString(), type: AppSnackType.error);
    }),
  );
  context.showSuccessSnack(s.snackTransactionDeleted);
}
