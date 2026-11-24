import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pocket_karcha/data/models/firestore_parse.dart';

enum OrderStatus {
  pending,
  confirmed,
  dispatched,
  delivered,
  cancelled;

  static OrderStatus fromKey(String? key) => OrderStatus.values.firstWhere(
        (s) => s.name == key,
        orElse: () => OrderStatus.pending,
      );

  /// Position on the Pending → Delivered stepper (cancelled = -1).
  int get step => switch (this) {
        OrderStatus.pending => 0,
        OrderStatus.confirmed => 1,
        OrderStatus.dispatched => 2,
        OrderStatus.delivered => 3,
        OrderStatus.cancelled => -1,
      };
}

enum Fulfillment {
  delivery,
  pickup;

  static Fulfillment fromKey(String? key) =>
      key == 'pickup' ? Fulfillment.pickup : Fulfillment.delivery;
}

enum OrderSource {
  link,
  counter;

  static OrderSource fromKey(String? key) =>
      key == 'counter' ? OrderSource.counter : OrderSource.link;
}

enum PaymentState { unpaid, partial, paid }

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    this.variant = '',
    required this.price,
    required this.qty,
  });

  final String productId;
  final String name;
  final String variant;
  final double price;
  final int qty;

  double get lineTotal => price * qty;

  /// "Fruit Chaat (Large)".
  String get label => variant.isEmpty ? name : '$name ($variant)';

  /// Same product + option → same cart line.
  String get key => '$productId|$variant|$name';

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'variant': variant,
        'price': price,
        'qty': qty,
      };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: FsParse.string(m['productId']),
        name: FsParse.string(m['name']),
        variant: FsParse.string(m['variant']),
        price: FsParse.number(m['price']),
        qty: math.max(1, FsParse.integer(m['qty'], 1)),
      );

  OrderItem copyWith({int? qty, double? price}) => OrderItem(
        productId: productId,
        name: name,
        variant: variant,
        price: price ?? this.price,
        qty: qty ?? this.qty,
      );
}

class OrderPayment {
  const OrderPayment({
    required this.amount,
    required this.at,
    this.method = 'cash',
  });

  final double amount;
  final DateTime at;

  /// `cash` · `online` · `other`.
  final String method;

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'at': Timestamp.fromDate(at),
        'method': method,
      };

  factory OrderPayment.fromMap(Map<String, dynamic> m) => OrderPayment(
        amount: FsParse.number(m['amount']),
        at: FsParse.date(m['at']) ?? DateTime.now(),
        method: FsParse.string(m['method'], 'cash'),
      );
}

class OrderAnswer {
  const OrderAnswer({required this.label, required this.value});

  final String label;
  final String value;

  Map<String, dynamic> toMap() => {'label': label, 'value': value};

  factory OrderAnswer.fromMap(Map<String, dynamic> m) => OrderAnswer(
        label: FsParse.string(m['label']),
        value: FsParse.string(m['value']),
      );
}

class OrderCustomer {
  const OrderCustomer({this.name = '', this.phone = '', this.address = ''});

  final String name;
  final String phone;
  final String address;

  bool get hasPhone => phone.replaceAll(RegExp(r'\D'), '').length >= 7;

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'address': address,
      };

  factory OrderCustomer.fromMap(Map<String, dynamic> m) => OrderCustomer(
        name: FsParse.string(m['name']),
        phone: FsParse.string(m['phone']),
        address: FsParse.string(m['address']),
      );

  OrderCustomer copyWith({String? name, String? phone, String? address}) =>
      OrderCustomer(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
      );
}

/// `stores/{ownerUid}/orders/{id}` — from the store link or a counter sale.
class OrderModel {
  const OrderModel({
    required this.id,
    required this.number,
    this.source = OrderSource.link,
    this.status = OrderStatus.pending,
    this.fulfillment = Fulfillment.delivery,
    this.customer = const OrderCustomer(),
    this.items = const [],
    this.requestText = '',
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.total = 0,
    this.paid = 0,
    this.payments = const [],
    this.note = '',
    this.answers = const [],
    this.amountChanged = false,
    this.originalTotal,
    this.buyerUid = '',
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String number;
  final OrderSource source;
  final OrderStatus status;
  final Fulfillment fulfillment;
  final OrderCustomer customer;
  final List<OrderItem> items;
  final String requestText;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final double paid;
  final List<OrderPayment> payments;
  final String note;
  final List<OrderAnswer> answers;
  final bool amountChanged;
  final double? originalTotal;

  /// Anonymous uid of the buyer who sent this from the order page ('' for
  /// counter orders). Used to block a buyer.
  final String buyerUid;
  final DateTime createdAt;
  final DateTime? updatedAt;

  int get itemCount => items.fold(0, (acc, i) => acc + i.qty);

  bool get isRequest => items.isEmpty && requestText.trim().isNotEmpty;

  bool get isCancelled => status == OrderStatus.cancelled;

  bool get isOpen =>
      status != OrderStatus.delivered && status != OrderStatus.cancelled;

  double get due => isCancelled ? 0 : math.max(0, total - paid);

  PaymentState get paymentState {
    if (total > 0 && paid >= total) return PaymentState.paid;
    if (paid > 0) return PaymentState.partial;
    return PaymentState.unpaid;
  }

  bool get isUnpaid => !isCancelled && due > 0;

  String get displayName {
    final n = customer.name.trim();
    if (n.isNotEmpty) return n;
    if (customer.phone.trim().isNotEmpty) return customer.phone.trim();
    return '';
  }

  /// Totals recomputed from items (used after editing lines).
  static ({double subtotal, double total}) totalsFor(
    List<OrderItem> items,
    double deliveryFee,
  ) {
    final subtotal = items.fold<double>(0, (s, i) => s + i.lineTotal);
    return (subtotal: subtotal, total: subtotal + deliveryFee);
  }

  /// 6-digit display code, e.g. "160768".
  static String newNumber() {
    final r = math.Random();
    return (100000 + r.nextInt(900000)).toString();
  }

  Map<String, dynamic> toMap() => {
        'number': number,
        'source': source.name,
        'status': status.name,
        'fulfillment': fulfillment.name,
        'customer': customer.toMap(),
        'items': items.map((i) => i.toMap()).toList(),
        'itemCount': itemCount,
        'requestText': requestText,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'paid': paid,
        'payments': payments.map((p) => p.toMap()).toList(),
        'note': note,
        'answers': answers.map((a) => a.toMap()).toList(),
        'amountChanged': amountChanged,
        if (originalTotal != null) 'originalTotal': originalTotal,
        if (buyerUid.isNotEmpty) 'buyerUid': buyerUid,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.now(),
      };

  factory OrderModel.fromMap(String id, Map<String, dynamic> m) {
    final orig = m['originalTotal'];
    return OrderModel(
      id: id,
      number: FsParse.string(m['number'], id.substring(0, math.min(6, id.length))),
      source: OrderSource.fromKey(m['source'] as String?),
      status: OrderStatus.fromKey(m['status'] as String?),
      fulfillment: Fulfillment.fromKey(m['fulfillment'] as String?),
      customer: OrderCustomer.fromMap(FsParse.map(m['customer'])),
      items: FsParse.mapList(m['items']).map(OrderItem.fromMap).toList(),
      requestText: FsParse.string(m['requestText']),
      subtotal: FsParse.number(m['subtotal']),
      deliveryFee: FsParse.number(m['deliveryFee']),
      total: FsParse.number(m['total']),
      paid: FsParse.number(m['paid']),
      payments:
          FsParse.mapList(m['payments']).map(OrderPayment.fromMap).toList(),
      note: FsParse.string(m['note']),
      answers: FsParse.mapList(m['answers'])
          .map(OrderAnswer.fromMap)
          .where((a) => a.value.trim().isNotEmpty)
          .toList(),
      amountChanged: FsParse.boolean(m['amountChanged']),
      originalTotal: orig == null ? null : FsParse.number(orig),
      buyerUid: FsParse.string(m['buyerUid']),
      createdAt: FsParse.date(m['createdAt']) ?? DateTime.now(),
      updatedAt: FsParse.date(m['updatedAt']),
    );
  }

  OrderModel copyWith({
    OrderStatus? status,
    Fulfillment? fulfillment,
    OrderCustomer? customer,
    List<OrderItem>? items,
    String? requestText,
    double? subtotal,
    double? deliveryFee,
    double? total,
    double? paid,
    List<OrderPayment>? payments,
    String? note,
    bool? amountChanged,
    double? originalTotal,
  }) {
    return OrderModel(
      id: id,
      number: number,
      source: source,
      status: status ?? this.status,
      fulfillment: fulfillment ?? this.fulfillment,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      requestText: requestText ?? this.requestText,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      payments: payments ?? this.payments,
      note: note ?? this.note,
      answers: answers,
      amountChanged: amountChanged ?? this.amountChanged,
      originalTotal: originalTotal ?? this.originalTotal,
      buyerUid: buyerUid,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// A buyer, built from their orders (grouped by phone, else name).
class CustomerSummary {
  const CustomerSummary({
    required this.key,
    required this.name,
    required this.phone,
    required this.orders,
  });

  final String key;
  final String name;
  final String phone;

  /// Newest first.
  final List<OrderModel> orders;

  List<OrderModel> get _active => orders.where((o) => !o.isCancelled).toList();

  int get orderCount => _active.length;

  double get total => _active.fold(0, (s, o) => s + o.total);

  double get due => _active.fold(0, (s, o) => s + o.due);

  DateTime get lastOrderAt => orders.first.createdAt;

  String get address => orders
      .map((o) => o.customer.address.trim())
      .firstWhere((a) => a.isNotEmpty, orElse: () => '');
}
