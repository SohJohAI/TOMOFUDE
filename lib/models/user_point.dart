/// A model class representing a user's point information.
///
/// This class contains information about a user's points, including
/// free points, paid points, and referral code.
class UserPoint {
  /// The user's ID.
  final String uid;

  /// The user's email.
  final String email;

  /// The user's display name.
  final String? displayName;

  /// The total number of points the user has.
  final int point;

  /// The number of free points the user has.
  final int freePoint;

  /// The number of paid points the user has.
  final int paidPoint;

  /// The user's referral code.
  final String referralCode;

  /// The date the user was created.
  final DateTime createdAt;

  /// The date the user's points were last reset.
  final DateTime? lastResetDate;

  /// The number of users this user has referred.
  final int referralCount;

  /// The date the user's referral bonus expires.
  final DateTime? referralExpiry;

  /// Creates a new user point.
  UserPoint({
    required this.uid,
    required this.email,
    this.displayName,
    required this.point,
    required this.freePoint,
    required this.paidPoint,
    required this.referralCode,
    required this.createdAt,
    required this.lastResetDate,
    required this.referralCount,
    this.referralExpiry,
  });

  /// Creates a user point from a map.
  factory UserPoint.fromMap(Map<String, dynamic> map) {
    return UserPoint(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      point: map['point'] as int,
      freePoint: map['freePoint'] as int,
      paidPoint: map['paidPoint'] as int,
      referralCode: map['referralCode'] as String,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
              ? map['createdAt'] as DateTime
              : DateTime.parse(map['createdAt'].toString()))
          : DateTime.now(),
      lastResetDate: map['lastResetDate'] != null
          ? (map['lastResetDate'] is DateTime
              ? map['lastResetDate'] as DateTime
              : DateTime.parse(map['lastResetDate'].toString()))
          : DateTime.now(),
      referralCount: map['referralCount'] as int? ?? 0,
      referralExpiry: map['referralExpiry'] != null
          ? (map['referralExpiry'] is DateTime
              ? map['referralExpiry'] as DateTime
              : DateTime.parse(map['referralExpiry'].toString()))
          : null,
    );
  }

  /// Converts this user point to a map.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'point': point,
      'freePoint': freePoint,
      'paidPoint': paidPoint,
      'referralCode': referralCode,
      'createdAt': createdAt.toIso8601String(),
      'lastResetDate': lastResetDate?.toIso8601String(),
      'referralCount': referralCount,
      'referralExpiry': referralExpiry?.toIso8601String(),
    };
  }

  /// Creates a copy of this user point with the given fields replaced with the new values.
  UserPoint copyWith({
    String? uid,
    String? email,
    String? displayName,
    int? point,
    int? freePoint,
    int? paidPoint,
    String? referralCode,
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
      createdAt: createdAt ?? this.createdAt,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      referralCount: referralCount ?? this.referralCount,
      referralExpiry: referralExpiry ?? this.referralExpiry,
    );
  }
}
