/// PointHistory model represents a record of point transactions in the system.
///
/// This model tracks various point-related activities such as registration bonuses,
/// referral bonuses, point consumption, and monthly resets.
class PointHistory {
  final String id;
  final String userId;
  final String type;
  final int amount;
  final DateTime timestamp;
  final String description;
  final DateTime? expiryDate;

  /// Possible types of point history records
  static const String registerBonus = 'register_bonus';
  static const String referralBonus = 'referral_bonus';
  static const String referralUsed = 'referral_used';
  static const String pointConsumption = 'point_consumption';
  static const String monthlyReset = 'monthly_reset';

  PointHistory({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.timestamp,
    required this.description,
    this.expiryDate,
  });

  /// Creates a PointHistory instance from a Firestore document map.
  ///
  /// Note: This requires the cloud_firestore package to be installed.
  /// Run 'flutter pub get' after adding Firebase dependencies to pubspec.yaml.
  factory PointHistory.fromMap(Map<String, dynamic> map) {
    return PointHistory(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      amount: map['amount'] ?? 0,
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      description: map['description'] ?? '',
      expiryDate: map['expiryDate']?.toDate(),
    );
  }

  /// Converts this PointHistory instance to a map for Firestore storage.
  ///
  /// Note: This requires the cloud_firestore package to be installed.
  /// Run 'flutter pub get' after adding Firebase dependencies to pubspec.yaml.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'timestamp': timestamp,
      'description': description,
      'expiryDate': expiryDate,
    };
  }
}
