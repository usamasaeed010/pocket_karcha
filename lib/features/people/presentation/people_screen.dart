import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/data/models/person_model.dart';
import 'package:pocket_karcha/features/people/presentation/contact_picker_screen.dart';
import 'package:pocket_karcha/features/people/presentation/person_detail_screen.dart';
import 'package:pocket_karcha/features/people/widgets/person_contact_tiles.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/providers/people_provider.dart';
import 'package:pocket_karcha/shared/widgets/animated_list_item.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  void _openContactPicker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ContactPickerScreen()),
    );
  }

  void _openPerson(BuildContext context, PersonModel person) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PersonDetailScreen(person: person),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    final people = ref.watch(peopleListProvider);

    return ColoredBox(
      color: AppColors.dashboardSurface,
      child: Stack(
        children: [
          people.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.45),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s.addPeople,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.addPeopleDesc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => _openContactPicker(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.dashboardGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(s.addPeople),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: people.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final p = people[i];
                    final ledger = ref.watch(personLedgerProvider(p.id));
                    final balanceColor = ledger.balance >= 0
                        ? AppColors.navActive
                        : AppColors.expense;

                    return AnimatedListItem(
                      index: i,
                      child: PersonListTile(
                      name: p.name,
                      phone: p.displayPhone,
                      creditLabel: s.credit,
                      creditValue: CurrencyFormatter.format(
                        ledger.credit,
                        currencyCode: currency,
                      ),
                      debitLabel: s.debit,
                      debitValue: CurrencyFormatter.format(
                        ledger.debit,
                        currencyCode: currency,
                      ),
                      balanceLabel: s.balance,
                      balanceValue: CurrencyFormatter.format(
                        ledger.balance,
                        currencyCode: currency,
                      ),
                      balanceColor: balanceColor,
                      onTap: () => _openPerson(context, p),
                      ),
                    );
                  },
                ),
          if (people.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _openContactPicker(context),
                backgroundColor: AppColors.dashboardGreen,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(s.addPeople),
              ),
            ),
        ],
      ),
    );
  }
}
