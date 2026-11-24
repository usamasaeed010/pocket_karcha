import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_currencies.dart';
import 'package:pocket_karcha/core/utils/money.dart';
import 'package:pocket_karcha/data/models/blocked_customer.dart';
import 'package:pocket_karcha/data/models/order_model.dart';
import 'package:pocket_karcha/data/models/product_model.dart';
import 'package:pocket_karcha/data/models/store_model.dart';
import 'package:pocket_karcha/data/repositories/store_repository.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/services/firebase_service.dart';

final storeRepositoryProvider = Provider<StoreRepository?>((ref) {
  if (!FirebaseService.isReady) return null;
  return StoreRepository(FirebaseFirestore.instance);
});

/// The store id is the signed-in owner's uid.
final storeOwnerIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserIdProvider);
});

final storeProvider = StreamProvider<StoreModel?>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  final uid = ref.watch(storeOwnerIdProvider);
  if (repo == null || uid == null) return Stream.value(null);
  return repo.watchStore(uid);
});

final productsProvider = StreamProvider<List<ProductModel>>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  final uid = ref.watch(storeOwnerIdProvider);
  if (repo == null || uid == null) return Stream.value(const []);
  return repo.watchProducts(uid);
});

final ordersProvider = StreamProvider<List<OrderModel>>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  final uid = ref.watch(storeOwnerIdProvider);
  if (repo == null || uid == null) return Stream.value(const []);
  return repo.watchOrders(uid);
});

final storeStatsProvider = StreamProvider<StoreStats>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  final uid = ref.watch(storeOwnerIdProvider);
  if (repo == null || uid == null) return Stream.value(const StoreStats());
  return repo.watchStats(uid);
});

final blockedEntriesProvider = StreamProvider<List<BlockedEntry>>((ref) {
  final repo = ref.watch(storeRepositoryProvider);
  final uid = ref.watch(storeOwnerIdProvider);
  if (repo == null || uid == null) return Stream.value(const []);
  return repo.watchBlocked(uid);
});

/// Customers whose link orders firestore.rules refuses, newest first.
final blockedCustomersProvider = Provider<List<BlockedCustomer>>((ref) {
  final entries = ref.watch(blockedEntriesProvider).valueOrNull ?? const [];
  return BlockedCustomer.fromEntries(entries);
});

/// Every blocked key (phone forms and buyer uids).
final blockedKeysProvider = Provider<Set<String>>((ref) {
  final entries = ref.watch(blockedEntriesProvider).valueOrNull ?? const [];
  return {for (final e in entries) e.key};
});

final currentStoreProvider = Provider<StoreModel?>((ref) {
  return ref.watch(storeProvider).valueOrNull;
});

final productListProvider = Provider<List<ProductModel>>((ref) {
  return ref.watch(productsProvider).valueOrNull ?? const [];
});

final orderListProvider = Provider<List<OrderModel>>((ref) {
  return ref.watch(ordersProvider).valueOrNull ?? const [];
});

/// `Rs 1,700` using the store's currency symbol.
final moneyProvider = Provider<String Function(num)>((ref) {
  final symbol = ref.watch(currencySymbolProvider);
  return (num v) => formatMoney(v, symbol);
});

/// The store's currency symbol, e.g. `Rs`.
final currencySymbolProvider = Provider<String>((ref) {
  final store = ref.watch(currentStoreProvider);
  return store?.currencySymbol ??
      AppCurrencies.byCode(ref.watch(selectedCurrencyProvider)).symbol;
});

// ── Shell tabs ─────────────────────────────────────────────────────────────

abstract final class StoreTabs {
  static const home = 0;
  static const orders = 1;
  static const products = 2;
  static const khata = 3;
  static const settings = 4;
}

final storeTabProvider = StateProvider<int>((ref) => StoreTabs.home);

/// Set by store setup; the shell shows the "store is live" sheet once.
final storeJustCreatedProvider = StateProvider<bool>((ref) => false);

// ── Home numbers ───────────────────────────────────────────────────────────

class OrderKpis {
  const OrderKpis({
    this.toConfirm = 0,
    this.toDispatch = 0,
    this.toCollect = 0,
  });

  final int toConfirm;
  final int toDispatch;
  final double toCollect;
}

final orderKpisProvider = Provider<OrderKpis>((ref) {
  final orders = ref.watch(orderListProvider);
  var confirm = 0;
  var dispatch = 0;
  double collect = 0;
  for (final o in orders) {
    if (o.status == OrderStatus.pending) confirm++;
    if (o.status == OrderStatus.confirmed) dispatch++;
    collect += o.due;
  }
  return OrderKpis(toConfirm: confirm, toDispatch: dispatch, toCollect: collect);
});

// ── Orders list: filter + search ──────────────────────────────────────────

enum OrderFilter { all, unpaid, pending, confirmed, dispatched, delivered, cancelled }

extension OrderFilterX on OrderFilter {
  bool matches(OrderModel o) => switch (this) {
        OrderFilter.all => true,
        OrderFilter.unpaid => o.isUnpaid,
        OrderFilter.pending => o.status == OrderStatus.pending,
        OrderFilter.confirmed => o.status == OrderStatus.confirmed,
        OrderFilter.dispatched => o.status == OrderStatus.dispatched,
        OrderFilter.delivered => o.status == OrderStatus.delivered,
        OrderFilter.cancelled => o.status == OrderStatus.cancelled,
      };
}

final orderFilterProvider = StateProvider<OrderFilter>((ref) => OrderFilter.all);
final orderSearchProvider = StateProvider<String>((ref) => '');

/// 0 = Orders, 1 = Customers.
final ordersSegmentProvider = StateProvider<int>((ref) => 0);

final orderFilterCountsProvider = Provider<Map<OrderFilter, int>>((ref) {
  final orders = ref.watch(orderListProvider);
  return {
    for (final f in OrderFilter.values)
      f: orders.where((o) => f.matches(o)).length,
  };
});

bool _orderMatchesQuery(OrderModel o, String q) {
  if (q.isEmpty) return true;
  final digits = q.replaceAll(RegExp(r'\D'), '');
  if (o.customer.name.toLowerCase().contains(q)) return true;
  if (o.number.contains(q.replaceAll('#', ''))) return true;
  if (digits.length >= 3 &&
      o.customer.phone.replaceAll(RegExp(r'\D'), '').contains(digits)) {
    return true;
  }
  return o.items.any((i) => i.name.toLowerCase().contains(q));
}

final filteredOrdersProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(orderListProvider);
  final filter = ref.watch(orderFilterProvider);
  final q = ref.watch(orderSearchProvider).trim().toLowerCase();
  return orders
      .where((o) => filter.matches(o) && _orderMatchesQuery(o, q))
      .toList();
});

// ── Customers (built from orders) ─────────────────────────────────────────

String customerKeyFor(OrderCustomer c) {
  final digits = c.phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 7) {
    return 'p:${digits.length > 10 ? digits.substring(digits.length - 10) : digits}';
  }
  final name = c.name.trim().toLowerCase();
  return name.isEmpty ? '' : 'n:$name';
}

final customersProvider = Provider<List<CustomerSummary>>((ref) {
  final orders = ref.watch(orderListProvider);
  final groups = <String, List<OrderModel>>{};
  for (final o in orders) {
    final key = customerKeyFor(o.customer);
    if (key.isEmpty) continue;
    groups.putIfAbsent(key, () => []).add(o);
  }
  final list = groups.entries.map((e) {
    final named = e.value.firstWhere(
      (o) => o.customer.name.trim().isNotEmpty,
      orElse: () => e.value.first,
    );
    final phoned = e.value.firstWhere(
      (o) => o.customer.phone.trim().isNotEmpty,
      orElse: () => e.value.first,
    );
    return CustomerSummary(
      key: e.key,
      name: named.customer.name.trim(),
      phone: phoned.customer.phone.trim(),
      orders: e.value,
    );
  }).toList()
    ..sort((a, b) => b.lastOrderAt.compareTo(a.lastOrderAt));
  return list;
});


final filteredCustomersProvider = Provider<List<CustomerSummary>>((ref) {
  final list = ref.watch(customersProvider);
  final q = ref.watch(orderSearchProvider).trim().toLowerCase();
  if (q.isEmpty) return list;
  final digits = q.replaceAll(RegExp(r'\D'), '');
  return list.where((c) {
    if (c.name.toLowerCase().contains(q)) return true;
    return digits.length >= 3 &&
        c.phone.replaceAll(RegExp(r'\D'), '').contains(digits);
  }).toList();
});

final productSearchProvider = StateProvider<String>((ref) => '');

/// Existing categories, for suggestions in the product form.
final productCategoriesProvider = Provider<List<String>>((ref) {
  final set = <String>{};
  for (final p in ref.watch(productListProvider)) {
    final c = p.category.trim();
    if (c.isNotEmpty) set.add(c);
  }
  return set.toList()..sort();
});
