import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_point.dart';
import '../models/point_history.dart';

/// Service for handling point-related operations.
///
/// This service provides methods for getting user points, consuming points,
/// and retrieving point history.
///
/// Note: This requires Firebase packages to be installed.
/// Run 'flutter pub get' after adding Firebase dependencies to pubspec.yaml.
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

      // Call the Cloud Function to get user point
      final result = await _functions.httpsCallable('getUserPoint').call();

      // If the function returns data directly
      if (result.data != null) {
        return UserPoint.fromMap(result.data);
      }

      // Alternatively, get the data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return null;
      }

      return UserPoint.fromMap(userDoc.data()!);
    } catch (e) {
      print('Error getting user point: $e');
      return _getMockUserPoint();
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

      // Call the Cloud Function to get point history
      final result = await _functions.httpsCallable('getPointHistory').call({
        'limit': limit,
      });

      // If the function returns data directly
      if (result.data != null && result.data['history'] != null) {
        return (result.data['history'] as List)
            .map((item) => PointHistory.fromMap(item))
            .toList();
      }

      // Alternatively, get the data from Firestore
      final historySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return historySnapshot.docs
          .map((doc) => PointHistory.fromMap(doc.data()))
          .toList();
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
        amount: 1500,
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

      // Call the Cloud Function to consume points
      final result = await _functions.httpsCallable('consumePoints').call({
        'amount': amount,
        'purpose': purpose,
      });

      return result.data['success'] ?? false;
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

      // Call the Cloud Function to apply the referral code
      final result = await _functions.httpsCallable('applyReferralBonus').call({
        'referralCode': code,
      });

      return result.data['success'] ?? false;
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
