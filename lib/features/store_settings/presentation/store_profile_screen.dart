import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_currencies.dart';
import 'package:pocket_karcha/core/constants/business_templates.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/utils/launch_utils.dart';
import 'package:pocket_karcha/core/utils/write_helpers.dart';
import 'package:pocket_karcha/features/auth/widgets/currency_bottom_sheet.dart';
import 'package:pocket_karcha/features/store_settings/widgets/whatsapp_field.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Store details: name, about, WhatsApp number, currency, type of business.
class StoreProfileScreen extends ConsumerStatefulWidget {
  const StoreProfileScreen({super.key});

  @override
  ConsumerState<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends ConsumerState<StoreProfileScreen> {
  final _name = TextEditingController();
  final _about = TextEditingController();
  final _phone = TextEditingController();
  String _countryCode = 'PK';
  String _dialCode = '+92';
  String _currency = 'PKR';
  String _business = 'other';
  String? _error;
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _about.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _load() {
    final s = ref.read(currentStoreProvider);
    if (s == null || _loaded) return;
    _loaded = true;
    _name.text = s.name;
    _about.text = s.about;
    _countryCode = s.countryCode;
    _dialCode = s.dialCode;
    _phone.text = WhatsAppField.localPart(s.whatsapp, s.dialCode);
    _currency = s.currency;
    _business = s.businessType;
  }

  Future<void> _pickCurrency(StoreStrings ss) async {
    final code = await showCurrencyBottomSheet(
      context,
      selectedCode: _currency,
      urdu: ss.isUrdu,
    );
    if (code != null) setState(() => _currency = code);
  }

  void _save() {
    final ss = ref.read(storeStringsProvider);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = ss.enterShopName);
      return;
    }
    final digits = LaunchUtils.toWhatsAppDigits(_phone.text, dialCode: _dialCode);
    if (_phone.text.replaceAll(RegExp(r'\D'), '').length < 7) {
      setState(() => _error = ss.enterValidWhatsapp);
      return;
    }
    final repo = ref.read(storeRepositoryProvider);
    final uid = ref.read(storeOwnerIdProvider);
    if (repo == null || uid == null) return;
    final currency = AppCurrencies.byCode(_currency);
    backgroundWrite(
      repo.updateStore(uid, {
        'name': name,
        'about': _about.text.trim(),
        'whatsapp': digits,
        'dialCode': _dialCode,
        'countryCode': _countryCode,
        'currency': currency.code,
        'currencySymbol': currency.symbol,
        'businessType': _business,
      }),
      ss,
    );
    showRootSnack(message: ss.storeSaved, type: AppSnackType.success);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    ref.watch(currentStoreProvider);
    _load();
    final currency = AppCurrencies.byCode(_currency);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text(ss.storeDetails),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          FieldLabel(ss.storeName),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(hintText: ss.shopNameHint),
          ),
          const SizedBox(height: 14),
          FieldLabel('${ss.aboutStore} · ${ss.optional}'),
          TextField(
            controller: _about,
            maxLines: 3,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: ss.aboutStoreHint),
          ),
          const SizedBox(height: 6),
          FieldLabel(ss.whatsappNumber),
          WhatsAppField(
            controller: _phone,
            countryCode: _countryCode,
            urdu: ss.isUrdu,
            onCountryChanged: (c) => setState(() {
              _countryCode = c.code ?? _countryCode;
              _dialCode = c.dialCode ?? _dialCode;
            }),
          ),
          const SizedBox(height: 16),
          FieldLabel(ss.currency),
          CreamCard(
            radius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            onTap: () => _pickCurrency(ss),
            child: Row(
              children: [
                Text(currency.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${currency.name(ss.isUrdu)} (${currency.symbol})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.expand_more_rounded, color: AppColors.inkSoft),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FieldLabel(ss.businessType),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in BusinessTemplates.all)
                ChoiceChip(
                  label: Text('${t.emoji}  ${t.label(ss.isUrdu)}'),
                  selected: _business == t.key,
                  onSelected: (_) => setState(() => _business = t.key),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: _save, child: Text(ss.save)),
        ),
      ),
    );
  }
}
