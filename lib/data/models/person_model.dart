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

class PersonLedger {
  const PersonLedger({
    this.credit = 0,
    this.debit = 0,
  });

  final double credit;
  final double debit;

  double get balance => credit - debit;

  bool get hasActivity => credit > 0 || debit > 0;
}
