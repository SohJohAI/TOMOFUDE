/// UserPoint model represents a user's point information in the system.
///
/// This model includes details about the user's points, referral code, and other
/// related information for the payment system.
class UserPoint {
  final String uid;
  final String email;
  final String? displayName;
  final int point;
  final int freePoint;
  final int paidPoint;
  final String referralCode;
  final String? referredBy;
  final DateTime createdAt;
  final DateTime lastResetDate;
  final int referralCount;
  final DateTime referralExpiry;

  UserPoint({
    required this.uid,
    required this.email,
    this.displayName,
    required this.point,
    required this.freePoint,
    required this.paidPoint,
    required this.referralCode,
    this.referredBy,
    required this.createdAt,
    required this.lastResetDate,
    required this.referralCount,
    required this.referralExpiry,
  });

  /// Creates a UserPoint instance from a Firestore document map.
  ///
  /// Note: This requires the cloud_firestore package to be installed.
  /// Run 'flutter pub get' after adding Firebase dependencies to pubspec.yaml.
  factory UserPoint.fromMap(Map<String, dynamic> map) {
    return UserPoint(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      point: map['point'] ?? 0,
      freePoint: map['freePoint'] ?? 0,
      paidPoint: map['paidPoint'] ?? 0,
      referralCode: map['referralCode'] ?? '',
      referredBy: map['referredBy'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      lastResetDate: map['lastResetDate']?.toDate() ?? DateTime.now(),
      referralCount: map['referralCount'] ?? 0,
      referralExpiry: map['referralExpiry']?.toDate() ??
          DateTime.now().add(const Duration(days: 90)),
    );
  }

  /// Converts this UserPoint instance to a map for Firestore storage.
  ///
  /// Note: This requires the cloud_firestore package to be installed.
  /// Run 'flutter pub get' after adding Firebase dependencies to pubspec.yaml.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'point': point,
      'freePoint': freePoint,
      'paidPoint': paidPoint,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'createdAt': createdAt,
      'lastResetDate': lastResetDate,
      'referralCount': referralCount,
      'referralExpiry': referralExpiry,
    };
  }

  UserPoint copyWith({
    String? uid,
    String? email,
    String? displayName,
    int? point,
    int? freePoint,
    int? paidPoint,
    String? referralCode,
    String? referredBy,
    DateTime? createdAt,
    DateTime? lastResetDate,
    int? referralCount,
    DateTime? referralExpiry,
  }) {
    return UserPoint(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      point: point ?? this.point,
      freePoint: freePoint ?? this.freePoint,
      paidPoint: paidPoint ?? this.paidPoint,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      createdAt: createdAt ?? this.createdAt,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      referralCount: referralCount ?? this.referralCount,
      referralExpiry: referralExpiry ?? this.referralExpiry,
    );
  }
}
