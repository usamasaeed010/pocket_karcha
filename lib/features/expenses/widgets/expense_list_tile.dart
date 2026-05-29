import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/core/utils/date_utils.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';

class ExpenseListTile extends ConsumerWidget {
  const ExpenseListTile({
    super.key,
    required this.expense,
    required this.onDelete,
    this.currencyCode = 'PKR',
    this.onViewReceipt,
  });

  final ExpenseModel expense;
  final String currencyCode;
  final VoidCallback onDelete;
  final VoidCallback? onViewReceipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urdu = ref.watch(localeUrduProvider);
    final s = ref.watch(appStringsProvider);
    final cat = ref.watch(categoryByIdProvider(expense.categoryId));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cat.color.withValues(alpha: 0.15),
          child: Icon(cat.icon, color: cat.color, size: 22),
        ),
        title: Text(
          expense.note.isNotEmpty ? expense.note : cat.label(urdu),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(AppDateUtils.formatShort(expense.date)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (expense.hasReceipt && onViewReceipt != null)
              IconButton(
                icon: const Icon(Icons.receipt_long, size: 22),
                tooltip: s.viewReceipt,
                onPressed: onViewReceipt,
              ),
            Text(
              CurrencyFormatter.format(
                expense.amount,
                currencyCode: currencyCode,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

void showReceiptDialog(BuildContext context, String url, AppStrings s) {
  showDialog<void>(
    context: context,
    builder: (ctx) {
      final maxH = MediaQuery.sizeOf(ctx).height * 0.65;
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.viewReceipt,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: InteractiveViewer(
                  child: url.startsWith('http')
                      ? Image.network(url, fit: BoxFit.contain)
                      : Image.file(File(url), fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
