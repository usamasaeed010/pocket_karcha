import 'package:pocket_karcha/core/utils/phone_parser.dart';

class PersonModel {
  const PersonModel({
    required this.id,
    required this.name,
    this.countryCode = 'PK',
    this.dialCode = '+92',
    this.phoneLocal = '',
  });

  final String id;
  final String name;
  final String countryCode;
  final String dialCode;
  final String phoneLocal;

  String get displayPhone =>
      phoneLocal.isEmpty ? '' : '$dialCode $phoneLocal';

  String get fullPhone =>
      phoneLocal.isEmpty ? '' : '$dialCode$phoneLocal';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'countryCode': countryCode,
        'dialCode': dialCode,
        'phoneLocal': phoneLocal,
      };

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    final legacyPhone = json['phone'] as String?;
    final parsed = PhoneParser.parse(legacyPhone);

    return PersonModel(
      id: json['id'] as String,
      name: json['name'] as String,
      countryCode: json['countryCode'] as String? ?? parsed.countryCode,
      dialCode: json['dialCode'] as String? ?? parsed.dialCode,
      phoneLocal: json['phoneLocal'] as String? ?? parsed.localNumber,
    );
  }

  PersonModel copyWith({
    String? name,
    String? countryCode,
    String? dialCode,
    String? phoneLocal,
  }) {
    return PersonModel(
      id: id,
      name: name ?? this.name,
      countryCode: countryCode ?? this.countryCode,
      dialCode: dialCode ?? this.dialCode,
      phoneLocal: phoneLocal ?? this.phoneLocal,
    );
  }
}

/// Lena-dena totals with one person.
class PersonLedger {
  const PersonLedger({
    this.gave = 0,
    this.got = 0,
    this.entries = 0,
    this.lastActivity,
  });

  /// Money (or goods on credit) you gave them.
  final double gave;

  /// Money they gave you (paid back, advance, payment).
  final double got;

  final int entries;
  final DateTime? lastActivity;

  /// Positive: they will give you (lena hai).
  /// Negative: you will give them (dena hai).
  double get net => gave - got;

  bool get hasActivity => entries > 0;
  bool get isSettled => net.abs() < 0.005;
}
