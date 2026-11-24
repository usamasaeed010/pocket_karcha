import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/phone_parser.dart';
import 'package:pocket_karcha/data/models/person_model.dart';
import 'package:pocket_karcha/features/people/presentation/contact_picker_screen.dart';
import 'package:pocket_karcha/features/people/presentation/person_detail_screen.dart';
import 'package:pocket_karcha/providers/people_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Add a person to lena-dena (or edit one). A new person opens straight
/// into their ledger so the first entry is one tap away.
Future<void> showAddPersonSheet(BuildContext context, {PersonModel? existing}) {
  return showCreamSheet<void>(
    context,
    builder: (_) => _PersonSheet(existing: existing),
  );
}

class _PersonSheet extends ConsumerStatefulWidget {
  const _PersonSheet({this.existing});

  final PersonModel? existing;

  @override
  ConsumerState<_PersonSheet> createState() => _PersonSheetState();
}

class _PersonSheetState extends ConsumerState<_PersonSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    final local = p?.phoneLocal ?? '';
    _phone = TextEditingController(
      text: local.isEmpty || local.startsWith('0') ? local : '0$local',
    );
    // Numbers outside Pakistan keep their country code in the box.
    if (p != null && p.phoneLocal.isNotEmpty && p.dialCode != '+92') {
      _phone.text = p.displayPhone;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _pickContact() {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const ContactPickerScreen()),
    );
  }

  void _save() {
    final ss = ref.read(storeStringsProvider);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = ss.nameNeeded);
      return;
    }
    final old = widget.existing;
    final raw = _phone.text.trim();
    var country = old?.countryCode ?? 'PK';
    var dial = old?.dialCode ?? '+92';
    var local = '';
    if (raw.startsWith('+') || raw.startsWith('00')) {
      final parsed = PhoneParser.parse(
        raw.startsWith('00') ? '+${raw.substring(2)}' : raw,
      );
      country = parsed.countryCode;
      dial = parsed.dialCode;
      local = parsed.localNumber;
    } else {
      local = raw.replaceAll(RegExp(r'\D'), '');
      if (local.startsWith('0')) local = local.substring(1);
      if (old == null || old.dialCode == '+92') {
        country = 'PK';
        dial = '+92';
      }
    }

    final person = PersonModel(
      id: old?.id ?? 'p${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      countryCode: country,
      dialCode: dial,
      phoneLocal: local,
    );
    unawaited(
      ref.read(peopleActionsProvider).add(person).catchError((Object _) {
        showRootSnack(message: ss.somethingWrong, type: AppSnackType.error);
      }),
    );
    final navigator = Navigator.of(context);
    navigator.pop();
    if (!_editing) {
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => PersonDetailScreen(personId: person.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _editing ? ss.editPerson : ss.addPerson,
            style: AppFonts.display(size: 20),
          ),
          const SizedBox(height: 14),
          if (!_editing) ...[
            OutlinedButton.icon(
              onPressed: _pickContact,
              icon: const Icon(Icons.contacts_outlined),
              label: Text(ss.pickFromContacts),
            ),
            const SizedBox(height: 14),
          ],
          FieldLabel(ss.personNameLabel),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(errorText: _error),
          ),
          const SizedBox(height: 14),
          FieldLabel(ss.personPhoneLabel),
          const SizedBox(height: 6),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              hintText: '0300 1234567',
              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.inkSoft),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: _save, child: Text(ss.save)),
        ],
      ),
    );
  }
}
