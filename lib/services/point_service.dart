import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_point.dart';
import '../models/point_history.dart';

/// Service for handling point-related operations.
///
/// This service provides methods for getting user points, consuming points,
/// and retrieving point history.
class PointService {
  /// Singleton instance
  static final PointService _instance = PointService._internal();

  /// Factory constructor to return the same instance
  factory PointService() => _instance;

  /// Firebase Auth instance
  late final FirebaseAuth _auth;

  /// Firestore instance
  late final FirebaseFirestore _firestore;

  /// Cloud Functions instance
  late final FirebaseFunctions _functions;

  /// Flag indicating whether Firebase is initialized
  bool _isFirebaseInitialized = false;

  /// Private constructor
  PointService._internal() {
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _functions = FirebaseFunctions.instance;
      _isFirebaseInitialized = true;
      print('Firebase Point Service initialized successfully');
    } catch (e) {
      print('Firebase not initialized in PointService: $e');
      _isFirebaseInitialized = false;
    }
  }

  /// Get current user's point information
  Future<UserPoint?> getUserPoint() async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized, returning mock data');
      return _getMockUserPoint();
    }

    try {
      // Check if the user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the user document from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        print('User document not found');
        return null;
      }

      final userData = userDoc.data()!;

      // Get referral count
      final referralCount = await _getReferralCount(user.uid);

      // Create UserPoint object
      final DateTime? lastResetDate = userData['lastResetDate'] != null
          ? (userData['lastResetDate'] as Timestamp).toDate()
          : null;

      final DateTime? referralExpiry = userData['referralExpiry'] != null
          ? (userData['referralExpiry'] as Timestamp).toDate()
          : null;

      return UserPoint(
        uid: user.uid,
        email: user.email ?? userData['email'] ?? '',
        displayName: user.displayName ?? userData['displayName'] ?? '',
        point: userData['point'] ?? 0,
        freePoint: userData['freePoint'] ?? 0,
        paidPoint: userData['paidPoint'] ?? 0,
        referralCode: userData['referralCode'] ?? '',
        createdAt: userData['createdAt'] != null
            ? (userData['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        lastResetDate: lastResetDate,
        referralCount: referralCount,
        referralExpiry: referralExpiry,
      );
    } catch (e) {
      print('Error getting user point: $e');
      return _getMockUserPoint();
    }
  }

  /// Get the number of referrals for a user
  Future<int> _getReferralCount(String userId) async {
    try {
      final referralsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('referrals')
          .count()
          .get();

      return referralsSnapshot.count ?? 0;
    } catch (e) {
      print('Error getting referral count: $e');
      return 0;
    }
  }

  /// Get mock user point data for development
  UserPoint _getMockUserPoint() {
    return UserPoint(
      uid: 'mock-user-id',
      email: 'mock@example.com',
      displayName: 'Mock User',
      point: 1500,
      freePoint: 1000,
      paidPoint: 500,
      referralCode: 'MOCK1234',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastResetDate: DateTime.now().subtract(const Duration(days: 15)),
      referralCount: 2,
      referralExpiry: DateTime.now().add(const Duration(days: 60)),
    );
  }

  /// Get user's point history
  Future<List<PointHistory>> getPointHistory({int limit = 50}) async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized, returning mock data');
      return _getMockPointHistory();
    }

    try {
      // Check if the user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the point history from Firestore
      final historySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return historySnapshot.docs.map((doc) {
        final data = doc.data();
        return PointHistory(
          id: doc.id,
          userId: user.uid,
          type: data['type'] ?? '',
          amount: data['amount'] ?? 0,
          timestamp: data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          description: data['description'] ?? '',
          expiryDate: data['expiryDate'] != null
              ? (data['expiryDate'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    } catch (e) {
      print('Error getting point history: $e');
      return _getMockPointHistory();
    }
  }

  /// Get mock point history data for development
  List<PointHistory> _getMockPointHistory() {
    final now = DateTime.now();
    return [
      PointHistory(
        id: 'mock-history-1',
        userId: 'mock-user-id',
        type: PointHistory.registerBonus,
        amount: 1000,
        timestamp: now.subtract(const Duration(days: 30)),
        description: '初回登録ボーナス',
        expiryDate: now.add(const Duration(days: 60)),
      ),
      PointHistory(
        id: 'mock-history-2',
        userId: 'mock-user-id',
        type: PointHistory.referralBonus,
        amount: 500,
        timestamp: now.subtract(const Duration(days: 15)),
        description: '紹介ボーナス',
        expiryDate: now.add(const Duration(days: 75)),
      ),
      PointHistory(
        id: 'mock-history-3',
        userId: 'mock-user-id',
        type: PointHistory.pointConsumption,
        amount: -500,
        timestamp: now.subtract(const Duration(days: 5)),
        description: 'AI執筆支援',
        expiryDate: null,
      ),
    ];
  }

  /// Consume points for a specific purpose
  Future<bool> consumePoints(int amount, String purpose) async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized, simulating point consumption');
      return true; // Simulate successful consumption in development
    }

    try {
      // Check if the user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate amount
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      // Check if the user has enough points
      final userPoint = await getUserPoint();
      if (userPoint == null || userPoint.point < amount) {
        print('Not enough points');
        return false;
      }

      // Determine which points to use (free points first, then paid points)
      int freePointsToUse = 0;
      int paidPointsToUse = 0;

      if (userPoint.freePoint >= amount) {
        freePointsToUse = amount;
      } else {
        freePointsToUse = userPoint.freePoint;
        paidPointsToUse = amount - freePointsToUse;
      }

      // Update the user's points in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'point': FieldValue.increment(-amount),
        'freePoint': FieldValue.increment(-freePointsToUse),
        'paidPoint': FieldValue.increment(-paidPointsToUse),
      });

      // Add to point history
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .add({
        'type': PointHistory.pointConsumption,
        'amount': -amount,
        'description': purpose,
        'timestamp': FieldValue.serverTimestamp(),
        'expiryDate': null,
      });

      return true;
    } catch (e) {
      print('Error consuming points: $e');
      return false;
    }
  }

  /// Apply a referral code to get bonus points
  Future<bool> applyReferralCode(String code) async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized, simulating referral code application');
      return true; // Simulate successful referral in development
    }

    try {
      // Check if the user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate code format
      if (code.isEmpty || !RegExp(r'^[A-Z0-9]{8}$').hasMatch(code)) {
        throw Exception('Invalid referral code format');
      }

      // Check if the user has already used a referral code
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.data()?['referredBy'] != null) {
        print('User has already used a referral code');
        return false;
      }

      // Check if the referral code exists
      final codeQuery = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: code)
          .limit(1)
          .get();

      if (codeQuery.docs.isEmpty) {
        print('Invalid referral code');
        return false;
      }

      final referrerDoc = codeQuery.docs.first;
      final referrerId = referrerDoc.id;

      // Check if the user is trying to use their own code
      if (referrerId == user.uid) {
        print('Cannot use own referral code');
        return false;
      }

      // Update the user document with the referral code
      await _firestore.collection('users').doc(user.uid).update({
        'referredBy': code,
        'referredById': referrerId,
        'point': FieldValue.increment(500),
        'freePoint': FieldValue.increment(500),
        'referralExpiry':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 90))),
      });

      // Add points to the referrer
      await _firestore.collection('users').doc(referrerId).update({
        'point': FieldValue.increment(500),
        'freePoint': FieldValue.increment(500),
      });

      // Add to referral history
      await _firestore
          .collection('users')
          .doc(referrerId)
          .collection('referrals')
          .add({
        'referredUserId': user.uid,
        'referredUserEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
        'points': 500,
      });

      // Add to point history for referrer
      await _firestore
          .collection('users')
          .doc(referrerId)
          .collection('history')
          .add({
        'type': PointHistory.referralBonus,
        'amount': 500,
        'description': '紹介ボーナス',
        'timestamp': FieldValue.serverTimestamp(),
        'expiryDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 90))),
      });

      // Add to point history for user
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .add({
        'type': PointHistory.referralBonus,
        'amount': 500,
        'description': '紹介ボーナス',
        'timestamp': FieldValue.serverTimestamp(),
        'expiryDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 90))),
      });

      return true;
    } catch (e) {
      print('Error applying referral code: $e');
      return false;
    }
  }

  /// Get the user's referral code
  Future<String?> getReferralCode() async {
    if (!_isFirebaseInitialized) {
      return 'MOCK1234'; // Return mock referral code in development
    }

    try {
      final userPoint = await getUserPoint();
      return userPoint?.referralCode;
    } catch (e) {
      print('Error getting referral code: $e');
      return null;
    }
  }

  /// Check if the user has enough points for a purchase
  Future<bool> hasEnoughPoints(int amount) async {
    if (!_isFirebaseInitialized) {
      return true; // Assume user has enough points in development
    }

    try {
      final userPoint = await getUserPoint();
      return userPoint != null && userPoint.point >= amount;
    } catch (e) {
      print('Error checking points: $e');
      return false;
    }
  }
}
