/// ReferralCode model represents a referral code in the system.
///
/// This model tracks referral codes, their owners, and expiration dates.
class ReferralCode {
  final String code;
  final String userId;
  final DateTime createdAt;
  final DateTime expiryDate;
  final bool isActive;

  ReferralCode({
    required this.code,
    required this.userId,
    required this.createdAt,
    required this.expiryDate,
    this.isActive = true,
  });

  /// Creates a ReferralCode instance from a Firestore document map.
  ///
  /// Note: This requires the cloud_firestore package to be installed.
  /// Run 'flutter pub get' after adding Firebase dependencies to pubspec.yaml.
  factory ReferralCode.fromMap(Map<String, dynamic> map) {
    return ReferralCode(
      code: map['code'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      expiryDate: map['expiryDate']?.toDate() ??
          DateTime.now().add(const Duration(days: 90)),
      isActive: map['isActive'] ?? true,
    );
  }

  /// Converts this ReferralCode instance to a map for Firestore storage.
  ///
  /// Note: This requires the cloud_firestore package to be installed.
  /// Run 'flutter pub get' after adding Firebase dependencies to pubspec.yaml.
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'userId': userId,
      'createdAt': createdAt,
      'expiryDate': expiryDate,
      'isActive': isActive,
    };
  }

  /// Creates a copy of this ReferralCode with the given fields replaced with the new values.
  ReferralCode copyWith({
    String? code,
    String? userId,
    DateTime? createdAt,
    DateTime? expiryDate,
    bool? isActive,
  }) {
    return ReferralCode(
      code: code ?? this.code,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
