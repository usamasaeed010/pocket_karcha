import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/launch_utils.dart';
import 'package:pocket_karcha/core/utils/time_ago.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/data/models/person_model.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_options_sheet.dart';
import 'package:pocket_karcha/features/khata/entry_status.dart';
import 'package:pocket_karcha/features/khata/widgets/entry_editor_sheet.dart';
import 'package:pocket_karcha/features/khata/widgets/khata_widgets.dart';
import 'package:pocket_karcha/features/khata/widgets/person_sheet.dart';
import 'package:pocket_karcha/features/voice/voice_entry_sheet.dart';
import 'package:pocket_karcha/providers/people_provider.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// One person's lena-dena: what is due either way, every entry, and
/// "You gave" / "You got" buttons.
class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({super.key, required this.personId});

  final String personId;

  void _addEntry(BuildContext context, PersonModel person, {required bool gave}) {
    showEntryEditor(
      context,
      book: EntryBook.people,
      personId: person.id,
      personName: person.name,
      gave: gave,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PersonModel person,
    int ledgerEntries,
  ) async {
    final ss = ref.read(storeStringsProvider);
    final ok = await confirmAction(
      context,
      title: ss.deletePersonTitle(person.name),
      body: ss.deletePersonBody(ledgerEntries),
      confirmLabel: ss.delete,
      cancelLabel: ss.cancel,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    unawaited(
      ref
          .read(peopleActionsProvider)
          .removeWithEntries(person.id)
          .catchError((Object _) {
        showRootSnack(message: ss.somethingWrong, type: AppSnackType.error);
      }),
    );
    Navigator.of(context).pop();
  }

  void _remind(WidgetRef ref, PersonModel person, double due) {
    final ss = ref.read(storeStringsProvider);
    final money = ref.read(moneyProvider);
    final store = ref.read(currentStoreProvider);
    LaunchUtils.openWhatsApp(
      phoneDigits: LaunchUtils.toWhatsAppDigits(
        person.phoneLocal,
        dialCode: person.dialCode,
      ),
      text: ss.reminderText(person.name, money(due), store?.name ?? ''),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);
    final person = ref.watch(personByIdProvider(personId));
    final ledger = ref.watch(personLedgerProvider(personId));
    final entries = ref.watch(personExpensesProvider(personId));
    final urdu = ss.isUrdu;

    if (person == null) {
      // A new person shows up a moment after saving.
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(backgroundColor: AppColors.cream),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final net = ledger.net;
    final settled = ledger.isSettled;
    final color = settled
        ? AppColors.inkSoft
        : (net > 0 ? AppColors.brandDark : AppColors.danger);
    final status = settled
        ? ss.allSettled
        : (net > 0 ? ss.willGiveYou(person.name) : ss.youWillGiveTo(person.name));
    final hasPhone = person.phoneLocal.isNotEmpty;
    final ledgerEntries =
        entries.where((e) => e.book == EntryBook.people).length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            InitialAvatar(name: person.name, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.5,
                    ),
                  ),
                  if (hasPhone)
                    Text(
                      person.displayPhone,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12.5,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: ss.voiceEntry,
            onPressed: () => showVoiceEntrySheet(context, person: person),
            icon: const Icon(Icons.mic_none_rounded),
          ),
          if (hasPhone)
            IconButton(
              tooltip: ss.call,
              onPressed: () => LaunchUtils.call(person.fullPhone),
              icon: const Icon(Icons.call_outlined),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              if (v == 'edit') showAddPersonSheet(context, existing: person);
              if (v == 'delete') _delete(context, ref, person, ledgerEntries);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(ss.editPerson)),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  ss.deletePerson,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          CreamCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status, style: const TextStyle(color: AppColors.inkSoft)),
                const SizedBox(height: 4),
                Text(
                  money(settled ? 0 : net.abs()),
                  style: AppFonts.display(size: 32, color: color),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.creamBorder),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Total(
                      label: ss.youGave,
                      value: money(ledger.gave),
                      color: AppColors.danger,
                    ),
                    _Total(
                      label: ss.youGot,
                      value: money(ledger.got),
                      color: AppColors.brandDark,
                    ),
                  ],
                ),
                if (net > 0 && !settled && hasPhone) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _remind(ref, person, net),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.whatsapp,
                      side: BorderSide(
                        color: AppColors.whatsapp.withValues(alpha: 0.5),
                      ),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 19),
                    label: Text(ss.remindOnWhatsApp),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          CapsLabel(ss.entriesLabel),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            CreamCard(
              child: Text(
                ss.noLedgerEntries,
                style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
              ),
            )
          else
            KhataEntryCard(
              children: [
                for (final e in entries)
                  _LedgerEntryTile(
                    entry: e,
                    ss: ss,
                    urdu: urdu,
                    money: money,
                    onTap: () => e.book == EntryBook.people
                        ? showEntryEditor(
                            context,
                            book: EntryBook.people,
                            existing: e,
                            personName: person.name,
                          )
                        : showTransactionOptions(context, ref, e),
                  ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addEntry(context, person, gave: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.north_east_rounded, size: 19),
                  label: Text(ss.youGave),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addEntry(context, person, gave: false),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.south_west_rounded, size: 19),
                  label: Text(ss.youGot),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerEntryTile extends StatelessWidget {
  const _LedgerEntryTile({
    required this.entry,
    required this.ss,
    required this.urdu,
    required this.money,
    required this.onTap,
  });

  final ExpenseModel entry;
  final StoreStrings ss;
  final bool urdu;
  final String Function(num) money;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effect = ledgerEffectOf(entry);
    final shop = entry.book == EntryBook.shop;
    final color = switch (effect) {
      LedgerEffect.gave => AppColors.danger,
      LedgerEffect.got => AppColors.brandDark,
      LedgerEffect.none => AppColors.inkSoft,
    };
    // Shop entries with a status say what they were (sale, purchase …);
    // lena-dena and older entries say who gave.
    final side = shop && entry.status != null
        ? switch (entry.type) {
            ExpenseRecordType.income => ss.khAddSale,
            ExpenseRecordType.purchase => ss.khAddPurchase,
            ExpenseRecordType.expense => ss.khAddExpense,
          }
        : (effect == LedgerEffect.got ? ss.youGot : ss.youGave);
    final what = entry.note.isNotEmpty
        ? entry.note
        : (entry.hasItemName ? entry.itemName! : '');
    final tag = !shop
        ? null
        : entry.status == null
            ? ss.shopEntryTag
            : '${ss.shopEntryTag} · '
                '${entry.isPending ? ss.statusPending : ss.statusPaid}';
    return KhataEntryTile(
      icon: switch (effect) {
        LedgerEffect.gave => Icons.north_east_rounded,
        LedgerEffect.got => Icons.south_west_rounded,
        LedgerEffect.none => Icons.check_circle_outline_rounded,
      },
      iconColor: color,
      title: what.isNotEmpty ? what : side,
      subtitle: what.isNotEmpty
          ? '$side · ${TimeAgo.dayLabel(entry.date, urdu: urdu)}'
          : TimeAgo.dayAndTime(entry.date, urdu: urdu),
      tag: tag,
      tagColor: entry.isPending ? pendingColor : null,
      amount: money(entry.amount),
      amountColor: effect == LedgerEffect.none ? AppColors.ink : color,
      onTap: onTap,
    );
  }
}
