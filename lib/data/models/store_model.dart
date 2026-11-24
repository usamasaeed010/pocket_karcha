import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pocket_karcha/data/models/firestore_parse.dart';

/// How customers send an order from the store link.
enum OrderMode {
  /// Pick items into a cart with quantities and totals.
  cart,

  /// Write a free-text request (no cart).
  request;

  static OrderMode fromKey(String? key) =>
      key == 'request' ? OrderMode.request : OrderMode.cart;
}

/// An extra question asked on the order form (e.g. "Preferred time").
class CustomField {
  const CustomField({
    required this.id,
    required this.label,
    this.required = false,
  });

  final String id;
  final String label;
  final bool required;

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'required': required,
      };

  factory CustomField.fromMap(Map<String, dynamic> m) => CustomField(
        id: FsParse.string(m['id']),
        label: FsParse.string(m['label']),
        required: FsParse.boolean(m['required']),
      );

  CustomField copyWith({String? label, bool? required}) => CustomField(
        id: id,
        label: label ?? this.label,
        required: required ?? this.required,
      );
}

/// Public store document — `stores/{ownerUid}`. Everything here is visible
/// on the customer page, so never put private data in it.
class StoreModel {
  const StoreModel({
    required this.id,
    required this.name,
    required this.slug,
    this.about = '',
    this.whatsapp = '',
    this.dialCode = '+92',
    this.countryCode = 'PK',
    this.currency = 'PKR',
    this.currencySymbol = 'Rs',
    this.businessType = 'other',
    this.isLive = true,
    this.pausedMessage = '',
    this.orderMode = OrderMode.cart,
    this.deliveryEnabled = true,
    this.deliveryFee = 0,
    this.freeDeliveryAbove = 0,
    this.deliveryArea = '',
    this.pickupEnabled = true,
    this.pickupAddress = '',
    this.minOrder = 0,
    this.askNote = true,
    this.customFields = const [],
    this.pageLanguage = 'en',
    this.createdAt,
  });

  final String id;
  final String name;
  final String slug;
  final String about;

  /// International digits without '+', e.g. `923001234567`.
  final String whatsapp;
  final String dialCode;
  final String countryCode;
  final String currency;
  final String currencySymbol;
  final String businessType;
  final bool isLive;
  final String pausedMessage;
  final OrderMode orderMode;
  final bool deliveryEnabled;
  final double deliveryFee;
  final double freeDeliveryAbove;
  final String deliveryArea;
  final bool pickupEnabled;
  final String pickupAddress;
  final double minOrder;
  final bool askNote;
  final List<CustomField> customFields;
  final String pageLanguage;
  final DateTime? createdAt;

  /// Number shown to people, e.g. `+92 300 1234567`.
  String get whatsappDisplay {
    if (whatsapp.isEmpty) return '';
    final dial = dialCode.replaceAll(RegExp(r'\D'), '');
    if (dial.isNotEmpty && whatsapp.startsWith(dial)) {
      final local = whatsapp.substring(dial.length);
      if (local.length > 3) {
        return '+$dial ${local.substring(0, 3)} ${local.substring(3)}';
      }
      return '+$dial $local';
    }
    return '+$whatsapp';
  }

  /// Delivery fee for a cart subtotal (free above the threshold).
  double deliveryFeeFor(double subtotal) {
    if (!deliveryEnabled) return 0;
    if (freeDeliveryAbove > 0 && subtotal >= freeDeliveryAbove) return 0;
    return deliveryFee;
  }

  Map<String, dynamic> toMap() => {
        'ownerUid': id,
        'name': name,
        'slug': slug,
        'about': about,
        'whatsapp': whatsapp,
        'dialCode': dialCode,
        'countryCode': countryCode,
        'currency': currency,
        'currencySymbol': currencySymbol,
        'businessType': businessType,
        'isLive': isLive,
        'pausedMessage': pausedMessage,
        'orderMode': orderMode.name,
        'deliveryEnabled': deliveryEnabled,
        'deliveryFee': deliveryFee,
        'freeDeliveryAbove': freeDeliveryAbove,
        'deliveryArea': deliveryArea,
        'pickupEnabled': pickupEnabled,
        'pickupAddress': pickupAddress,
        'minOrder': minOrder,
        'askNote': askNote,
        'customFields': customFields.map((f) => f.toMap()).toList(),
        'pageLanguage': pageLanguage,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

  /// Only the order-form settings — used by the Order settings screen.
  Map<String, dynamic> orderSettingsMap() => {
        'orderMode': orderMode.name,
        'deliveryEnabled': deliveryEnabled,
        'deliveryFee': deliveryFee,
        'freeDeliveryAbove': freeDeliveryAbove,
        'deliveryArea': deliveryArea,
        'pickupEnabled': pickupEnabled,
        'pickupAddress': pickupAddress,
        'minOrder': minOrder,
        'askNote': askNote,
        'customFields': customFields.map((f) => f.toMap()).toList(),
        'pageLanguage': pageLanguage,
        'pausedMessage': pausedMessage,
        'updatedAt': Timestamp.now(),
      };

  factory StoreModel.fromMap(String id, Map<String, dynamic> m) {
    return StoreModel(
      id: id,
      name: FsParse.string(m['name']),
      slug: FsParse.string(m['slug']),
      about: FsParse.string(m['about']),
      whatsapp: FsParse.string(m['whatsapp']),
      dialCode: FsParse.string(m['dialCode'], '+92'),
      countryCode: FsParse.string(m['countryCode'], 'PK'),
      currency: FsParse.string(m['currency'], 'PKR'),
      currencySymbol: FsParse.string(m['currencySymbol'], 'Rs'),
      businessType: FsParse.string(m['businessType'], 'other'),
      isLive: FsParse.boolean(m['isLive'], true),
      pausedMessage: FsParse.string(m['pausedMessage']),
      orderMode: OrderMode.fromKey(m['orderMode'] as String?),
      deliveryEnabled: FsParse.boolean(m['deliveryEnabled'], true),
      deliveryFee: FsParse.number(m['deliveryFee']),
      freeDeliveryAbove: FsParse.number(m['freeDeliveryAbove']),
      deliveryArea: FsParse.string(m['deliveryArea']),
      pickupEnabled: FsParse.boolean(m['pickupEnabled'], true),
      pickupAddress: FsParse.string(m['pickupAddress']),
      minOrder: FsParse.number(m['minOrder']),
      askNote: FsParse.boolean(m['askNote'], true),
      customFields: FsParse.mapList(m['customFields'])
          .map(CustomField.fromMap)
          .where((f) => f.label.trim().isNotEmpty)
          .toList(),
      pageLanguage: FsParse.string(m['pageLanguage'], 'en'),
      createdAt: FsParse.date(m['createdAt']),
    );
  }

  StoreModel copyWith({
    String? name,
    String? slug,
    String? about,
    String? whatsapp,
    String? dialCode,
    String? countryCode,
    String? currency,
    String? currencySymbol,
    String? businessType,
    bool? isLive,
    String? pausedMessage,
    OrderMode? orderMode,
    bool? deliveryEnabled,
    double? deliveryFee,
    double? freeDeliveryAbove,
    String? deliveryArea,
    bool? pickupEnabled,
    String? pickupAddress,
    double? minOrder,
    bool? askNote,
    List<CustomField>? customFields,
    String? pageLanguage,
  }) {
    return StoreModel(
      id: id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      about: about ?? this.about,
      whatsapp: whatsapp ?? this.whatsapp,
      dialCode: dialCode ?? this.dialCode,
      countryCode: countryCode ?? this.countryCode,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      businessType: businessType ?? this.businessType,
      isLive: isLive ?? this.isLive,
      pausedMessage: pausedMessage ?? this.pausedMessage,
      orderMode: orderMode ?? this.orderMode,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      freeDeliveryAbove: freeDeliveryAbove ?? this.freeDeliveryAbove,
      deliveryArea: deliveryArea ?? this.deliveryArea,
      pickupEnabled: pickupEnabled ?? this.pickupEnabled,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      minOrder: minOrder ?? this.minOrder,
      askNote: askNote ?? this.askNote,
      customFields: customFields ?? this.customFields,
      pageLanguage: pageLanguage ?? this.pageLanguage,
      createdAt: createdAt,
    );
  }
}

/// Link analytics — `storeStats/{ownerUid}`, bumped by the customer page.
class StoreStats {
  const StoreStats({this.opens = 0, this.carts = 0, this.sent = 0});

  final int opens;
  final int carts;
  final int sent;

  factory StoreStats.fromMap(Map<String, dynamic> m) => StoreStats(
        opens: FsParse.integer(m['opens']),
        carts: FsParse.integer(m['carts']),
        sent: FsParse.integer(m['sent']),
      );
}
