/// A model class representing a point history entry.
///
/// This class contains information about a point transaction,
/// including the amount, type, and date.
class PointHistory {
  /// The ID of the history entry.
  final String id;

  /// The ID of the user.
  final String userId;

  /// The type of the transaction.
  final String type;

  /// The amount of points.
  final int amount;

  /// The timestamp of the transaction.
  final DateTime timestamp;

  /// The description of the transaction.
  final String description;

  /// The expiry date of the points.
  final DateTime? expiryDate;

  /// Type constant for register bonus.
  static const String registerBonus = 'register_bonus';

  /// Type constant for referral bonus.
  static const String referralBonus = 'referral_bonus';

  /// Type constant for monthly bonus.
  static const String monthlyBonus = 'monthly_bonus';

  /// Type constant for point consumption.
  static const String pointConsumption = 'point_consumption';

  /// Type constant for point purchase.
  static const String pointPurchase = 'point_purchase';

  /// Creates a new point history entry.
  PointHistory({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.timestamp,
    required this.description,
    this.expiryDate,
  });

  /// Creates a point history entry from a map.
  factory PointHistory.fromMap(Map<String, dynamic> map) {
    return PointHistory(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: map['type'] as String,
      amount: map['amount'] as int,
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] is DateTime
              ? map['timestamp'] as DateTime
              : DateTime.parse(map['timestamp'].toString()))
          : DateTime.now(),
      description: map['description'] as String,
      expiryDate: map['expiryDate'] != null
          ? (map['expiryDate'] is DateTime
              ? map['expiryDate'] as DateTime
              : DateTime.parse(map['expiryDate'].toString()))
          : null,
    );
  }

  /// Converts this point history entry to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  /// Creates a copy of this point history entry with the given fields replaced with the new values.
  PointHistory copyWith({
    String? id,
    String? userId,
    String? type,
    int? amount,
    DateTime? timestamp,
    String? description,
    DateTime? expiryDate,
  }) {
    return PointHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  /// Gets a human-readable type name.
  String get typeName {
    switch (type) {
      case registerBonus:
        return '初回登録ボーナス';
      case referralBonus:
        return '紹介ボーナス';
      case monthlyBonus:
        return '月間ボーナス';
      case pointConsumption:
        return 'ポイント消費';
      case pointPurchase:
        return 'ポイント購入';
      default:
        return type;
    }
  }

  /// Gets whether this is a positive transaction.
  bool get isPositive => amount > 0;

  /// Gets whether this is a negative transaction.
  bool get isNegative => amount < 0;

  /// Gets whether this transaction has an expiry date.
  bool get hasExpiry => expiryDate != null;

  /// Gets whether this transaction is expired.
  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  /// Gets whether this transaction is about to expire (within 7 days).
  bool get isAboutToExpire {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final difference = expiryDate!.difference(now).inDays;
    return difference <= 7 && difference >= 0;
  }
}
