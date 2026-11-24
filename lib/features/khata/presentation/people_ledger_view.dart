import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/time_ago.dart';
import 'package:pocket_karcha/data/models/person_model.dart';
import 'package:pocket_karcha/features/khata/widgets/khata_widgets.dart';
import 'package:pocket_karcha/features/khata/widgets/person_sheet.dart';
import 'package:pocket_karcha/features/people/presentation/person_detail_screen.dart';
import 'package:pocket_karcha/providers/people_provider.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Lena-dena: everyone you give money to or get money from, with what is
/// still due either way.
class PeopleLedgerView extends ConsumerStatefulWidget {
  const PeopleLedgerView({super.key});

  @override
  ConsumerState<PeopleLedgerView> createState() => _PeopleLedgerViewState();
}

class _PeopleLedgerViewState extends ConsumerState<PeopleLedgerView> {
  String _query = '';

  void _open(PersonModel p) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PersonDetailScreen(personId: p.id),
      ),
    );
  }

  bool _matches(PersonModel p, String q) {
    if (q.isEmpty) return true;
    if (p.name.toLowerCase().contains(q)) return true;
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 3 &&
        p.fullPhone.replaceAll(RegExp(r'\D'), '').contains(digits);
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);
    final people = ref.watch(peopleListProvider);
    final ledgers = ref.watch(ledgersProvider);
    final summary = ref.watch(peopleSummaryProvider);
    final urdu = ss.isUrdu;

    final addButton = KhataAddButton(
      label: ss.addPerson,
      icon: Icons.person_add_alt_1_rounded,
      onTap: () => showAddPersonSheet(context),
    );

    if (people.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: addButton,
        body: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            EmptyHint(
              icon: Icons.handshake_outlined,
              title: ss.noPeopleTitle,
              body: ss.noPeopleBody,
              action: FilledButton.icon(
                onPressed: () => showAddPersonSheet(context),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(ss.addPerson),
              ),
            ),
          ],
        ),
      );
    }

    // People with recent lena-dena first, then the rest by name.
    final sorted = [...people]
      ..sort((a, b) {
        final la = ledgers[a.id]?.lastActivity;
        final lb = ledgers[b.id]?.lastActivity;
        if (la == null && lb == null) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        if (la == null) return 1;
        if (lb == null) return -1;
        return lb.compareTo(la);
      });
    final q = _query.trim().toLowerCase();
    final shown = sorted.where((p) => _matches(p, q)).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: addButton,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          CreamCard(
            padding: EdgeInsets.zero,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _TotalHalf(
                    label: ss.youWillGet,
                    value: money(summary.toGet),
                    color: AppColors.brandDark,
                    icon: Icons.south_west_rounded,
                  ),
                  const VerticalDivider(
                    width: 1,
                    color: AppColors.creamBorder,
                  ),
                  _TotalHalf(
                    label: ss.youWillGive,
                    value: money(summary.toGive),
                    color: AppColors.danger,
                    icon: Icons.north_east_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (people.length > 5) ...[
            StoreSearchField(
              hint: ss.searchPeople,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
          ],
          if (shown.isNotEmpty)
            KhataEntryCard(
              children: [
                for (final p in shown)
                  _PersonRow(
                    person: p,
                    ledger: ledgers[p.id] ?? const PersonLedger(),
                    money: money,
                    ss: ss,
                    urdu: urdu,
                    onTap: () => _open(p),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TotalHalf extends StatelessWidget {
  const _TotalHalf({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(value, style: AppFonts.display(size: 22, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.person,
    required this.ledger,
    required this.money,
    required this.ss,
    required this.urdu,
    required this.onTap,
  });

  final PersonModel person;
  final PersonLedger ledger;
  final String Function(num) money;
  final StoreStrings ss;
  final bool urdu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final net = ledger.net;
    final settled = ledger.isSettled;
    final color = settled
        ? AppColors.inkSoft
        : (net > 0 ? AppColors.brandDark : AppColors.danger);
    final last = ledger.lastActivity;
    final subtitle = last != null
        ? TimeAgo.dayLabel(last, urdu: urdu)
        : person.displayPhone;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            InitialAvatar(name: person.name, size: 38),
            const SizedBox(width: 12),
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
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  settled ? ss.settledUp : money(net.abs()),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: settled ? 12.5 : 14.5,
                    color: color,
                  ),
                ),
                if (!settled) ...[
                  const SizedBox(height: 2),
                  Text(
                    net > 0 ? ss.youWillGet : ss.youWillGive,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
