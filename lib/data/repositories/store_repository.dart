import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pocket_karcha/data/models/blocked_customer.dart';
import 'package:pocket_karcha/data/models/order_model.dart';
import 'package:pocket_karcha/data/models/product_model.dart';
import 'package:pocket_karcha/data/models/store_model.dart';

enum SlugStatus { available, yours, taken }

/// Firestore access for the order app:
/// `stores/{uid}` · `stores/{uid}/products` · `stores/{uid}/orders` ·
/// `stores/{uid}/blocked` · `slugs/{slug}` · `storeStats/{uid}`.
class StoreRepository {
  StoreRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _store(String uid) =>
      _db.collection('stores').doc(uid);

  CollectionReference<Map<String, dynamic>> _products(String uid) =>
      _store(uid).collection('products');

  CollectionReference<Map<String, dynamic>> _orders(String uid) =>
      _store(uid).collection('orders');

  CollectionReference<Map<String, dynamic>> _blocked(String uid) =>
      _store(uid).collection('blocked');

  DocumentReference<Map<String, dynamic>> _slug(String slug) =>
      _db.collection('slugs').doc(slug);

  DocumentReference<Map<String, dynamic>> _stats(String uid) =>
      _db.collection('storeStats').doc(uid);

  // ── Store ──────────────────────────────────────────────────────────────

  Stream<StoreModel?> watchStore(String uid) {
    return _store(uid).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return StoreModel.fromMap(snap.id, data);
    });
  }

  /// [serverOnly] skips the offline cache (throws when offline).
  Future<StoreModel?> fetchStore(String uid, {bool serverOnly = false}) async {
    final snap = await _store(uid)
        .get(serverOnly ? const GetOptions(source: Source.server) : null);
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return StoreModel.fromMap(snap.id, data);
  }

  Future<SlugStatus> checkSlug(String slug, {required String uid}) async {
    final snap = await _slug(slug).get(const GetOptions(source: Source.server));
    if (!snap.exists) return SlugStatus.available;
    return snap.data()?['storeId'] == uid ? SlugStatus.yours : SlugStatus.taken;
  }

  /// Store + link + stats + starter products in one atomic write.
  Future<void> createStore(
    StoreModel store,
    List<ProductModel> starter, {
    bool slugAlreadyYours = false,
  }) async {
    final batch = _db.batch();
    batch.set(_store(store.id), store.toMap());
    if (!slugAlreadyYours) {
      batch.set(_slug(store.slug), {
        'storeId': store.id,
        'createdAt': Timestamp.now(),
      });
    }
    batch.set(_stats(store.id), {'opens': 0, 'carts': 0, 'sent': 0});
    for (var i = 0; i < starter.length; i++) {
      batch.set(
        _products(store.id).doc(),
        starter[i].copyWith(sortOrder: i).toMap(),
      );
    }
    await batch.commit();
  }

  Future<void> updateStore(String uid, Map<String, dynamic> data) {
    return _store(uid).update({...data, 'updatedAt': Timestamp.now()});
  }

  Future<void> changeSlug({
    required String uid,
    required String oldSlug,
    required String newSlug,
  }) async {
    final batch = _db.batch();
    batch.set(_slug(newSlug), {'storeId': uid, 'createdAt': Timestamp.now()});
    batch.update(_store(uid), {'slug': newSlug, 'updatedAt': Timestamp.now()});
    if (oldSlug.isNotEmpty && oldSlug != newSlug) {
      batch.delete(_slug(oldSlug));
    }
    await batch.commit();
  }

  /// Account deletion: take the page offline and free the link.
  Future<void> closeStore(String uid, String slug) async {
    final batch = _db.batch();
    // `deleted: true` makes the public page show "Store not found".
    batch.update(_store(uid), {
      'isLive': false,
      'closed': true,
      'deleted': true,
      'updatedAt': Timestamp.now(),
    });
    if (slug.isNotEmpty) batch.delete(_slug(slug));
    await batch.commit();
  }

  Stream<StoreStats> watchStats(String uid) {
    return _stats(uid)
        .snapshots()
        .map((snap) => StoreStats.fromMap(snap.data() ?? const {}));
  }

  // ── Products ───────────────────────────────────────────────────────────

  Stream<List<ProductModel>> watchProducts(String uid) {
    return _products(uid).orderBy('sortOrder').snapshots().map(
          (snap) => snap.docs
              .map((d) => ProductModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  String newProductId(String uid) => _products(uid).doc().id;

  Future<void> saveProduct(String uid, ProductModel product) {
    final id = product.id.isEmpty ? newProductId(uid) : product.id;
    return _products(uid).doc(id).set(product.copyWith(id: id).toMap());
  }

  Future<void> addProducts(
    String uid,
    List<ProductModel> items, {
    int startOrder = 0,
  }) async {
    final batch = _db.batch();
    for (var i = 0; i < items.length; i++) {
      batch.set(
        _products(uid).doc(),
        items[i].copyWith(sortOrder: startOrder + i).toMap(),
      );
    }
    await batch.commit();
  }

  Future<void> deleteProduct(String uid, String id) =>
      _products(uid).doc(id).delete();

  Future<void> setInStock(String uid, String id, bool inStock) =>
      _products(uid).doc(id).update({
        'inStock': inStock,
        'updatedAt': Timestamp.now(),
      });

  Future<void> updatePrice(String uid, String id, double price) =>
      _products(uid).doc(id).update({
        'price': price,
        'updatedAt': Timestamp.now(),
      });

  /// Writes the new order of the list (after drag to reorder).
  Future<void> saveSortOrder(String uid, List<ProductModel> ordered) async {
    final batch = _db.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update(_products(uid).doc(ordered[i].id), {'sortOrder': i});
    }
    await batch.commit();
  }

  /// Price + option prices for many items (Edit prices / Change all prices).
  Future<void> savePrices(String uid, List<ProductModel> updated) async {
    final batch = _db.batch();
    for (final p in updated) {
      batch.update(_products(uid).doc(p.id), {
        'price': p.hasVariants ? p.displayPrice : p.price,
        'variants': p.variants.map((v) => v.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }

  // ── Orders ─────────────────────────────────────────────────────────────

  Stream<List<OrderModel>> watchOrders(String uid) {
    return _orders(uid)
        .orderBy('createdAt', descending: true)
        .limit(1500)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => OrderModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  String newOrderId(String uid) => _orders(uid).doc().id;

  Future<void> saveOrder(String uid, OrderModel order) =>
      _orders(uid).doc(order.id).set(order.toMap());

  Future<void> updateOrder(
    String uid,
    String orderId,
    Map<String, dynamic> data,
  ) {
    return _orders(uid)
        .doc(orderId)
        .update({...data, 'updatedAt': Timestamp.now()});
  }

  Future<void> deleteOrder(String uid, String orderId) =>
      _orders(uid).doc(orderId).delete();

  // ── Blocked customers ──────────────────────────────────────────────────

  Stream<List<BlockedEntry>> watchBlocked(String uid) {
    return _blocked(uid).snapshots().map(
          (snap) => snap.docs
              .map((d) => BlockedEntry.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// Writes every key of one block; they share [group] and unblock together.
  Future<void> block(
    String uid, {
    required Set<String> keys,
    required String group,
    String name = '',
    String phone = '',
  }) {
    final batch = _db.batch();
    final data = {
      'group': group,
      'name': name,
      'phone': phone,
      'createdAt': Timestamp.now(),
    };
    for (final key in keys) {
      batch.set(_blocked(uid).doc(key), data);
    }
    return batch.commit();
  }

  Future<void> unblock(String uid, Iterable<String> keys) {
    final batch = _db.batch();
    for (final key in keys) {
      batch.delete(_blocked(uid).doc(key));
    }
    return batch.commit();
  }
}
