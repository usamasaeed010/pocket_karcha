import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/money.dart';
import 'package:pocket_karcha/core/utils/write_helpers.dart';
import 'package:pocket_karcha/data/models/store_model.dart';
import 'package:pocket_karcha/features/store_home/store_actions.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// How the public order page works: cart or request, delivery / pickup,
/// fees, minimum, questions, page language and the paused message.
class OrderSettingsScreen extends ConsumerStatefulWidget {
  const OrderSettingsScreen({super.key});

  @override
  ConsumerState<OrderSettingsScreen> createState() => _OrderSettingsScreenState();
}

class _Question {
  _Question(this.id, String label, this.required)
      : label = TextEditingController(text: label);

  final String id;
  final TextEditingController label;
  bool required;
}

class _OrderSettingsScreenState extends ConsumerState<OrderSettingsScreen> {
  final _area = TextEditingController();
  final _fee = TextEditingController();
  final _freeAbove = TextEditingController();
  final _pickupAddress = TextEditingController();
  final _minOrder = TextEditingController();
  final _paused = TextEditingController();
  final _questions = <_Question>[];
  OrderMode _mode = OrderMode.cart;
  bool _delivery = true;
  bool _pickup = true;
  bool _askNote = true;
  String _language = 'en';
  bool _loaded = false;

  @override
  void dispose() {
    for (final c in [_area, _fee, _freeAbove, _pickupAddress, _minOrder, _paused]) {
      c.dispose();
    }
    for (final q in _questions) {
      q.label.dispose();
    }
    super.dispose();
  }

  String _num(double v) => v > 0 ? formatPlainNumber(v) : '';

  void _load(StoreModel s) {
    if (_loaded) return;
    _loaded = true;
    _mode = s.orderMode;
    _delivery = s.deliveryEnabled;
    _pickup = s.pickupEnabled;
    _area.text = s.deliveryArea;
    _fee.text = _num(s.deliveryFee);
    _freeAbove.text = _num(s.freeDeliveryAbove);
    _pickupAddress.text = s.pickupAddress;
    _minOrder.text = _num(s.minOrder);
    _askNote = s.askNote;
    _language = s.pageLanguage == 'ur' ? 'ur' : 'en';
    _paused.text = s.pausedMessage;
    for (final f in s.customFields) {
      _questions.add(_Question(f.id, f.label, f.required));
    }
  }

  StoreModel? _draft() {
    final s = ref.read(currentStoreProvider);
    if (s == null) return null;
    return s.copyWith(
      orderMode: _mode,
      deliveryEnabled: _delivery,
      pickupEnabled: _pickup,
      deliveryArea: _area.text.trim(),
      deliveryFee: parseAmount(_fee.text) ?? 0,
      freeDeliveryAbove: parseAmount(_freeAbove.text) ?? 0,
      pickupAddress: _pickupAddress.text.trim(),
      minOrder: parseAmount(_minOrder.text) ?? 0,
      askNote: _askNote,
      pageLanguage: _language,
      pausedMessage: _paused.text.trim(),
      customFields: [
        for (final q in _questions)
          if (q.label.text.trim().isNotEmpty)
            CustomField(id: q.id, label: q.label.text.trim(), required: q.required),
      ],
    );
  }

  void _toggleMode(bool delivery, bool value, StoreStrings ss) {
    final otherOn = delivery ? _pickup : _delivery;
    if (!value && !otherOn) {
      context.showInfoSnack(ss.keepOneMode);
      return;
    }
    setState(() => delivery ? _delivery = value : _pickup = value);
  }

  void _addQuestion() {
    setState(() {
      _questions.add(
        _Question('q${DateTime.now().millisecondsSinceEpoch}', '', false),
      );
    });
  }

  void _removeQuestion(int i) {
    final q = _questions[i];
    setState(() => _questions.removeAt(i));
    WidgetsBinding.instance.addPostFrameCallback((_) => q.label.dispose());
  }

  void _save() {
    final ss = ref.read(storeStringsProvider);
    final draft = _draft();
    final repo = ref.read(storeRepositoryProvider);
    final uid = ref.read(storeOwnerIdProvider);
    if (draft == null || repo == null || uid == null) return;
    backgroundWrite(repo.updateStore(uid, draft.orderSettingsMap()), ss);
    showRootSnack(message: ss.settingsSaved, type: AppSnackType.success);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);
    final store = ref.watch(currentStoreProvider);
    if (store == null) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    _load(store);
    final symbol = store.currencySymbol;

    // Sample order preview with the current fee settings.
    const sampleSubtotal = 1000.0;
    final fee = !_delivery
        ? 0.0
        : ((parseAmount(_freeAbove.text) ?? 0) > 0 &&
                sampleSubtotal >= (parseAmount(_freeAbove.text) ?? 0))
            ? 0.0
            : (parseAmount(_fee.text) ?? 0);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(backgroundColor: AppColors.cream, title: Text(ss.orderSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          CreamCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                InitialAvatar(name: store.name, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ss.storeOrders(store.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.display(size: 17),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => StoreActions.viewStore(ref),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: Text(ss.previewPage),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SerifSectionHeader(
            icon: Icons.shopping_cart_outlined,
            title: ss.howCustomersSend,
            subtitle: ss.howCustomersSendSub,
          ),
          const SizedBox(height: 12),
          _ModeCard(
            selected: _mode == OrderMode.cart,
            icon: Icons.shopping_basket_outlined,
            title: ss.orderWithCart,
            body: ss.cartDesc,
            onTap: () => setState(() => _mode = OrderMode.cart),
          ),
          const SizedBox(height: 8),
          _ModeCard(
            selected: _mode == OrderMode.request,
            icon: Icons.chat_bubble_outline_rounded,
            title: ss.sendARequest,
            body: ss.requestDesc,
            onTap: () => setState(() => _mode = OrderMode.request),
          ),
          if (_mode == OrderMode.cart) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.creamDeep,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ss.previewSample(money(sampleSubtotal)),
                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 6),
                  _previewRow(ss.subtotal, money(sampleSubtotal)),
                  if (_delivery)
                    _previewRow(ss.deliveryFeeShort, fee > 0 ? money(fee) : ss.free),
                  _previewRow(ss.total, money(sampleSubtotal + fee), bold: true),
                ],
              ),
            ),
          ],
          const SizedBox(height: 26),
          SerifSectionHeader(
            icon: Icons.local_shipping_outlined,
            title: ss.howTheyGetIt,
            subtitle: ss.howTheyGetItSub,
          ),
          const SizedBox(height: 12),
          CreamCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchRow(
                  icon: Icons.delivery_dining_outlined,
                  title: ss.delivery,
                  subtitle: ss.deliverySub,
                  value: _delivery,
                  onChanged: (v) => _toggleMode(true, v, ss),
                ),
                if (_delivery) ...[
                  const SizedBox(height: 6),
                  FieldLabel(ss.deliveryArea),
                  TextField(
                    controller: _area,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(hintText: ss.deliveryAreaHint),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FieldLabel(ss.deliveryFee),
                            MoneyInput(
                              controller: _fee,
                              symbol: symbol,
                              dense: true,
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FieldLabel(ss.freeAbove),
                            MoneyInput(
                              controller: _freeAbove,
                              symbol: symbol,
                              dense: true,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ss.zeroNever,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                const Divider(height: 1, color: AppColors.creamBorder),
                SwitchRow(
                  icon: Icons.shopping_bag_outlined,
                  title: ss.pickup,
                  subtitle: ss.pickupSub,
                  value: _pickup,
                  onChanged: (v) => _toggleMode(false, v, ss),
                ),
                if (_pickup) ...[
                  const SizedBox(height: 6),
                  FieldLabel('${ss.pickupAddress} · ${ss.optional}'),
                  TextField(
                    controller: _pickupAddress,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          CreamCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FieldLabel(ss.minOrder),
                MoneyInput(controller: _minOrder, symbol: symbol, dense: true),
                const SizedBox(height: 4),
                Text(
                  ss.zeroNoMin,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SerifSectionHeader(
            icon: Icons.assignment_outlined,
            title: ss.whatYouAsk,
            subtitle: ss.whatYouAskSub,
          ),
          const SizedBox(height: 12),
          CreamCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _alwaysRow(Icons.person_outline_rounded, ss.customerName, ss.always),
                const Divider(height: 1, color: AppColors.creamBorder),
                _alwaysRow(Icons.phone_outlined, ss.askPhone, ss.always),
                if (_delivery) ...[
                  const Divider(height: 1, color: AppColors.creamBorder),
                  _alwaysRow(Icons.place_outlined, ss.askAddress, ss.always),
                ],
                const Divider(height: 1, color: AppColors.creamBorder),
                SwitchRow(
                  icon: Icons.sticky_note_2_outlined,
                  title: ss.askNoteTitle,
                  subtitle: ss.askNoteSub,
                  value: _askNote,
                  onChanged: (v) => setState(() => _askNote = v),
                ),
              ],
            ),
          ),
          for (var i = 0; i < _questions.length; i++) ...[
            const SizedBox(height: 8),
            CreamCard(
              padding: const EdgeInsets.fromLTRB(14, 10, 4, 6),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _questions[i].label,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: ss.questionHint,
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeQuestion(i),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: AppColors.inkSoft,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ss.requiredLabel,
                          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                        ),
                      ),
                      Switch(
                        value: _questions[i].required,
                        onChanged: (v) => setState(() => _questions[i].required = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _questions.length >= 10 ? null : _addQuestion,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: Text(ss.addQuestion),
            ),
          ),
          const SizedBox(height: 20),
          SerifSectionHeader(
            icon: Icons.translate_rounded,
            title: ss.pageLanguage,
            subtitle: ss.pageLanguageSub,
          ),
          const SizedBox(height: 12),
          ChoicePills<String>(
            options: const ['en', 'ur'],
            selected: _language,
            labelOf: (l) => l == 'ur' ? 'اردو' : 'English',
            onSelected: (l) => setState(() => _language = l),
          ),
          const SizedBox(height: 26),
          SerifSectionHeader(
            icon: Icons.pause_circle_outline_rounded,
            title: ss.whenPaused,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paused,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: ss.pausedMessageHint),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: _save, child: Text(ss.saveSettings)),
        ),
      ),
    );
  }

  Widget _previewRow(String k, String v, {bool bold = false}) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
      color: bold ? AppColors.ink : AppColors.inkSoft,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(k, style: style)),
          Text(v, style: style),
        ],
      ),
    );
  }

  Widget _alwaysRow(IconData icon, String title, String badge) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.brandDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
            ),
          ),
          SoftChip(
            label: badge,
            background: AppColors.creamDeep,
            foreground: AppColors.inkSoft,
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CreamCard(
      onTap: onTap,
      color: selected ? AppColors.brandSoft : null,
      borderColor: selected ? AppColors.brand : null,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: selected ? AppColors.brandDark : AppColors.inkSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.brandDark : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            color: selected ? AppColors.brand : AppColors.inkFaint,
          ),
        ],
      ),
    );
  }
}
