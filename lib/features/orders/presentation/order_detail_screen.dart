import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/launch_utils.dart';
import 'package:pocket_karcha/core/utils/money.dart';
import 'package:pocket_karcha/core/utils/time_ago.dart';
import 'package:pocket_karcha/core/utils/write_helpers.dart';
import 'package:pocket_karcha/data/models/blocked_customer.dart';
import 'package:pocket_karcha/data/models/order_model.dart';
import 'package:pocket_karcha/features/orders/presentation/order_editor_screen.dart';
import 'package:pocket_karcha/features/orders/widgets/order_card.dart';
import 'package:pocket_karcha/features/store_home/store_actions.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// One order: status steps, items, payment, customer and the next action.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late bool _notify = ref.read(preferencesServiceProvider).notifyBuyer;

  StoreStrings get _ss => ref.read(storeStringsProvider);

  OrderModel? _find(List<OrderModel> list) {
    for (final o in list) {
      if (o.id == widget.orderId) return o;
    }
    return null;
  }

  OrderModel? get _latest => _find(ref.read(orderListProvider));

  void _write(Map<String, dynamic> data) {
    final repo = ref.read(storeRepositoryProvider);
    final uid = ref.read(storeOwnerIdProvider);
    if (repo == null || uid == null) return;
    backgroundWrite(repo.updateOrder(uid, widget.orderId, data), _ss);
  }

  // ── Status ──────────────────────────────────────────────────────────────

  void _setStatus(OrderModel o, OrderStatus next) {
    if (o.status == next) return;
    HapticFeedback.lightImpact();
    _write({'status': next.name});
    final forward = next == OrderStatus.cancelled || next.step > o.status.step;
    if (_notify && forward && o.customer.hasPhone) {
      final text = _statusMessage(o, next);
      if (text != null) {
        StoreActions.messageCustomer(ref, phone: o.customer.phone, text: text);
      }
    }
  }

  String? _statusMessage(OrderModel o, OrderStatus next) {
    final ss = _ss;
    final money = ref.read(moneyProvider);
    final store = ref.read(currentStoreProvider);
    final storeName = store?.name ?? '';
    final name = o.customer.name;
    final pickup = o.fulfillment == Fulfillment.pickup;
    final orig = o.originalTotal;
    return switch (next) {
      OrderStatus.pending => null,
      OrderStatus.confirmed => ss.msgConfirmed(
          name: name,
          store: storeName,
          number: o.number,
          total: money(o.total),
          changedFrom: o.amountChanged && orig != null && orig != o.total
              ? money(orig)
              : null,
        ),
      OrderStatus.dispatched => pickup
          ? ss.msgReady(
              name: name,
              store: storeName,
              number: o.number,
              pickupAddress: store?.pickupAddress ?? '',
            )
          : ss.msgDispatched(name: name, store: storeName, number: o.number),
      OrderStatus.delivered =>
        ss.msgDelivered(name: name, store: storeName, number: o.number),
      OrderStatus.cancelled =>
        ss.msgCancelled(name: name, store: storeName, number: o.number),
    };
  }

  Future<void> _cancel(OrderModel o) async {
    final ss = _ss;
    final ok = await confirmAction(
      context,
      title: ss.cancelOrderConfirm,
      body: ss.cancelOrderBody,
      confirmLabel: ss.cancelOrder,
      cancelLabel: ss.keepOrder,
      destructive: true,
    );
    if (ok) _setStatus(_latest ?? o, OrderStatus.cancelled);
  }

  // ── Payments ────────────────────────────────────────────────────────────

  void _addPayment(double amount, String method) {
    final payment =
        OrderPayment(amount: amount, at: DateTime.now(), method: method);
    _write({
      'paid': FieldValue.increment(amount),
      'payments': FieldValue.arrayUnion([payment.toMap()]),
    });
    HapticFeedback.lightImpact();
    showRootSnack(message: _ss.paymentSaved, type: AppSnackType.success);
  }

  void _markPaid(OrderModel o) {
    final due = (_latest ?? o).due;
    if (due > 0) _addPayment(due, 'cash');
  }

  Future<void> _recordPayment(OrderModel o) async {
    final ss = _ss;
    final symbol = ref.read(currentStoreProvider)?.currencySymbol ?? 'Rs';
    final amount = TextEditingController(
      text: o.due > 0 ? formatPlainNumber(o.due) : '',
    );
    var method = 'cash';
    String? error;

    await showCreamSheet<void>(
      context,
      title: ss.recordPayment,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldLabel(ss.amountReceived),
              MoneyInput(controller: amount, symbol: symbol, autofocus: true),
              if (error != null) ...[
                const SizedBox(height: 6),
                Text(
                  error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12.5),
                ),
              ],
              const SizedBox(height: 16),
              FieldLabel(ss.paidBy),
              ChoicePills<String>(
                options: const ['cash', 'online', 'other'],
                selected: method,
                dense: true,
                labelOf: ss.methodLabel,
                onSelected: (m) => setSheet(() => method = m),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final v = parseAmount(amount.text);
                  if (v == null || v <= 0) {
                    setSheet(() => error = ss.enterAmount);
                    return;
                  }
                  Navigator.pop(ctx);
                  _addPayment(v, method);
                },
                child: Text(ss.savePayment),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearPayments() async {
    final ss = _ss;
    final ok = await confirmAction(
      context,
      title: ss.clearPayments,
      body: ss.clearPaymentsConfirm,
      confirmLabel: ss.clearPayments,
      cancelLabel: ss.cancel,
      destructive: true,
    );
    if (ok) _write({'paid': 0, 'payments': <Object>[]});
  }

  // ── Other actions ───────────────────────────────────────────────────────

  void _edit(OrderModel o) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => OrderEditorScreen(existing: o)),
    );
  }

  Future<void> _delete(OrderModel o) async {
    final ss = _ss;
    final ok = await confirmAction(
      context,
      title: ss.deleteOrderConfirm,
      body: ss.deleteOrderBody,
      confirmLabel: ss.delete,
      cancelLabel: ss.cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final repo = ref.read(storeRepositoryProvider);
    final uid = ref.read(storeOwnerIdProvider);
    Navigator.of(context).pop();
    if (repo != null && uid != null) {
      backgroundWrite(repo.deleteOrder(uid, o.id), ss);
    }
  }

  /// Every key that would block this order's customer.
  Set<String> _blockKeys(OrderModel o) => BlockedCustomer.keysFor(
        phone: o.customer.phone,
        buyerUid: o.buyerUid,
        dialCode: ref.read(currentStoreProvider)?.dialCode ?? '+92',
      );

  Future<void> _block(OrderModel o) async {
    final ss = _ss;
    final name = o.displayName.isEmpty ? ss.blockedBadge : o.displayName;
    final ok = await confirmAction(
      context,
      title: ss.blockCustomerTitle(name),
      body: ss.blockCustomerBody,
      confirmLabel: ss.block,
      cancelLabel: ss.cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final repo = ref.read(storeRepositoryProvider);
    final uid = ref.read(storeOwnerIdProvider);
    if (repo == null || uid == null) return;
    backgroundWrite(
      repo.block(
        uid,
        keys: _blockKeys(o),
        group: BlockedCustomer.groupFor(
          phone: o.customer.phone,
          buyerUid: o.buyerUid,
          dialCode: ref.read(currentStoreProvider)?.dialCode ?? '+92',
        ),
        name: o.customer.name.trim(),
        phone: o.customer.phone.trim(),
      ),
      ss,
    );
    context.showInfoSnack(ss.customerBlocked);
  }

  /// Lifts every block that covers this order's customer.
  void _unblock(OrderModel o) {
    final repo = ref.read(storeRepositoryProvider);
    final uid = ref.read(storeOwnerIdProvider);
    if (repo == null || uid == null) return;
    final mine = _blockKeys(o);
    final entries = ref.read(blockedEntriesProvider).valueOrNull ?? const [];
    final groups = {
      for (final e in entries)
        if (mine.contains(e.key)) e.group,
    };
    backgroundWrite(
      repo.unblock(uid, [
        for (final e in entries)
          if (groups.contains(e.group)) e.key,
      ]),
      _ss,
    );
    context.showInfoSnack(_ss.customerUnblocked);
  }

  void _remind(OrderModel o) {
    final money = ref.read(moneyProvider);
    StoreActions.messageCustomer(
      ref,
      phone: o.customer.phone,
      text: _ss.msgReminder(
        name: o.customer.name,
        store: ref.read(currentStoreProvider)?.name ?? '',
        number: o.number,
        amount: money(o.due),
      ),
    );
  }

  void _share(OrderModel o) {
    final ss = _ss;
    final money = ref.read(moneyProvider);
    final store = ref.read(currentStoreProvider);
    final b = StringBuffer()
      ..writeln('${store?.name ?? ''} · #${o.number}')
      ..writeln(TimeAgo.dayAndTime(o.createdAt, urdu: ss.isUrdu));
    final c = o.customer;
    if (c.name.trim().isNotEmpty) b.writeln(c.name.trim());
    if (c.phone.trim().isNotEmpty) b.writeln(c.phone.trim());
    b.writeln(o.fulfillment == Fulfillment.pickup ? ss.pickup : ss.delivery);
    if (o.fulfillment == Fulfillment.delivery && c.address.trim().isNotEmpty) {
      b.writeln('${ss.address}: ${c.address.trim()}');
    }
    b.writeln();
    if (o.requestText.trim().isNotEmpty) b.writeln(o.requestText.trim());
    for (final i in o.items) {
      b.writeln('${i.qty} × ${i.label} — ${money(i.lineTotal)}');
    }
    b.writeln();
    if (o.deliveryFee > 0) {
      b.writeln('${ss.deliveryFeeShort}: ${money(o.deliveryFee)}');
    }
    b.writeln('${ss.total}: ${money(o.total)}');
    if (o.paid > 0) b.writeln('${ss.paidLabel}: ${money(o.paid)}');
    if (o.due > 0) b.writeln('${ss.dueLabel}: ${money(o.due)}');
    if (o.note.trim().isNotEmpty) b.writeln('${ss.noteLabel}: ${o.note.trim()}');
    LaunchUtils.shareText(b.toString().trim());
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);
    final loading = ref.watch(ordersProvider).isLoading;
    final o = _find(ref.watch(orderListProvider));

    if (o == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(backgroundColor: AppColors.cream),
        body: Center(
          child: loading
              ? const CircularProgressIndicator()
              : Text(ss.orderDeleted, style: const TextStyle(color: AppColors.inkSoft)),
        ),
      );
    }

    final pickup = o.fulfillment == Fulfillment.pickup;
    final name = o.customer.name.trim().isEmpty ? ss.walkIn : o.customer.name.trim();
    final showPayment = o.total > 0 || o.payments.isNotEmpty;
    final canBlock = o.source == OrderSource.link &&
        (o.customer.hasPhone || o.buyerUid.isNotEmpty);
    final blockedKeys = ref.watch(blockedKeysProvider);
    final blocked = canBlock && _blockKeys(o).any(blockedKeys.contains);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text('#${o.number}'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              switch (v) {
                case 'share':
                  _share(o);
                case 'remind':
                  _remind(o);
                case 'edit':
                  _edit(o);
                case 'delete':
                  _delete(o);
                case 'block':
                  _block(o);
                case 'unblock':
                  _unblock(o);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'share', child: Text(ss.shareOrder)),
              if (o.due > 0 && o.customer.hasPhone)
                PopupMenuItem(value: 'remind', child: Text(ss.sendReminder)),
              if (!o.isCancelled)
                PopupMenuItem(value: 'edit', child: Text(ss.editOrderTitle)),
              if (canBlock)
                PopupMenuItem(
                  value: blocked ? 'unblock' : 'block',
                  child: Text(blocked ? ss.unblockCustomer : ss.blockCustomer),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  ss.deleteOrder,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppFonts.display(size: 25, height: 1.15)),
                    const SizedBox(height: 4),
                    Text(
                      '#${o.number} · ${TimeAgo.dayAndTime(o.createdAt, urdu: ss.isUrdu)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                o.total > 0 ? money(o.total) : '—',
                style: AppFonts.display(size: 24, color: AppColors.brand),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              SoftChip(
                label: o.source == OrderSource.link ? ss.viaLink : ss.viaCounter,
                icon: o.source == OrderSource.link
                    ? Icons.link_rounded
                    : Icons.storefront_outlined,
                background: AppColors.creamDeep,
                foreground: AppColors.inkSoft,
              ),
              SoftChip(
                label: pickup ? ss.pickup : ss.delivery,
                icon: pickup
                    ? Icons.shopping_bag_outlined
                    : Icons.delivery_dining_outlined,
                background: AppColors.creamDeep,
                foreground: AppColors.inkSoft,
              ),
              ?OrderCard.paymentChip(o, ss, money),
            ],
          ),
          const SizedBox(height: 14),
          if (o.isCancelled)
            CreamCard(
              color: AppColors.dangerSoft,
              borderColor: const Color(0xFFF2C9C9),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  const Icon(Icons.block_rounded, color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ss.orderCancelled,
                      style: const TextStyle(
                        color: Color(0xFF9E2B2B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            _StatusStepper(
              status: o.status,
              pickup: pickup,
              strings: ss,
              onTap: (s) => _setStatus(o, s),
            ),
          const SizedBox(height: 12),
          _ItemsCard(
            order: o,
            strings: ss,
            money: money,
            onEdit: o.isCancelled ? null : () => _edit(o),
          ),
          if (showPayment) ...[
            const SizedBox(height: 12),
            _PaymentCard(
              order: o,
              strings: ss,
              money: money,
              onMarkPaid: () => _markPaid(o),
              onRecord: () => _recordPayment(o),
              onClear: _clearPayments,
            ),
          ],
          const SizedBox(height: 12),
          _CustomerCard(
            order: o,
            name: name,
            strings: ss,
            onWhatsApp: () => StoreActions.messageCustomer(
              ref,
              phone: o.customer.phone,
              text: ss.msgHello(
                name: o.customer.name,
                store: ref.read(currentStoreProvider)?.name ?? '',
              ),
            ),
            onCall: () => StoreActions.callCustomer(o.customer.phone),
          ),
          if (o.answers.isNotEmpty || o.note.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            CreamCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CapsLabel(ss.details),
                  for (final a in o.answers) _labelled(a.label, a.value),
                  if (o.note.trim().isNotEmpty) _labelled(ss.noteLabel, o.note.trim()),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: _bottomBar(o, ss),
    );
  }

  Widget _labelled(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14.5, height: 1.35)),
        ],
      ),
    );
  }

  Widget _bottomBar(OrderModel o, StoreStrings ss) {
    final pickup = o.fulfillment == Fulfillment.pickup;
    final open = o.isOpen;
    final needsPrice = o.isRequest && o.total <= 0;

    Widget primary;
    switch (o.status) {
      case OrderStatus.pending:
        primary = needsPrice
            ? FilledButton(onPressed: () => _edit(o), child: Text(ss.setPrice))
            : FilledButton(
                onPressed: () => _setStatus(o, OrderStatus.confirmed),
                child: Text(ss.confirmOrder),
              );
      case OrderStatus.confirmed:
        primary = FilledButton(
          onPressed: () => _setStatus(o, OrderStatus.dispatched),
          style: FilledButton.styleFrom(backgroundColor: AppColors.dispatched),
          child: Text(pickup ? ss.markReady : ss.markDispatched),
        );
      case OrderStatus.dispatched:
        primary = FilledButton(
          onPressed: () => _setStatus(o, OrderStatus.delivered),
          child: Text(pickup ? ss.markPickedUp : ss.markDelivered),
        );
      case OrderStatus.delivered:
        primary = Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.brand),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ss.orderComplete,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () => _setStatus(o, OrderStatus.confirmed),
              child: Text(ss.reopenOrder),
            ),
          ],
        );
      case OrderStatus.cancelled:
        primary = OutlinedButton(
          onPressed: () => _setStatus(o, OrderStatus.pending),
          child: Text(ss.reopenOrder),
        );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.creamCard,
        border: Border(top: BorderSide(color: AppColors.creamBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (open && o.customer.hasPhone)
                Row(
                  children: [
                    const Icon(Icons.chat_rounded, size: 18, color: AppColors.whatsapp),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(ss.notifyBuyer, style: const TextStyle(fontSize: 13.5)),
                    ),
                    Switch(
                      value: _notify,
                      onChanged: (v) {
                        setState(() => _notify = v);
                        ref.read(preferencesServiceProvider).setNotifyBuyer(v);
                      },
                    ),
                  ],
                )
              else
                const SizedBox(height: 6),
              Row(
                children: [
                  if (open) ...[
                    TextButton(
                      onPressed: () => _cancel(o),
                      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      child: Text(ss.cancelOrder),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pending → Confirmed → Dispatched/Ready → Delivered/Picked up. Tap a step
/// to move the order there.
class _StatusStepper extends StatelessWidget {
  const _StatusStepper({
    required this.status,
    required this.pickup,
    required this.strings,
    required this.onTap,
  });

  final OrderStatus status;
  final bool pickup;
  final StoreStrings strings;
  final ValueChanged<OrderStatus> onTap;

  static const _steps = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.dispatched,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final labels = [
      strings.stepPending,
      strings.stepConfirmed,
      strings.stepDispatched(pickup),
      strings.stepDelivered(pickup),
    ];
    final current = status.step;
    return CreamCard(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _steps.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onTap(_steps[i]),
                borderRadius: BorderRadius.circular(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i == 0
                                ? Colors.transparent
                                : (i <= current ? AppColors.brand : AppColors.creamBorder),
                          ),
                        ),
                        _dot(i, current),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i == _steps.length - 1
                                ? Colors.transparent
                                : (i < current ? AppColors.brand : AppColors.creamBorder),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: i == current ? FontWeight.w600 : FontWeight.w400,
                        color: i <= current ? AppColors.ink : AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dot(int i, int current) {
    final done = i < current;
    final now = i == current;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: done || now ? AppColors.brand : AppColors.creamCard,
        shape: BoxShape.circle,
        border: Border.all(
          color: done || now ? AppColors.brand : AppColors.creamBorder,
          width: 2,
        ),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : now
              ? Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({
    required this.order,
    required this.strings,
    required this.money,
    required this.onEdit,
  });

  final OrderModel order;
  final StoreStrings strings;
  final String Function(num) money;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final o = order;
    final ss = strings;
    final orig = o.originalTotal;
    return CreamCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsLabel(
            o.items.isEmpty && o.requestText.trim().isNotEmpty
                ? ss.customerRequest
                : ss.orderItems,
            trailing: onEdit == null
                ? null
                : GestureDetector(
                    onTap: onEdit,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined, size: 15, color: AppColors.brand),
                        const SizedBox(width: 4),
                        Text(
                          ss.edit,
                          style: const TextStyle(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          if (o.requestText.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.creamDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                o.requestText.trim(),
                style: const TextStyle(fontSize: 14.5, height: 1.4),
              ),
            ),
          for (final i in o.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${i.qty}×',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i.label, style: const TextStyle(fontSize: 14.5)),
                        if (i.qty > 1)
                          Text(
                            money(i.price),
                            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                          ),
                      ],
                    ),
                  ),
                  Text(money(i.lineTotal), style: const TextStyle(fontSize: 14.5)),
                ],
              ),
            ),
          if (o.items.isNotEmpty) ...[
            const Divider(height: 18, color: AppColors.creamBorder),
            _kv(ss.subtotal, money(o.subtotal)),
            if (o.fulfillment == Fulfillment.delivery)
              _kv(ss.deliveryFeeShort, o.deliveryFee > 0 ? money(o.deliveryFee) : ss.free),
            _kv(ss.total, money(o.total), bold: true),
          ],
          if (o.amountChanged && orig != null && orig != o.total)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                ss.amountChangedFrom(money(orig)),
                style: const TextStyle(fontSize: 12, color: Color(0xFFB4650F)),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _kv(String k, String v, {bool bold = false, Color? color}) {
  final style = TextStyle(
    fontSize: bold ? 15 : 14,
    fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
    color: color ?? (bold ? AppColors.ink : AppColors.inkSoft),
  );
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(k, style: style)),
        Text(v, style: style.copyWith(color: color ?? AppColors.ink)),
      ],
    ),
  );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.order,
    required this.strings,
    required this.money,
    required this.onMarkPaid,
    required this.onRecord,
    required this.onClear,
  });

  final OrderModel order;
  final StoreStrings strings;
  final String Function(num) money;
  final VoidCallback onMarkPaid;
  final VoidCallback onRecord;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final o = order;
    final ss = strings;
    final paid = o.paymentState == PaymentState.paid;
    return CreamCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsLabel(
            ss.payment,
            trailing: o.isCancelled
                ? null
                : paid
                    ? SoftChip(
                        label: ss.paidLabel,
                        icon: Icons.check_rounded,
                        background: AppColors.brandSoft,
                        foreground: AppColors.brandDark,
                      )
                    : SoftChip(
                        label: ss.dueAmount(money(o.due)),
                        background: AppColors.pendingSoft,
                        foreground: const Color(0xFFB4650F),
                      ),
          ),
          const SizedBox(height: 10),
          _kv(ss.orderTotal, money(o.total)),
          for (final p in o.payments)
            _kv(
              '${ss.methodLabel(p.method)} · ${TimeAgo.dayAndTime(p.at, urdu: ss.isUrdu)}',
              '− ${money(p.amount)}',
              color: AppColors.brand,
            ),
          if (o.paid > 0) ...[
            const Divider(height: 18, color: AppColors.creamBorder),
            _kv(ss.dueLabel, money(o.due), bold: true),
          ],
          if (!o.isCancelled && o.due > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onMarkPaid,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(ss.markPaid),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRecord,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(ss.addPayment),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (!o.isCancelled && paid) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.verified_rounded, size: 18, color: AppColors.brand),
                const SizedBox(width: 6),
                Text(
                  ss.paidInFull,
                  style: const TextStyle(
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (o.payments.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.inkSoft,
                  textStyle: const TextStyle(fontSize: 12.5),
                ),
                child: Text(ss.clearPayments),
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.order,
    required this.name,
    required this.strings,
    required this.onWhatsApp,
    required this.onCall,
  });

  final OrderModel order;
  final String name;
  final StoreStrings strings;
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final c = order.customer;
    final ss = strings;
    return CreamCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsLabel(ss.customer),
          const SizedBox(height: 10),
          Row(
            children: [
              InitialAvatar(name: name, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      c.phone.trim().isEmpty ? ss.noPhone : c.phone.trim(),
                      style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              if (c.hasPhone) ...[
                _RoundAction(
                  icon: Icons.chat_rounded,
                  color: AppColors.whatsapp,
                  tooltip: ss.whatsapp,
                  onTap: onWhatsApp,
                ),
                const SizedBox(width: 8),
                _RoundAction(
                  icon: Icons.call_rounded,
                  color: AppColors.brand,
                  tooltip: ss.call,
                  onTap: onCall,
                ),
              ],
            ],
          ),
          if (c.address.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, size: 18, color: AppColors.inkSoft),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.address.trim(),
                    style: const TextStyle(fontSize: 14, height: 1.35),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 19, color: color),
          ),
        ),
      ),
    );
  }
}
