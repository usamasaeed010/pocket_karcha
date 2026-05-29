import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/data/models/person_model.dart';
import 'package:pocket_karcha/features/people/widgets/person_phone_field.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/providers/people_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_button.dart';
import 'package:pocket_karcha/shared/widgets/app_text_field.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';

class AddPersonScreen extends ConsumerStatefulWidget {
  const AddPersonScreen({
    super.key,
    required this.contactId,
    this.initialName = '',
    this.initialCountryCode = 'PK',
    this.initialDialCode = '+92',
    this.initialPhoneLocal = '',
  });

  final String contactId;
  final String initialName;
  final String initialCountryCode;
  final String initialDialCode;
  final String initialPhoneLocal;

  @override
  ConsumerState<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends ConsumerState<AddPersonScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late String _countryCode;
  late String _dialCode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _phone = TextEditingController(text: widget.initialPhoneLocal);
    _countryCode = widget.initialCountryCode;
    _dialCode = widget.initialDialCode;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(appStringsProvider);
    final name = _name.text.trim();
    if (name.isEmpty) {
      context.showErrorSnack(s.nameRequired);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(peopleActionsProvider).add(
            PersonModel(
              id: widget.contactId,
              name: name,
              countryCode: _countryCode,
              dialCode: _dialCode,
              phoneLocal: _phone.text.trim(),
            ),
          );
      if (mounted) {
        context.showSuccessSnack(s.snackPersonAdded);
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) context.showErrorSnack(s.snackSomethingWrong);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final urdu = ref.watch(localeUrduProvider);

    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      appBar: AppToolbar(
        title: s.addPeople,
        subtitle: s.addPeopleFormDesc,
        showBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppTextField(
            controller: _name,
            label: s.name,
            hint: s.name,
          ),
          const SizedBox(height: AppSpacing.lg),
          PersonPhoneField(
            controller: _phone,
            countryCode: _countryCode,
            dialCode: _dialCode,
            urdu: urdu,
            onCountryChanged: (CountryCode code) {
              setState(() {
                _countryCode = code.code ?? 'PK';
                _dialCode = code.dialCode ?? '+92';
              });
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: s.addPeople,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
