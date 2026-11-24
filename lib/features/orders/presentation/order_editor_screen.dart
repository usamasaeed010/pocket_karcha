import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/money.dart';
import 'package:pocket_karcha/core/utils/write_helpers.dart';
import 'package:pocket_karcha/data/models/order_model.dart';
import 'package:pocket_karcha/data/models/product_model.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Counter order (new) or "Edit order" (change items / price a request).
class OrderEditorScreen extends ConsumerStatefulWidget {
  const OrderEditorScreen({super.key, this.existing});

  final OrderModel? existing;

  @override
  ConsumerState<OrderEditorScreen> createState() => _OrderEditorScreenState();
}

class _OrderEditorScreenState extends ConsumerState<OrderEditorScreen> {
  final _lines = <String, OrderItem>{};
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  final _fee = TextEditingController();
  final _search = TextEditingController();
  String _query = '';
  Fulfillment _fulfillment = Fulfillment.pickup;
  bool _hasPaid = true;
  bool _handedOver = true;
  bool _dirty = false;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      for (final i in e.items) {
        _lines[i.key] = i;
      }
      _fulfillment = e.fulfillment;
      _fee.text = formatPlainNumber(e.deliveryFee);
      _note.text = e.note;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _note, _fee, _search]) {
      c.dispose();
    }
    super.dispose();
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  double get _subtotal =>
      _lines.values.fold<double>(0, (s, i) => s + i.lineTotal);

  double _autoFee() =>
      ref.read(currentStoreProvider)?.deliveryFeeFor(_subtotal) ?? 0;

  double get _deliveryFee {
    if (_fulfillment != Fulfillment.delivery) return 0;
    final typed = _fee.text.trim();
    if (typed.isEmpty) return _autoFee();
    return parseAmount(typed) ?? 0;
  }

  double get _total => _subtotal + _deliveryFee;

  int _qtyFor(ProductModel p) => _lines.values
      .where((i) => i.productId == p.id)
      .fold<int>(0, (s, i) => s + i.qty);

  void _addItem(OrderItem item) {
    setState(() {
      final existing = _lines[item.key];
      _lines[item.key] =
          existing == null ? item : existing.copyWith(qty: existing.qty + item.qty);
      _dirty = true;
    });
  }

  void _changeQty(String key, int delta) {
    final line = _lines[key];
    if (line == null) return;
    setState(() {
      final q = line.qty + delta;
      if (q <= 0) {
        _lines.remove(key);
      } else {
        _lines[key] = line.copyWith(qty: q);
      }
      _dirty = true;
    });
  }

  OrderItem _plainLine(ProductModel p) =>
      OrderItem(productId: p.id, name: p.name, price: p.price, qty: 1);

  Future<void> _pickVariant(ProductModel p) async {
    final money = ref.read(moneyProvider);
    final v = await showCreamSheet<ProductVariant>(
      context,
      title: p.name,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          children: [
            for (final v in p.variants)
              ListTile(
                title: Text(v.name),
                trailing: Text(
                  money(v.price),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(ctx, v),
              ),
          ],
        ),
      ),
    );
    if (v == null) return;
    _addItem(
      OrderItem(
        productId: p.id,
        name: p.name,
        variant: v.name,
        price: v.price,
        qty: 1,
      ),
    );
  }

  Future<void> _editLinePrice(OrderItem line) async {
    final ss = ref.read(storeStringsProvider);
    final symbol = ref.read(currentStoreProvider)?.currencySymbol ?? 'Rs';
    final c = TextEditingController(text: formatPlainNumber(line.price));
    final v = await showCreamSheet<double>(
      context,
      title: ss.priceFor(line.label),
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
              onPressed: () => Navigator.pop(ctx, parseAmount(c.text) ?? 0),
              child: Text(ss.save),
            ),
          ],
        ),
      ),
    );
    if (v == null) return;
    setState(() {
      _lines[line.key] = line.copyWith(price: v);
      _dirty = true;
    });
  }

  Future<void> _customItem() async {
    final ss = ref.read(storeStringsProvider);
    final symbol = ref.read(currentStoreProvider)?.currencySymbol ?? 'Rs';
    final name = TextEditingController();
    final price = TextEditingController();
    String? error;
    final item = await showCreamSheet<OrderItem>(
      context,
      title: ss.customItem,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldLabel(ss.itemName),
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              FieldLabel(ss.price),
              MoneyInput(controller: price, symbol: symbol),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12.5),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  final n = name.text.trim();
                  if (n.isEmpty) {
                    setSheet(() => error = ss.productNameRequired);
                    return;
                  }
                  Navigator.pop(
                    ctx,
                    OrderItem(
                      productId: 'custom',
                      name: n,
                      price: parseAmount(price.text) ?? 0,
                      qty: 1,
                    ),
                  );
                },
                child: Text(ss.add),
              ),
            ],
          ),
        ),
      ),
    );
    if (item != null) _addItem(item);
  }

  void _save() {
    final ss = ref.read(storeStringsProvider);
    if (_lines.isEmpty) {
      context.showErrorSnack(ss.addAtLeastOne);
      return;
    }
    final repo = ref.read(storeRepositoryProvider);
    final uid = ref.read(storeOwnerIdProvider);
    if (repo == null || uid == null) return;

    final items = _lines.values.toList();
    final fee = _deliveryFee;
    final totals = OrderModel.totalsFor(items, fee);
    final e = widget.existing;

    if (e == null) {
      final now = DateTime.now();
      final total = totals.total;
      final order = OrderModel(
        id: repo.newOrderId(uid),
        number: OrderModel.newNumber(),
        source: OrderSource.counter,
        status: _handedOver ? OrderStatus.delivered : OrderStatus.confirmed,
        fulfillment: _fulfillment,
        customer: OrderCustomer(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          address: _fulfillment == Fulfillment.delivery ? _address.text.trim() : '',
        ),
        items: items,
        subtotal: totals.subtotal,
        deliveryFee: fee,
        total: total,
        paid: _hasPaid ? total : 0,
        payments: _hasPaid && total > 0
            ? [OrderPayment(amount: total, at: now)]
            : const [],
        note: _note.text.trim(),
        createdAt: now,
      );
      backgroundWrite(repo.saveOrder(uid, order), ss);
      showRootSnack(message: ss.orderSaved, type: AppSnackType.success);
    } else {
      final data = <String, dynamic>{
        'items': items.map((i) => i.toMap()).toList(),
        'itemCount': items.fold<int>(0, (s, i) => s + i.qty),
        'subtotal': totals.subtotal,
        'deliveryFee': fee,
        'total': totals.total,
        'fulfillment': _fulfillment.name,
        'note': _note.text.trim(),
      };
      if ((totals.total - e.total).abs() > 0.001 && e.total > 0) {
        data['amountChanged'] = true;
        data['originalTotal'] = e.originalTotal ?? e.total;
      }
      backgroundWrite(repo.updateOrder(uid, e.id, data), ss);
      showRootSnack(message: ss.orderUpdated, type: AppSnackType.success);
    }
    _saving = true;
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
      _saving = true;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);
    final store = ref.watch(currentStoreProvider);
    final symbol = store?.currencySymbol ?? 'Rs';
    final products = ref.watch(productListProvider);
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? products
        : products
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q))
            .toList();
    final request = widget.existing?.requestText.trim() ?? '';

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          title: Text(_isEdit ? ss.editOrderTitle : ss.counterOrderTitle),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (request.isNotEmpty) ...[
              CreamCard(
                color: AppColors.dispatchedSoft,
                borderColor: const Color(0xFFD3E0F7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CapsLabel(ss.customerRequest),
                    const SizedBox(height: 6),
                    Text(request, style: const TextStyle(fontSize: 14.5, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (products.isNotEmpty) ...[
              StoreSearchField(
                controller: _search,
                hint: ss.searchProducts,
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 10),
              CreamCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < shown.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          indent: 14,
                          endIndent: 14,
                          color: AppColors.creamBorder,
                        ),
                      _pickRow(shown[i], ss, money),
                    ],
                    if (shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          ss.noProductsMatch,
                          style: const TextStyle(color: AppColors.inkSoft),
                        ),
                      ),
                  ],
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  ss.noProductsForOrder,
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 13.5),
                ),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _customItem,
                icon: const Icon(Icons.add_rounded, size: 19),
                label: Text(ss.addCustomItem),
              ),
            ),
            if (_lines.isNotEmpty) ...[
              const SizedBox(height: 8),
              CapsLabel(ss.itemsInOrder),
              const SizedBox(height: 8),
              CreamCard(
                padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
                child: Column(
                  children: [
                    for (final line in _lines.values.toList())
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _editLinePrice(line),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.label,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          line.price > 0
                                              ? money(line.price)
                                              : ss.setPrice,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: line.price > 0
                                                ? AppColors.inkSoft
                                                : AppColors.pending,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.edit_outlined,
                                          size: 12,
                                          color: AppColors.inkFaint,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            QtyStepper(
                              qty: line.qty,
                              onMinus: () => _changeQty(line.key, -1),
                              onPlus: () => _changeQty(line.key, 1),
                            ),
                            SizedBox(
                              width: 78,
                              child: Text(
                                money(line.lineTotal),
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (!_isEdit) ...[
              const SizedBox(height: 20),
              CapsLabel(ss.customerOptional),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _touch(),
                decoration: InputDecoration(
                  hintText: ss.customerName,
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _touch(),
                decoration: InputDecoration(
                  hintText: ss.customerPhone,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                ),
              ),
            ],
            const SizedBox(height: 20),
            CapsLabel(ss.howTheyGetItCaps),
            const SizedBox(height: 8),
            ChoicePills<Fulfillment>(
              options: const [Fulfillment.pickup, Fulfillment.delivery],
              selected: _fulfillment,
              labelOf: (f) => f == Fulfillment.pickup ? ss.pickup : ss.delivery,
              iconOf: (f) => f == Fulfillment.pickup
                  ? Icons.shopping_bag_outlined
                  : Icons.delivery_dining_outlined,
              onSelected: (f) => setState(() {
                _fulfillment = f;
                _dirty = true;
                if (!_isEdit) _handedOver = f == Fulfillment.pickup;
              }),
            ),
            if (_fulfillment == Fulfillment.delivery) ...[
              if (!_isEdit) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _address,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => _touch(),
                  decoration: InputDecoration(
                    hintText: ss.address,
                    prefixIcon: const Icon(Icons.place_outlined, size: 20),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              FieldLabel(ss.deliveryFee),
              MoneyInput(
                controller: _fee,
                symbol: symbol,
                hint: formatPlainNumber(_autoFee()),
                onChanged: (_) => setState(() => _dirty = true),
              ),
            ],
            if (!_isEdit) ...[
              const SizedBox(height: 14),
              CreamCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: Column(
                  children: [
                    SwitchRow(
                      icon: Icons.payments_outlined,
                      title: ss.customerHasPaid,
                      value: _hasPaid,
                      onChanged: (v) => setState(() => _hasPaid = v),
                    ),
                    const Divider(height: 1, color: AppColors.creamBorder),
                    SwitchRow(
                      icon: Icons.task_alt_rounded,
                      title: ss.handedOver,
                      subtitle: ss.handedOverSub,
                      value: _handedOver,
                      onChanged: (v) => setState(() => _handedOver = v),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            FieldLabel(ss.noteLabel),
            TextField(
              controller: _note,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _touch(),
              decoration: InputDecoration(hintText: ss.orderNoteHint),
            ),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.creamCard,
            border: Border(top: BorderSide(color: AppColors.creamBorder)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lines.isEmpty
                            ? ss.total
                            : '${ss.total} · ${ss.itemsLabel(_lines.values.fold<int>(0, (s, i) => s + i.qty))}',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                      ),
                      Text(money(_total), style: AppFonts.display(size: 22)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(_isEdit ? ss.saveChanges : ss.saveOrder),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickRow(ProductModel p, StoreStrings ss, String Function(num) money) {
    final qty = _qtyFor(p);
    final price = p.hasVariants ? ss.fromPrice(money(p.displayPrice)) : money(p.price);
    final plainKey = _plainLine(p).key;
    final plainQty = _lines[plainKey]?.qty ?? 0;

    Widget trailing;
    if (p.hasVariants) {
      trailing = AddPill(
        label: qty > 0 ? '+ $qty' : ss.add,
        onTap: () => _pickVariant(p),
      );
    } else if (plainQty > 0) {
      trailing = QtyStepper(
        qty: plainQty,
        onMinus: () => _changeQty(plainKey, -1),
        onPlus: () => _changeQty(plainKey, 1),
      );
    } else {
      trailing = AddPill(label: ss.add, onTap: () => _addItem(_plainLine(p)));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: Opacity(
              opacity: p.inStock ? 1 : 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    p.inStock ? price : '$price · ${ss.outOfStock}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
