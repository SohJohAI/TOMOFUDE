/// A model class representing a referral code.
///
/// This class contains information about a referral code,
/// including the code, owner, and usage count.
class ReferralCode {
  /// The referral code.
  final String code;

  /// The ID of the user who owns this code.
  final String ownerId;

  /// The email of the user who owns this code.
  final String ownerEmail;

  /// The display name of the user who owns this code.
  final String? ownerDisplayName;

  /// The number of times this code has been used.
  final int usageCount;

  /// The maximum number of times this code can be used.
  final int maxUsage;

  /// Whether this code is active.
  final bool isActive;

  /// The date this code was created.
  final DateTime createdAt;

  /// The date this code expires.
  final DateTime expiryDate;

  /// Creates a new referral code.
  ReferralCode({
    required this.code,
    required this.ownerId,
    required this.ownerEmail,
    this.ownerDisplayName,
    required this.usageCount,
    required this.maxUsage,
    required this.isActive,
    required this.createdAt,
    required this.expiryDate,
  });

  /// Creates a referral code from a map.
  factory ReferralCode.fromMap(Map<String, dynamic> map) {
    return ReferralCode(
      code: map['code'] as String,
      ownerId: map['ownerId'] as String,
      ownerEmail: map['ownerEmail'] as String,
      ownerDisplayName: map['ownerDisplayName'] as String?,
      usageCount: map['usageCount'] as int,
      maxUsage: map['maxUsage'] as int,
      isActive: map['isActive'] as bool,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
              ? map['createdAt'] as DateTime
              : DateTime.parse(map['createdAt'].toString()))
          : DateTime.now(),
      expiryDate: map['expiryDate'] != null
          ? (map['expiryDate'] is DateTime
              ? map['expiryDate'] as DateTime
              : DateTime.parse(map['expiryDate'].toString()))
          : DateTime.now().add(const Duration(days: 90)),
    );
  }

  /// Converts this referral code to a map.
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'ownerDisplayName': ownerDisplayName,
      'usageCount': usageCount,
      'maxUsage': maxUsage,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
    };
  }

  /// Creates a copy of this referral code with the given fields replaced with the new values.
  ReferralCode copyWith({
    String? code,
    String? ownerId,
    String? ownerEmail,
    String? ownerDisplayName,
    int? usageCount,
    int? maxUsage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? expiryDate,
  }) {
    return ReferralCode(
      code: code ?? this.code,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerDisplayName: ownerDisplayName ?? this.ownerDisplayName,
      usageCount: usageCount ?? this.usageCount,
      maxUsage: maxUsage ?? this.maxUsage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  /// Gets whether this code is expired.
  bool get isExpired => expiryDate.isBefore(DateTime.now());

  /// Gets whether this code is valid.
  bool get isValid => isActive && !isExpired && usageCount < maxUsage;

  /// Gets the number of remaining uses.
  int get remainingUses => maxUsage - usageCount;

  /// Gets the number of days until this code expires.
  int get daysUntilExpiry {
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  /// Gets whether this code is about to expire (within 7 days).
  bool get isAboutToExpire {
    final daysLeft = daysUntilExpiry;
    return daysLeft <= 7 && daysLeft >= 0;
  }
}
