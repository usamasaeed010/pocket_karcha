class UserProfileModel {
  const UserProfileModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phone,
    this.countryCode = 'PK',
    this.dialCode = '+92',
    this.currency = 'PKR',
    this.locale = 'en',
    this.profileComplete = false,
    this.isDisabled = false,
    this.avatarUrl,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? phone;
  final String countryCode;
  final String dialCode;
  final String currency;
  final String locale;
  final bool profileComplete;
  final bool isDisabled;
  final String? avatarUrl;

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName ?? '',
        'phone': phone ?? '',
        'countryCode': countryCode,
        'dialCode': dialCode,
        'currency': currency,
        'locale': locale,
        'profileComplete': profileComplete,
        'isDisabled': isDisabled,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'updatedAt': DateTime.now().toIso8601String(),
        if (!profileComplete) 'createdAt': DateTime.now().toIso8601String(),
      };

  factory UserProfileModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfileModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      phone: map['phone'] as String?,
      countryCode: map['countryCode'] as String? ?? 'PK',
      dialCode: map['dialCode'] as String? ?? '+92',
      currency: map['currency'] as String? ?? 'PKR',
      locale: map['locale'] as String? ?? 'en',
      profileComplete: map['profileComplete'] as bool? ?? false,
      isDisabled: map['isDisabled'] as bool? ?? false,
      avatarUrl: map['avatarUrl'] as String?,
    );
  }

  UserProfileModel copyWith({
    String? displayName,
    String? phone,
    String? countryCode,
    String? dialCode,
    String? currency,
    String? locale,
    bool? profileComplete,
    bool? isDisabled,
    String? avatarUrl,
  }) {
    return UserProfileModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      countryCode: countryCode ?? this.countryCode,
      dialCode: dialCode ?? this.dialCode,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      profileComplete: profileComplete ?? this.profileComplete,
      isDisabled: isDisabled ?? this.isDisabled,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
