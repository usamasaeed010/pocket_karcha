import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pocket_karcha/data/models/firestore_parse.dart';

/// A size / option with its own price (e.g. Small, Large).
class ProductVariant {
  const ProductVariant({required this.name, required this.price});

  final String name;
  final double price;

  Map<String, dynamic> toMap() => {'name': name, 'price': price};

  factory ProductVariant.fromMap(Map<String, dynamic> m) => ProductVariant(
        name: FsParse.string(m['name']),
        price: FsParse.number(m['price']),
      );

  ProductVariant copyWith({String? name, double? price}) =>
      ProductVariant(name: name ?? this.name, price: price ?? this.price);
}

/// Catalogue item — `stores/{ownerUid}/products/{id}`.
class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    this.price = 0,
    this.description = '',
    this.category = '',
    this.inStock = true,
    this.sortOrder = 0,
    this.variants = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final double price;
  final String description;
  final String category;
  final bool inStock;
  final int sortOrder;
  final List<ProductVariant> variants;
  final DateTime? createdAt;

  bool get hasVariants => variants.isNotEmpty;

  /// Lowest price — "from Rs X" when the item has options.
  double get displayPrice =>
      hasVariants ? variants.map((v) => v.price).reduce(math.min) : price;

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': hasVariants ? displayPrice : price,
        'description': description,
        'category': category,
        'inStock': inStock,
        'sortOrder': sortOrder,
        'variants': variants.map((v) => v.toMap()).toList(),
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

  factory ProductModel.fromMap(String id, Map<String, dynamic> m) {
    return ProductModel(
      id: id,
      name: FsParse.string(m['name']),
      price: FsParse.number(m['price']),
      description: FsParse.string(m['description']),
      category: FsParse.string(m['category']),
      inStock: FsParse.boolean(m['inStock'], true),
      sortOrder: FsParse.integer(m['sortOrder']),
      variants: FsParse.mapList(m['variants'])
          .map(ProductVariant.fromMap)
          .where((v) => v.name.trim().isNotEmpty)
          .toList(),
      createdAt: FsParse.date(m['createdAt']),
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? category,
    bool? inStock,
    int? sortOrder,
    List<ProductVariant>? variants,
    bool resetCreatedAt = false,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      inStock: inStock ?? this.inStock,
      sortOrder: sortOrder ?? this.sortOrder,
      variants: variants ?? this.variants,
      createdAt: resetCreatedAt ? null : createdAt,
    );
  }
}
