import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart' show storeStringsProvider;
import 'package:pocket_karcha/core/utils/money.dart';
import 'package:pocket_karcha/core/utils/write_helpers.dart';
import 'package:pocket_karcha/data/models/product_model.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Add or edit one product: name, price or sizes, description, category,
/// stock.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final ProductModel? product;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _OptionRow {
  _OptionRow({String name = '', String price = ''})
      : name = TextEditingController(text: name),
        price = TextEditingController(text: price);

  final TextEditingController name;
  final TextEditingController price;
  final FocusNode priceFocus = FocusNode();

  void dispose() {
    name.dispose();
    price.dispose();
    priceFocus.dispose();
  }
}

/// One-tap size sets for the menu. Names stay in English — they are the
/// words customers use ("half", "full") and what voice entry listens for.
const _sizePresets = <List<String>>[
  ['Half', 'Full'],
  ['Small', 'Medium', 'Large'],
  ['Single', 'Double'],
];

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController();
  final _options = <_OptionRow>[];
  bool _inStock = true;
  bool _dirty = false;
  bool _leaving = false;
  String? _error;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _name.text = p.name;
      _price.text = p.hasVariants ? '' : formatPlainNumber(p.price);
      _description.text = p.description;
      _category.text = p.category;
      _inStock = p.inStock;
      for (final v in p.variants) {
        _options.add(_OptionRow(name: v.name, price: formatPlainNumber(v.price)));
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _category.dispose();
    for (final o in _options) {
      o.dispose();
    }
    super.dispose();
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _addOption() {
    setState(() {
      // First option starts with the single price, so nothing is lost.
      if (_options.isEmpty && _price.text.trim().isNotEmpty) {
        _options.add(_OptionRow(price: _price.text.trim()));
      } else {
        _options.add(_OptionRow());
      }
      _dirty = true;
    });
  }

  /// Adds a size set (e.g. Half / Full). A price typed already goes to the
  /// biggest size, so nothing is lost.
  void _addPreset(List<String> names) {
    final single = _price.text.trim();
    setState(() {
      for (var i = 0; i < names.length; i++) {
        final last = i == names.length - 1;
        _options.add(_OptionRow(name: names[i], price: last ? single : ''));
      }
      _dirty = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_options.isNotEmpty && mounted) _options.first.priceFocus.requestFocus();
    });
  }

  void _removeOption(int i) {
    final row = _options[i];
    setState(() {
      _options.removeAt(i);
      if (_options.isEmpty && _price.text.trim().isEmpty) {
        _price.text = row.price.text;
      }
      _dirty = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
  }

  void _save() {
    final ss = ref.read(storeStringsProvider);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = ss.productNameRequired);
      return;
    }

    final variants = <ProductVariant>[];
    for (final o in _options) {
      final n = o.name.text.trim();
      final p = parseAmount(o.price.text);
      if (n.isEmpty && o.price.text.trim().isEmpty) continue;
      if (n.isEmpty || p == null) {
        setState(() => _error = ss.optionsIncomplete);
        return;
      }
      variants.add(ProductVariant(name: n, price: p));
    }

    double price = 0;
    if (variants.isEmpty) {
      final p = parseAmount(_price.text);
      if (p == null) {
        setState(() => _error = ss.priceRequired);
        return;
      }
      price = p;
    }

    final repo = ref.read(storeRepositoryProvider);
    final uid = ref.read(storeOwnerIdProvider);
    if (repo == null || uid == null) return;
    final existing = widget.product;
    final product = ProductModel(
      id: existing?.id ?? '',
      name: name,
      price: price,
      description: _description.text.trim(),
      category: _category.text.trim(),
      inStock: _inStock,
      sortOrder: existing?.sortOrder ?? ref.read(productListProvider).length,
      variants: variants,
      createdAt: existing?.createdAt,
    );
    backgroundWrite(repo.saveProduct(uid, product), ss);
    showRootSnack(message: ss.productSaved, type: AppSnackType.success);
    _leaving = true;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final p = widget.product;
    if (p == null) return;
    final ss = ref.read(storeStringsProvider);
    final ok = await confirmAction(
      context,
      title: ss.deleteProductConfirm(p.name),
      body: ss.deleteProductBody,
      confirmLabel: ss.delete,
      cancelLabel: ss.cancel,
      destructive: true,
    );
    final repo = ref.read(storeRepositoryProvider);
    final uid = ref.read(storeOwnerIdProvider);
    if (!ok || !mounted || repo == null || uid == null) return;
    backgroundWrite(repo.deleteProduct(uid, p.id), ss);
    showRootSnack(message: ss.productDeleted);
    _leaving = true;
    Navigator.of(context).pop();
  }

  Future<void> _confirmDiscard() async {
    final ss = ref.read(storeStringsProvider);
    final ok = await confirmAction(
      context,
      title: ss.discardChanges,
      body: ss.discardChangesBody,
      confirmLabel: ss.discard,
      cancelLabel: ss.keepEditing,
      destructive: true,
    );
    if (ok && mounted) {
      _leaving = true;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final symbol = ref.watch(currentStoreProvider)?.currencySymbol ?? 'Rs';
    final typed = _category.text.trim().toLowerCase();
    final suggestions = ref
        .watch(productCategoriesProvider)
        .where((c) => c.toLowerCase() != typed)
        .take(8)
        .toList();

    return PopScope(
      canPop: !_dirty || _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          title: Text(_isEdit ? ss.editProductTitle : ss.addProductTitle),
          actions: [
            if (_isEdit)
              IconButton(
                tooltip: ss.delete,
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            FieldLabel(ss.productName),
            TextField(
              controller: _name,
              autofocus: !_isEdit,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _touch(),
              decoration: InputDecoration(hintText: ss.productNameHint),
            ),
            if (_options.isEmpty) ...[
              const SizedBox(height: 14),
              FieldLabel(ss.price),
              MoneyInput(
                controller: _price,
                symbol: symbol,
                onChanged: (_) => _touch(),
              ),
            ],
            const SizedBox(height: 14),
            FieldLabel('${ss.description} · ${ss.optional}'),
            TextField(
              controller: _description,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _touch(),
              decoration: InputDecoration(hintText: ss.descriptionHint),
            ),
            const SizedBox(height: 14),
            FieldLabel('${ss.category} · ${ss.optional}'),
            TextField(
              controller: _category,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _dirty = true),
              decoration: InputDecoration(hintText: ss.categoryHint),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in suggestions)
                    ActionChip(
                      label: Text(c),
                      onPressed: () => setState(() {
                        _category.text = c;
                        _dirty = true;
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            CreamCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ss.optionsTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ss.optionsHint,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                  ),
                  if (_options.isEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      ss.quickSizes,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final preset in _sizePresets)
                          ActionChip(
                            avatar: const Icon(Icons.add_rounded, size: 16),
                            label: Text(preset.join(' / ')),
                            onPressed: () => _addPreset(preset),
                          ),
                      ],
                    ),
                  ],
                  for (var i = 0; i < _options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _options[i].name,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _touch(),
                              decoration: InputDecoration(
                                hintText: ss.optionNameHint,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: MoneyInput(
                              controller: _options[i].price,
                              focusNode: _options[i].priceFocus,
                              symbol: symbol,
                              dense: true,
                              textInputAction: i < _options.length - 1
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onChanged: (_) => _touch(),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeOption(i),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: AppColors.inkSoft,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _addOption,
                      icon: const Icon(Icons.add_rounded, size: 19),
                      label: Text(ss.addOption),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CreamCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: SwitchRow(
                title: ss.inStock,
                subtitle: ss.inStockSub,
                value: _inStock,
                onChanged: (v) => setState(() {
                  _inStock = v;
                  _dirty = true;
                }),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
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
      ),
    );
  }
}
