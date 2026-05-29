import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/utils/phone_parser.dart';
import 'package:pocket_karcha/features/people/presentation/add_person_screen.dart';
import 'package:pocket_karcha/features/people/widgets/person_contact_tiles.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/providers/people_provider.dart';
import 'package:pocket_karcha/shared/widgets/animated_list_item.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';

class ContactPickerScreen extends ConsumerStatefulWidget {
  const ContactPickerScreen({super.key});

  @override
  ConsumerState<ContactPickerScreen> createState() =>
      _ContactPickerScreenState();
}

class _ContactPickerScreenState extends ConsumerState<ContactPickerScreen> {
  final _searchCtrl = TextEditingController();
  List<Contact> _contacts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final status =
          await FlutterContacts.permissions.request(PermissionType.read);
      if (status != PermissionStatus.granted &&
          status != PermissionStatus.limited) {
        final msg = ref.read(appStringsProvider).contactsPermissionDenied;
        setState(() {
          _loading = false;
          _error = msg;
        });
        if (mounted) context.showErrorSnack(msg);
        return;
      }

      final list = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );

      list.sort(
        (a, b) => (a.displayName ?? '')
            .toLowerCase()
            .compareTo((b.displayName ?? '').toLowerCase()),
      );

      if (!mounted) return;
      setState(() {
        _contacts = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      context.showErrorSnack(e.toString());
    }
  }

  List<Contact> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _contacts;
    return _contacts.where((c) {
      final name = (c.displayName ?? '').toLowerCase();
      final phones = c.phones.map((p) => p.number.toLowerCase()).join(' ');
      return name.contains(q) || phones.contains(q);
    }).toList();
  }

  void _openAddPerson(Contact contact) {
    final id = contact.id;
    if (id == null || id.isEmpty) return;

    final alreadyAdded =
        ref.read(peopleListProvider).any((p) => p.id == id);
    if (alreadyAdded) {
      context.showWarningSnack(ref.read(appStringsProvider).personAlreadyAdded);
      return;
    }

    final name = (contact.displayName ?? '').trim();
    final rawPhone =
        contact.phones.isNotEmpty ? contact.phones.first.number : null;
    final parsed = PhoneParser.parse(rawPhone);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddPersonScreen(
          contactId: id,
          initialName: name,
          initialCountryCode: parsed.countryCode,
          initialDialCode: parsed.dialCode,
          initialPhoneLocal: parsed.localNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final urdu = ref.watch(localeUrduProvider);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      appBar: AppToolbar(
        title: s.selectContact,
        subtitle: s.selectContactDesc,
        showBack: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: s.searchContacts,
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.75),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE8EDF3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE8EDF3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.dashboardGreen,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _loadContacts,
                                child: Text(s.retry),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              s.noContacts,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final c = filtered[i];
                              final name = (c.displayName ?? '').trim();
                              final phone = c.phones.isNotEmpty
                                  ? c.phones.first.number
                                  : '';

                              return AnimatedListItem(
                                index: i,
                                child: ContactListTile(
                                  name: name,
                                  phone: phone,
                                  noNameLabel: urdu ? 'بغیر نام' : 'No name',
                                  onTap: () => _openAddPerson(c),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
