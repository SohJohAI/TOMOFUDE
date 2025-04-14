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

  /// Private constructor
  PointService._internal();

  /// Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cloud Functions instance
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get current user's point information
  Future<UserPoint?> getUserPoint() async {
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
      rethrow;
    }
  }

  /// Get user's point history
  Future<List<PointHistory>> getPointHistory({int limit = 50}) async {
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
      return [];
    }
  }

  /// Consume points for a specific purpose
  Future<bool> consumePoints(int amount, String purpose) async {
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
      rethrow;
    }
  }

  /// Apply a referral code to get bonus points
  Future<bool> applyReferralCode(String code) async {
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
      rethrow;
    }
  }

  /// Get the user's referral code
  Future<String?> getReferralCode() async {
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
    try {
      final userPoint = await getUserPoint();
      return userPoint != null && userPoint.point >= amount;
    } catch (e) {
      print('Error checking points: $e');
      return false;
    }
  }
}
