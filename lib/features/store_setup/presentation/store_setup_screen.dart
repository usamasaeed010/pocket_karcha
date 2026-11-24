import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_currencies.dart';
import 'package:pocket_karcha/core/constants/business_templates.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/navigation/app_navigator.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/launch_utils.dart';
import 'package:pocket_karcha/core/utils/money.dart';
import 'package:pocket_karcha/core/utils/slug_utils.dart';
import 'package:pocket_karcha/core/utils/write_helpers.dart';
import 'package:pocket_karcha/data/models/product_model.dart';
import 'package:pocket_karcha/data/models/store_model.dart';
import 'package:pocket_karcha/data/repositories/store_repository.dart';
import 'package:pocket_karcha/features/auth/widgets/currency_bottom_sheet.dart';
import 'package:pocket_karcha/features/products/presentation/paste_list_screen.dart';
import 'package:pocket_karcha/features/store_settings/widgets/slug_field.dart';
import 'package:pocket_karcha/features/store_settings/widgets/whatsapp_field.dart';
import 'package:pocket_karcha/providers/firebase_providers.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';
import 'package:pocket_karcha/providers/session_provider.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

enum _CreateResult { ok, taken, offline, failed }

/// Four quick steps after "Create my store": name → WhatsApp → link → items.
class StoreSetupScreen extends ConsumerStatefulWidget {
  const StoreSetupScreen({super.key});

  @override
  ConsumerState<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends ConsumerState<StoreSetupScreen> {
  static const _steps = 4;

  int _step = 0;
  String? _error;
  bool _creating = false;
  Object? _lastError;

  // 1 · Name
  final _name = TextEditingController();
  String? _businessType;

  // 2 · WhatsApp
  final _phone = TextEditingController();
  String _countryCode = 'PK';
  String _dialCode = '+92';
  String _currency = 'PKR';
  bool _currencyPicked = false;

  // 3 · Link
  String _slug = '';
  String _suggested = '';
  SlugCheck _slugStatus = SlugCheck.checking;

  // 4 · Items
  String? _itemsFor;
  bool _pasted = false;
  List<ProductModel> _items = [];
  List<bool> _picked = [];
  List<TextEditingController> _prices = [];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    for (final c in _prices) {
      c.dispose();
    }
    super.dispose();
  }

  int get _pickedCount => _picked.where((p) => p).length;

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  // ── Steps ──────────────────────────────────────────────────────────────

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _step = step;
    });
  }

  void _back() {
    if (_creating || _step == 0) return;
    _goTo(_step - 1);
  }

  void _next() {
    final ss = ref.read(storeStringsProvider);
    switch (_step) {
      case 0:
        if (_name.text.trim().isEmpty) {
          setState(() => _error = ss.enterShopName);
          return;
        }
        _goTo(1);
      case 1:
        if (_phone.text.replaceAll(RegExp(r'\D'), '').length < 7) {
          setState(() => _error = ss.enterValidWhatsapp);
          return;
        }
        _prepareSlug();
        _goTo(2);
      case 2:
        if (!_slugStatus.usable) {
          setState(() => _error = ss.pickAnotherLink);
          return;
        }
        _prepareItems();
        _goTo(3);
      default:
        _create();
    }
  }

  /// Suggests a link from the shop name unless the owner typed their own.
  void _prepareSlug() {
    final typedOwn = _slug.isNotEmpty && _slug != _suggested;
    if (typedOwn) return;
    _suggested = SlugUtils.suggest(_name.text.trim());
    _slug = _suggested;
    _slugStatus = SlugCheck.checking;
  }

  void _prepareItems() {
    if (_pasted) return;
    final key = _businessType ?? 'other';
    if (_itemsFor == key) return;
    _itemsFor = key;
    _setItems([
      for (final it in BusinessTemplates.byKey(key).items) it.toProduct(),
    ]);
  }

  void _setItems(List<ProductModel> items) {
    // Old fields may still be on screen this frame — free them after it.
    final old = _prices;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in old) {
        c.dispose();
      }
    });
    _items = items;
    _picked = List<bool>.filled(items.length, true, growable: true);
    _prices = [
      for (final p in items)
        TextEditingController(
          text: p.hasVariants || p.price <= 0 ? '' : formatPlainNumber(p.price),
        ),
    ];
  }

  Future<void> _pickCurrency() async {
    final ss = ref.read(storeStringsProvider);
    final code = await showCurrencyBottomSheet(
      context,
      selectedCode: _currency,
      urdu: ss.isUrdu,
    );
    if (code == null || !mounted) return;
    setState(() {
      _currency = code;
      _currencyPicked = true;
    });
  }

  Future<void> _pasteList() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PasteListScreen(
          onDone: (items) {
            if (!mounted) return;
            setState(() {
              _pasted = true;
              _itemsFor = null;
              _setItems(items);
            });
          },
        ),
      ),
    );
  }

  void _useSuggested() {
    setState(() {
      _pasted = false;
      _itemsFor = null;
      _prepareItems();
    });
  }

  List<ProductModel> _selected() {
    return [
      for (var i = 0; i < _items.length; i++)
        if (_picked[i]) _withPrice(i),
    ];
  }

  ProductModel _withPrice(int i) {
    final item = _items[i];
    if (item.hasVariants) return item;
    final price = parseAmount(_prices[i].text) ?? 0;
    // Items without a price show as out of stock until priced.
    return item.copyWith(price: price, inStock: price > 0);
  }

  // ── Create ─────────────────────────────────────────────────────────────

  Future<void> _create({bool skipItems = false}) async {
    if (_creating) return;
    final ss = ref.read(storeStringsProvider);
    final repo = ref.read(storeRepositoryProvider);
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? ref.read(storeOwnerIdProvider);
    if (repo == null || uid == null) {
      context.showErrorSnack(ss.serviceUnavailable);
      return;
    }
    FocusScope.of(context).unfocus();

    final currency = AppCurrencies.byCode(_currency);
    final store = StoreModel(
      id: uid,
      name: _name.text.trim(),
      slug: _slug,
      whatsapp: LaunchUtils.toWhatsAppDigits(_phone.text, dialCode: _dialCode),
      dialCode: _dialCode,
      countryCode: _countryCode,
      currency: currency.code,
      currencySymbol: currency.symbol,
      businessType: _businessType ?? 'other',
      pageLanguage: ss.isUrdu ? 'ur' : 'en',
      createdAt: DateTime.now(),
    );
    final starter = skipItems ? const <ProductModel>[] : _selected();

    setState(() {
      _creating = true;
      _error = null;
    });

    // Never overwrite a store that already exists for this account (an
    // earlier try that finished late, or "create" tapped while offline).
    final StoreModel? existing;
    try {
      existing = await repo
          .fetchStore(uid, serverOnly: true)
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      context.showErrorSnack(friendlyError(e, ss));
      return;
    }
    if (existing != null) {
      await _finish(uid, existing);
      return;
    }

    final result = await _commit(repo, store, starter, uid);
    if (!mounted) return;

    switch (result) {
      case _CreateResult.ok:
        await _finish(uid, store);
      case _CreateResult.taken:
        setState(() {
          _creating = false;
          _step = 2;
          _slugStatus = SlugCheck.taken;
          _error = ss.slugTaken;
        });
      case _CreateResult.offline:
        setState(() => _creating = false);
        context.showErrorSnack(ss.checkInternet);
      case _CreateResult.failed:
        setState(() => _creating = false);
        context.showErrorSnack(friendlyError(_lastError ?? '', ss));
    }
  }

  Future<_CreateResult> _commit(
    StoreRepository repo,
    StoreModel store,
    List<ProductModel> starter,
    String uid,
  ) async {
    var slugYours = _slugStatus == SlugCheck.yours;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await repo
            .createStore(store, starter, slugAlreadyYours: slugYours)
            .timeout(const Duration(seconds: 20));
        return _CreateResult.ok;
      } on FirebaseException catch (e) {
        _lastError = e;
        if (e.code != 'permission-denied' || slugYours) {
          return _CreateResult.failed;
        }
        // Creating a link that exists is denied. It can still be ours — an
        // earlier try that finished in the background — then retry without it.
        final status = await _recheckSlug(repo, uid);
        if (status != SlugStatus.yours) return _CreateResult.taken;
        slugYours = true;
      } on TimeoutException {
        return _CreateResult.offline;
      } catch (e) {
        _lastError = e;
        return _CreateResult.failed;
      }
    }
    return _CreateResult.failed;
  }

  Future<SlugStatus?> _recheckSlug(StoreRepository repo, String uid) async {
    try {
      return await repo
          .checkSlug(_slug, uid: uid)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
  }

  Future<void> _finish(String uid, StoreModel store) async {
    await ref.read(preferencesServiceProvider).setStoreReady(uid, true);
    unawaited(_saveProfile(uid, store));

    final session = ref.read(sessionProvider.notifier);
    await session.markProfileComplete(
      phone: store.whatsapp,
      currency: store.currency,
    );
    await session.completeOnboarding();

    ref.read(storeTabProvider.notifier).state = StoreTabs.home;
    ref.read(storeJustCreatedProvider.notifier).state = true;
    if (!mounted) return;
    AppNavigator.toHome(context);
  }

  /// Profile doc used by the khata screens — best effort, never blocks.
  Future<void> _saveProfile(String uid, StoreModel store) async {
    final profiles = ref.read(userProfileServiceProvider);
    if (profiles == null) return;
    try {
      await profiles.completeProfile(
        uid: uid,
        phone: store.whatsapp,
        countryCode: store.countryCode,
        dialCode: store.dialCode,
        currency: store.currency,
        urdu: store.pageLanguage == 'ur',
        displayName: store.name,
      );
    } catch (e) {
      debugPrint('Store setup: profile not saved: $e');
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);

    return PopScope(
      canPop: _step == 0 && !_creating,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: _creating
              ? _CreatingView(text: ss.settingUpStore)
              : Column(
                  children: [
                    _Header(
                      progress: (_step + 1) / _steps,
                      label: ss.stepOf(_step + 1, _steps),
                      onBack: _step > 0 ? _back : null,
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: ListView(
                          key: ValueKey(_step),
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: [
                            ...switch (_step) {
                              0 => _nameStep(ss),
                              1 => _whatsappStep(ss),
                              2 => _linkStep(ss),
                              _ => _itemsStep(ss),
                            },
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _bottomBar(ss),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _bottomBar(StoreStrings ss) {
    final last = _step == _steps - 1;
    final canNext = switch (_step) {
      2 => _slugStatus.usable,
      _ => true,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: canNext ? _next : null,
            child: Text(last ? ss.createMyStore : ss.next),
          ),
          if (last)
            TextButton(
              onPressed: () => _create(skipItems: true),
              child: Text(ss.skipAddLater),
            ),
        ],
      ),
    );
  }

  List<Widget> _title(String title, String sub) => [
        Text(title, style: AppFonts.display(size: 26, height: 1.2)),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(color: AppColors.inkSoft, height: 1.4)),
        const SizedBox(height: 22),
      ];

  List<Widget> _nameStep(StoreStrings ss) => [
        ..._title(ss.setupNameTitle, ss.setupNameSub),
        FieldLabel(ss.shopName),
        TextField(
          controller: _name,
          autofocus: _name.text.isEmpty,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onChanged: (_) => _clearError(),
          onSubmitted: (_) => _next(),
          decoration: InputDecoration(
            hintText: ss.shopNameHint,
            counterText: '',
          ),
        ),
        const SizedBox(height: 26),
        FieldLabel(ss.whatDoYouSell),
        const SizedBox(height: 2),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in BusinessTemplates.all)
              _TypeChip(
                label: '${t.emoji}  ${t.label(ss.isUrdu)}',
                selected: _businessType == t.key,
                onTap: () => setState(() => _businessType = t.key),
              ),
          ],
        ),
      ];

  List<Widget> _whatsappStep(StoreStrings ss) {
    final currency = AppCurrencies.byCode(_currency);
    return [
      ..._title(ss.setupWhatsappTitle, ss.setupWhatsappSub),
      FieldLabel(ss.whatsappNumber),
      WhatsAppField(
        controller: _phone,
        countryCode: _countryCode,
        urdu: ss.isUrdu,
        autofocus: _phone.text.isEmpty,
        onChanged: (_) => _clearError(),
        onCountryChanged: (c) => setState(() {
          _countryCode = c.code ?? _countryCode;
          _dialCode = c.dialCode ?? _dialCode;
          if (!_currencyPicked) {
            _currency = AppCurrencies.forCountryCode(_countryCode).code;
          }
        }),
      ),
      const SizedBox(height: 22),
      FieldLabel(ss.currency),
      CreamCard(
        onTap: _pickCurrency,
        radius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Text(currency.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${currency.name(ss.isUrdu)} (${currency.symbol})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: AppColors.inkSoft),
          ],
        ),
      ),
    ];
  }

  List<Widget> _linkStep(StoreStrings ss) => [
        ..._title(ss.setupLinkTitle, ss.setupLinkSub),
        FieldLabel(ss.linkName),
        SlugField(
          initial: _slug,
          onChanged: (slug, status) {
            if (!mounted || _step != 2) return;
            setState(() {
              _slug = slug;
              _slugStatus = status;
              if (status.usable) _error = null;
            });
          },
        ),
      ];

  List<Widget> _itemsStep(StoreStrings ss) {
    final symbol = AppCurrencies.byCode(_currency).symbol;
    final hasTemplate =
        BusinessTemplates.byKey(_businessType ?? 'other').items.isNotEmpty;
    return [
      ..._title(ss.setupItemsTitle, ss.setupItemsSub),
      if (_items.isEmpty)
        CreamCard(
          child: Column(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.brand,
                size: 30,
              ),
              const SizedBox(height: 10),
              Text(
                ss.pasteListHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkSoft, height: 1.45),
              ),
            ],
          ),
        )
      else ...[
        CapsLabel(ss.itemsSelected(_pickedCount)),
        const SizedBox(height: 8),
        for (var i = 0; i < _items.length; i++) ...[
          _ItemRow(
            item: _items[i],
            picked: _picked[i],
            price: _prices[i],
            symbol: symbol,
            hint: ss.price,
            onPicked: (v) => setState(() => _picked[i] = v),
          ),
          const SizedBox(height: 8),
        ],
      ],
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pasteList,
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: Text(ss.pasteMyList),
            ),
          ),
          if (_pasted && hasTemplate) ...[
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _useSuggested,
                child: Text(ss.useSuggested),
              ),
            ),
          ],
        ],
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.progress,
    required this.label,
    required this.onBack,
  });

  final double progress;
  final String label;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  )
                else
                  const SizedBox(width: 12),
                const Spacer(),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) => LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: AppColors.creamDeep,
                  valueColor: const AlwaysStoppedAnimation(AppColors.brand),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandSoft : AppColors.creamCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.brand : AppColors.creamBorder,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: selected ? AppColors.brandDark : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.picked,
    required this.price,
    required this.symbol,
    required this.hint,
    required this.onPicked,
  });

  final ProductModel item;
  final bool picked;
  final TextEditingController price;
  final String symbol;
  final String hint;
  final ValueChanged<bool> onPicked;

  @override
  Widget build(BuildContext context) {
    final variants = item.variants;
    return CreamCard(
      radius: 14,
      color: picked ? AppColors.creamCard : AppColors.cream,
      padding: const EdgeInsets.fromLTRB(4, 6, 10, 6),
      child: Row(
        children: [
          Checkbox(
            value: picked,
            activeColor: AppColors.brand,
            onChanged: (v) => onPicked(v ?? false),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onPicked(!picked),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: picked ? AppColors.ink : AppColors.inkFaint,
                      ),
                    ),
                    if (variants.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        variants
                            .map((v) => '${v.name} ${formatMoney(v.price, symbol)}')
                            .join(' · '),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (variants.isEmpty)
            SizedBox(
              width: 112,
              child: MoneyInput(
                controller: price,
                symbol: symbol,
                hint: hint,
                dense: true,
              ),
            ),
        ],
      ),
    );
  }
}

class _CreatingView extends StatelessWidget {
  const _CreatingView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 18),
          Text(text, style: AppFonts.display(size: 20)),
        ],
      ),
    );
  }
}
