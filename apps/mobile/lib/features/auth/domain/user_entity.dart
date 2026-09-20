class UserEntity {
  final String id;
  final String email;
  final String fullName;
  final String baseCurrency;
  final bool biometricEnabled;
  final int monthStartDay;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.baseCurrency = 'INR',
    this.biometricEnabled = false,
    this.monthStartDay = 1,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] is Map<String, dynamic>
        ? json['metadata'] as Map<String, dynamic>
        : (json['user_metadata'] is Map<String, dynamic>
            ? json['user_metadata'] as Map<String, dynamic>
            : <String, dynamic>{});

    final name = json['fullName'] ??
        json['full_name'] ??
        metadata['full_name'] ??
        metadata['fullName'] ??
        '';

    final currency = json['baseCurrency'] ??
        json['base_currency'] ??
        metadata['base_currency'] ??
        metadata['baseCurrency'] ??
        'INR';

    return UserEntity(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: name.toString(),
      baseCurrency: currency.toString(),
      biometricEnabled: json['biometricEnabled'] ?? json['biometric_enabled'] ?? false,
      monthStartDay: json['monthStartDay'] ?? json['month_start_day'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'baseCurrency': baseCurrency,
      'biometricEnabled': biometricEnabled,
      'monthStartDay': monthStartDay,
    };
  }

  UserEntity copyWith({
    String? id,
    String? email,
    String? fullName,
    String? baseCurrency,
    bool? biometricEnabled,
    int? monthStartDay,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      monthStartDay: monthStartDay ?? this.monthStartDay,
    );
  }
}
