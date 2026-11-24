import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/money.dart';
import 'package:pocket_karcha/core/utils/write_helpers.dart';
import 'package:pocket_karcha/data/models/product_model.dart';
import 'package:pocket_karcha/features/products/presentation/paste_list_screen.dart';
import 'package:pocket_karcha/features/products/presentation/product_form_screen.dart';
import 'package:pocket_karcha/features/store_home/store_actions.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Products tab: drag to reorder, quick price edit, stock switch,
/// "Edit prices" for all at once and "Change all prices" by % or amount.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  late final TextEditingController _search =
      TextEditingController(text: ref.read(productSearchProvider));

  /// Order shown right after a drag, until Firestore reflects it.
  List<String>? _localOrder;

  bool _editPrices = false;
  final Map<String, TextEditingController> _priceCtrls = {};

  @override
  void dispose() {
    _search.dispose();
    _disposePriceCtrls();
    super.dispose();
  }

  void _disposePriceCtrls() {
    for (final c in _priceCtrls.values) {
      c.dispose();
    }
    _priceCtrls.clear();
  }

  StoreStrings get _ss => ref.read(storeStringsProvider);

  ({dynamic repo, String uid})? get _target {
    final repo = ref.read(storeRepositoryProvider);
    final uid = ref.read(storeOwnerIdProvider);
    if (repo == null || uid == null) return null;
    return (repo: repo, uid: uid);
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  // ── Reorder ─────────────────────────────────────────────────────────────

  List<ProductModel> _ordered(List<ProductModel> fresh) {
    final local = _localOrder;
    if (local == null) return fresh;
    final byId = {for (final p in fresh) p.id: p};
    if (byId.length != local.length || !local.every(byId.containsKey)) {
      return fresh;
    }
    return [for (final id in local) byId[id]!];
  }

  void _onReorder(List<ProductModel> list, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final next = [...list];
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex, moved);
    setState(() => _localOrder = next.map((p) => p.id).toList());
    HapticFeedback.selectionClick();
    final t = _target;
    if (t != null) backgroundWrite(t.repo.saveSortOrder(t.uid, next), _ss);
  }

  // ── Single product actions ──────────────────────────────────────────────

  Future<void> _quickPrice(ProductModel p) async {
    if (p.hasVariants) {
      _push(ProductFormScreen(product: p));
      return;
    }
    final ss = _ss;
    final symbol = ref.read(currentStoreProvider)?.currencySymbol ?? 'Rs';
    final c = TextEditingController(text: formatPlainNumber(p.price));
    final v = await showCreamSheet<double>(
      context,
      title: ss.priceFor(p.name),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MoneyInput(
              controller: c,
              symbol: symbol,
              autofocus: true,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final v = parseAmount(c.text);
                if (v != null) Navigator.pop(ctx, v);
              },
              child: Text(ss.save),
            ),
          ],
        ),
      ),
    );
    final t = _target;
    if (v == null || t == null || v == p.price) return;
    backgroundWrite(t.repo.updatePrice(t.uid, p.id, v), ss);
  }

  void _setStock(ProductModel p, bool inStock) {
    final t = _target;
    if (t == null) return;
    backgroundWrite(t.repo.setInStock(t.uid, p.id, inStock), _ss);
  }

  void _duplicate(ProductModel p, int count) {
    final t = _target;
    if (t == null) return;
    final ss = _ss;
    final copy = p.copyWith(
      id: '',
      name: ss.copyOf(p.name),
      sortOrder: count,
      resetCreatedAt: true,
    );
    backgroundWrite(t.repo.saveProduct(t.uid, copy), ss);
    showRootSnack(message: ss.productDuplicated, type: AppSnackType.success);
  }

  Future<void> _delete(ProductModel p) async {
    final ss = _ss;
    final ok = await confirmAction(
      context,
      title: ss.deleteProductConfirm(p.name),
      body: ss.deleteProductBody,
      confirmLabel: ss.delete,
      cancelLabel: ss.cancel,
      destructive: true,
    );
    final t = _target;
    if (!ok || t == null) return;
    backgroundWrite(t.repo.deleteProduct(t.uid, p.id), ss);
    showRootSnack(message: ss.productDeleted);
  }

  // ── Edit prices (all at once) ───────────────────────────────────────────

  void _startEditPrices(List<ProductModel> products) {
    _disposePriceCtrls();
    for (final p in products) {
      if (p.hasVariants) {
        for (var i = 0; i < p.variants.length; i++) {
          _priceCtrls['${p.id}#$i'] =
              TextEditingController(text: formatPlainNumber(p.variants[i].price));
        }
      } else {
        _priceCtrls[p.id] = TextEditingController(text: formatPlainNumber(p.price));
      }
    }
    setState(() => _editPrices = true);
  }

  void _stopEditPrices() {
    setState(() => _editPrices = false);
    // Dispose after the fields have left the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) => _disposePriceCtrls());
  }

  void _savePrices(List<ProductModel> products) {
    final updated = <ProductModel>[];
    for (final p in products) {
      if (p.hasVariants) {
        var changed = false;
        final variants = <ProductVariant>[];
        for (var i = 0; i < p.variants.length; i++) {
          final v = p.variants[i];
          final price = parseAmount(_priceCtrls['${p.id}#$i']?.text ?? '') ?? v.price;
          if (price != v.price) changed = true;
          variants.add(v.copyWith(price: price));
        }
        if (changed) updated.add(p.copyWith(variants: variants));
      } else {
        final price = parseAmount(_priceCtrls[p.id]?.text ?? '') ?? p.price;
        if (price != p.price) updated.add(p.copyWith(price: price));
      }
    }
    final t = _target;
    if (updated.isNotEmpty && t != null) {
      backgroundWrite(t.repo.savePrices(t.uid, updated), _ss);
    }
    _stopEditPrices();
    showRootSnack(message: _ss.pricesSaved, type: AppSnackType.success);
  }

  // ── Change all prices by % / amount ─────────────────────────────────────

  Future<void> _changeAll(List<ProductModel> products) async {
    final ss = _ss;
    final money = ref.read(moneyProvider);
    final symbol = ref.read(currentStoreProvider)?.currencySymbol ?? 'Rs';
    final amount = TextEditingController();
    var up = true;
    var percent = true;
    var round = 0;

    double apply(double price, double v) {
      if (v <= 0) return price;
      var n = percent ? price * (1 + (up ? v : -v) / 100) : price + (up ? v : -v);
      if (n < 0) n = 0;
      if (round > 0) {
        n = (n / round).round() * round.toDouble();
      } else {
        n = (n * 100).roundToDouble() / 100;
      }
      return n;
    }

    List<ProductModel> changedFor(double v) {
      final out = <ProductModel>[];
      for (final p in products) {
        if (p.hasVariants) {
          final vs = p.variants.map((x) => x.copyWith(price: apply(x.price, v))).toList();
          final changed = [
            for (var i = 0; i < vs.length; i++) vs[i].price != p.variants[i].price,
          ].any((c) => c);
          if (changed) out.add(p.copyWith(variants: vs));
        } else {
          final n = apply(p.price, v);
          if (n != p.price) out.add(p.copyWith(price: n));
        }
      }
      return out;
    }

    await showCreamSheet<void>(
      context,
      title: ss.changeAllPrices,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final v = parseAmount(amount.text) ?? 0;
          final changed = changedFor(v);
          final byId = {for (final p in products) p.id: p};
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChoicePills<bool>(
                  options: const [true, false],
                  selected: up,
                  labelOf: (b) => b ? ss.increase : ss.decrease,
                  iconOf: (b) =>
                      b ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  onSelected: (b) => setSheet(() => up = b),
                ),
                const SizedBox(height: 10),
                ChoicePills<bool>(
                  options: const [true, false],
                  selected: percent,
                  dense: true,
                  labelOf: (b) => b ? ss.byPercent : ss.byAmount,
                  onSelected: (b) => setSheet(() => percent = b),
                ),
                const SizedBox(height: 16),
                FieldLabel(ss.howMuch),
                TextField(
                  controller: amount,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  onChanged: (_) => setSheet(() {}),
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixText: percent ? null : '$symbol ',
                    suffixText: percent ? '%' : null,
                  ),
                ),
                const SizedBox(height: 14),
                FieldLabel(ss.roundTo),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final r in const [0, 5, 10, 50])
                      ChoiceChip(
                        label: Text(r == 0 ? ss.noRounding : '$r'),
                        selected: round == r,
                        onSelected: (_) => setSheet(() => round = r),
                      ),
                  ],
                ),
                if (changed.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  CapsLabel(ss.preview),
                  const SizedBox(height: 6),
                  for (final p in changed.take(4))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            money(byId[p.id]!.displayPrice),
                            style: const TextStyle(
                              color: AppColors.inkFaint,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            money(p.displayPrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: changed.isEmpty
                      ? null
                      : () {
                          final t = _target;
                          if (t != null) {
                            backgroundWrite(t.repo.savePrices(t.uid, changed), ss);
                          }
                          Navigator.pop(ctx);
                          showRootSnack(
                            message: ss.pricesSaved,
                            type: AppSnackType.success,
                          );
                        },
                  child: Text(ss.updatePricesN(changed.length)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);
    final symbol = ref.watch(currentStoreProvider)?.currencySymbol ?? 'Rs';
    final async = ref.watch(productsProvider);
    final products = _ordered(ref.watch(productListProvider));
    final q = ref.watch(productSearchProvider).trim().toLowerCase();
    final shown = q.isEmpty
        ? products
        : products
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q))
            .toList();
    final top = MediaQuery.paddingOf(context).top;

    Widget body;
    if (async.isLoading && products.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (products.isEmpty) {
      body = ListView(
        children: [
          EmptyHint(
            icon: Icons.restaurant_menu_rounded,
            title: ss.noProductsTitle,
            body: ss.noProductsBody,
          ),
        ],
      );
    } else if (_editPrices) {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final p in products) _priceEditRow(p, symbol),
        ],
      );
    } else if (shown.isEmpty) {
      body = ListView(
        children: [
          EmptyHint(icon: Icons.search_off_rounded, title: ss.noProductsMatch, body: ''),
        ],
      );
    } else if (q.isNotEmpty) {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: shown.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _productCard(shown[i], ss, money, products.length),
      );
    } else {
      body = ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        buildDefaultDragHandles: false,
        itemCount: products.length,
        onReorder: (a, b) => _onReorder(products, a, b),
        proxyDecorator: (child, _, _) => Material(
          color: Colors.transparent,
          elevation: 6,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(14),
          child: child,
        ),
        itemBuilder: (_, i) => Padding(
          key: ValueKey(products[i].id),
          padding: const EdgeInsets.only(bottom: 8),
          child: _productCard(products[i], ss, money, products.length, dragIndex: i),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 12, 4, 6),
            child: Row(
              children: [
                Text(ss.productsTitle, style: AppFonts.display(size: 26)),
                const SizedBox(width: 10),
                if (products.isNotEmpty)
                  SoftChip(
                    label: ss.productsLabel(products.length),
                    background: AppColors.creamDeep,
                    foreground: AppColors.inkSoft,
                  ),
                const Spacer(),
                if (products.isNotEmpty && !_editPrices) ...[
                  IconButton(
                    tooltip: ss.sharePriceList,
                    onPressed: () => StoreActions.sharePriceList(ref),
                    icon: const Icon(Icons.ios_share_rounded, size: 21),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (v) {
                      if (v == 'edit') _startEditPrices(products);
                      if (v == 'all') _changeAll(products);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text(ss.editPrices)),
                      PopupMenuItem(value: 'all', child: Text(ss.changeAllPrices)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (products.isNotEmpty && !_editPrices)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
              child: StoreSearchField(
                controller: _search,
                hint: ss.searchProducts,
                onChanged: (v) => ref.read(productSearchProvider.notifier).state = v,
              ),
            ),
          if (_editPrices)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Text(
                ss.editPrices,
                style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
              ),
            ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.creamCard,
          border: Border(top: BorderSide(color: AppColors.creamBorder)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: _editPrices
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _stopEditPrices,
                        child: Text(ss.cancel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _savePrices(products),
                        child: Text(ss.savePrices),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _push(const ProductFormScreen()),
                        icon: const Icon(Icons.add_rounded, size: 19),
                        label: Text(ss.addProduct),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _push(const PasteListScreen()),
                        icon: const Icon(Icons.content_paste_rounded, size: 18),
                        label: Text(ss.pasteList),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _productCard(
    ProductModel p,
    StoreStrings ss,
    String Function(num) money,
    int count, {
    int? dragIndex,
  }) {
    final sub = [
      if (p.category.trim().isNotEmpty) p.category.trim(),
      if (p.hasVariants) p.variants.map((v) => v.name).join(' · '),
      if (!p.hasVariants && p.description.trim().isNotEmpty) p.description.trim(),
    ].join(' · ');
    final price = p.hasVariants ? ss.fromPrice(money(p.displayPrice)) : money(p.price);

    return CreamCard(
      radius: 14,
      padding: EdgeInsets.fromLTRB(dragIndex == null ? 14 : 2, 6, 2, 6),
      onTap: () => _push(ProductFormScreen(product: p)),
      child: Row(
        children: [
          if (dragIndex != null)
            ReorderableDragStartListener(
              index: dragIndex,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Icon(Icons.drag_indicator_rounded, color: AppColors.inkFaint, size: 22),
              ),
            ),
          Expanded(
            child: Opacity(
              opacity: p.inStock ? 1 : 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  if (sub.isNotEmpty || !p.inStock)
                    Text(
                      p.inStock ? sub : [ss.outOfStock, if (sub.isNotEmpty) sub].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: p.inStock ? AppColors.inkSoft : AppColors.danger,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              onTap: () => _quickPrice(p),
              borderRadius: BorderRadius.circular(9),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                child: Text(
                  price,
                  style: const TextStyle(
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(value: p.inStock, onChanged: (v) => _setStock(p, v)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.inkSoft),
            padding: EdgeInsets.zero,
            onSelected: (v) {
              switch (v) {
                case 'edit':
                  _push(ProductFormScreen(product: p));
                case 'duplicate':
                  _duplicate(p, count);
                case 'stock':
                  _setStock(p, !p.inStock);
                case 'delete':
                  _delete(p);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(ss.edit)),
              PopupMenuItem(value: 'duplicate', child: Text(ss.duplicate)),
              PopupMenuItem(
                value: 'stock',
                child: Text(p.inStock ? ss.markOutOfStock : ss.markInStock),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(ss.delete, style: const TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceEditRow(ProductModel p, String symbol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CreamCard(
        radius: 14,
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: p.hasVariants
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  for (var i = 0; i < p.variants.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.variants[i].name,
                              style: const TextStyle(color: AppColors.inkSoft),
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: MoneyInput(
                              controller: _priceCtrls['${p.id}#$i']!,
                              symbol: symbol,
                              dense: true,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(
                    width: 130,
                    child: MoneyInput(
                      controller: _priceCtrls[p.id]!,
                      symbol: symbol,
                      dense: true,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
