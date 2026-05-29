import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/data/models/person_model.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/presentation/add_expense_screen.dart';
import 'package:pocket_karcha/features/history/widgets/history_transaction_tile.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/providers/people_provider.dart';
import 'package:pocket_karcha/shared/widgets/animated_list_item.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';
import 'package:pocket_karcha/shared/widgets/empty_state_card.dart';

class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({super.key, required this.person});

  final PersonModel person;

  void _addTransaction(BuildContext context, TransactionType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddExpenseScreen(
          initialType: type,
          personId: person.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    final ledger = ref.watch(personLedgerProvider(person.id));
    final transactions = ref.watch(personExpensesProvider(person.id));

    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      appBar: AppToolbar(
        title: person.name,
        subtitle: person.displayPhone.isEmpty ? s.people : person.displayPhone,
        showBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: _LedgerCard(
                  label: s.credit,
                  amount: ledger.credit,
                  currency: currency,
                  color: AppColors.navActive,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LedgerCard(
                  label: s.debit,
                  amount: ledger.debit,
                  currency: currency,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.balance,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(
                    ledger.balance,
                    currencyCode: currency,
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: ledger.balance >= 0
                        ? AppColors.navActive
                        : AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.transactions,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            EmptyStateCard(
              icon: Icons.receipt_long_outlined,
              title: s.noTransactionsForPerson,
              subtitle: s.noTransactionsForPersonDesc,
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < transactions.length; i++) ...[
                    AnimatedListItem(
                      index: i,
                      child: HistoryTransactionTile(
                        expense: transactions[i],
                        currencyCode: currency,
                      ),
                    ),
                    if (i < transactions.length - 1)
                      const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFF1F5F9),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'person_got',
            onPressed: () => _addTransaction(context, TransactionType.got),
            backgroundColor: AppColors.navActive,
            icon: const Icon(Icons.arrow_downward_rounded),
            label: Text(s.youGot),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'person_gave',
            onPressed: () => _addTransaction(context, TransactionType.gave),
            backgroundColor: AppColors.expense,
            icon: const Icon(Icons.arrow_upward_rounded),
            label: Text(s.youGave),
          ),
        ],
      ),
    );
  }
}

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  final String label;
  final double amount;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(amount, currencyCode: currency),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
