import 'package:flutter/foundation.dart' show kIsWeb;

// Import Firebase packages conditionally
import '../auth_imports.dart' if (dart.library.html) '../auth_imports_web.dart';
import '../models/user_point.dart';
import '../models/point_history.dart';
import '../utils/error_handler.dart';
import 'point_service_interface.dart';

/// Service for handling point-related operations.
///
/// This service provides methods for getting user points, consuming points,
/// and retrieving point history.
class PointService implements PointServiceInterface {
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
    // Constructor is empty, initialization is done in initialize() method
  }

  /// Initialize the service
  @override
  Future<void> initialize() async {
    return errorHandler.handleAsync(
      () async {
        // Skip Firebase initialization on web platform
        if (kIsWeb) {
          print(
              'Running on web platform, skipping Firebase Point Service initialization');
          _isFirebaseInitialized = false;
          return;
        }

        _auth = FirebaseAuth.instance;
        _firestore = FirebaseFirestore.instance;
        _functions = FirebaseFunctions.instance;
        _isFirebaseInitialized = true;
        print('Firebase Point Service initialized successfully');
      },
      'PointService.initialize',
      'ポイントサービスの初期化中にエラーが発生しました',
      onError: (errorMessage) {
        _isFirebaseInitialized = false;
        print(errorMessage);
      },
    );
  }

  /// Get current user's point information
  Future<UserPoint?> getUserPoint() async {
    if (!_isFirebaseInitialized) {
      errorHandler.logError(
        'Firebase not initialized',
        'PointService.getUserPoint',
      );
      return _getMockUserPoint();
    }

    return errorHandler.handleAsync<UserPoint?>(
      () async {
        // Check if the user is authenticated
        final user = _auth.currentUser;
        if (user == null) {
          errorHandler.logError(
            'User not authenticated',
            'PointService.getUserPoint',
          );
          return _getMockUserPoint();
        }

        // Get the user document from Firestore
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          errorHandler.logError(
            'User document not found',
            'PointService.getUserPoint',
          );
          return _getMockUserPoint();
        }

        final userData = userDoc.data();
        if (userData == null) {
          errorHandler.logError(
            'User data is null',
            'PointService.getUserPoint',
          );
          return _getMockUserPoint();
        }

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
      },
      'PointService.getUserPoint',
      'ユーザーポイント情報の取得中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
        return _getMockUserPoint();
      },
    );
  }

  /// Get the number of referrals for a user
  Future<int> _getReferralCount(String userId) async {
    final result = await errorHandler.handleAsync<int>(
      () async {
        final referralsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('referrals')
            .count()
            .get();

        return referralsSnapshot.count ?? 0;
      },
      'PointService._getReferralCount',
      '紹介数の取得中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
        return 0;
      },
    );

    return result ?? 0;
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
      errorHandler.logError(
        'Firebase not initialized',
        'PointService.getPointHistory',
      );
      return _getMockPointHistory();
    }

    final result = await errorHandler.handleAsync<List<PointHistory>>(
      () async {
        // Check if the user is authenticated
        final user = _auth.currentUser;
        if (user == null) {
          errorHandler.logError(
            'User not authenticated',
            'PointService.getPointHistory',
          );
          return _getMockPointHistory();
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
            type: data?['type'] ?? '',
            amount: data?['amount'] ?? 0,
            timestamp: data?['timestamp'] != null
                ? (data!['timestamp'] as Timestamp).toDate()
                : DateTime.now(),
            description: data?['description'] ?? '',
            expiryDate: data?['expiryDate'] != null
                ? (data!['expiryDate'] as Timestamp).toDate()
                : null,
          );
        }).toList();
      },
      'PointService.getPointHistory',
      'ポイント履歴の取得中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
        return _getMockPointHistory();
      },
    );

    return result ?? _getMockPointHistory();
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
      errorHandler.logError(
        'Firebase not initialized',
        'PointService.consumePoints',
      );
      return true; // Simulate successful consumption in development
    }

    final result = await errorHandler.handleAsync<bool>(
      () async {
        // Check if the user is authenticated
        final user = _auth.currentUser;
        if (user == null) {
          errorHandler.logError(
            'User not authenticated',
            'PointService.consumePoints',
          );
          return false;
        }

        // Validate amount
        if (amount <= 0) {
          errorHandler.logError(
            'Amount must be greater than 0',
            'PointService.consumePoints',
          );
          return false;
        }

        // Check if the user has enough points
        final userPoint = await getUserPoint();
        if (userPoint == null || userPoint.point < amount) {
          errorHandler.logError(
            'Not enough points',
            'PointService.consumePoints',
          );
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
      },
      'PointService.consumePoints',
      'ポイント消費中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
        return false;
      },
    );

    return result ?? false;
  }

  /// Apply a referral code to get bonus points
  Future<bool> applyReferralCode(String code) async {
    if (!_isFirebaseInitialized) {
      errorHandler.logError(
        'Firebase not initialized',
        'PointService.applyReferralCode',
      );
      return true; // Simulate successful referral in development
    }

    final result = await errorHandler.handleAsync<bool>(
      () async {
        // Check if the user is authenticated
        final user = _auth.currentUser;
        if (user == null) {
          errorHandler.logError(
            'User not authenticated',
            'PointService.applyReferralCode',
          );
          return false;
        }

        // Validate code format
        if (code.isEmpty || !RegExp(r'^[A-Z0-9]{8}$').hasMatch(code)) {
          errorHandler.logError(
            'Invalid referral code format',
            'PointService.applyReferralCode',
          );
          return false;
        }

        // Check if the user has already used a referral code
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.data()?['referredBy'] != null) {
          errorHandler.logError(
            'User has already used a referral code',
            'PointService.applyReferralCode',
          );
          return false;
        }

        // Check if the referral code exists
        final codeQuery = await _firestore
            .collection('users')
            .where('referralCode', isEqualTo: code)
            .limit(1)
            .get();

        if (codeQuery.docs.isEmpty) {
          errorHandler.logError(
            'Invalid referral code',
            'PointService.applyReferralCode',
          );
          return false;
        }

        final referrerDoc = codeQuery.docs.first;
        final referrerId = referrerDoc.id;

        // Check if the user is trying to use their own code
        if (referrerId == user.uid) {
          errorHandler.logError(
            'Cannot use own referral code',
            'PointService.applyReferralCode',
          );
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
      },
      'PointService.applyReferralCode',
      '紹介コードの適用中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
        return false;
      },
    );

    return result ?? false;
  }

  /// Get the user's referral code
  Future<String?> getReferralCode() async {
    if (!_isFirebaseInitialized) {
      errorHandler.logError(
        'Firebase not initialized',
        'PointService.getReferralCode',
      );
      return 'MOCK1234'; // Return mock referral code in development
    }

    return errorHandler.handleAsync<String?>(
      () async {
        final userPoint = await getUserPoint();
        return userPoint?.referralCode;
      },
      'PointService.getReferralCode',
      '紹介コードの取得中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
        return null;
      },
    );
  }

  /// Check if the user has enough points for a purchase
  Future<bool> hasEnoughPoints(int amount) async {
    if (!_isFirebaseInitialized) {
      errorHandler.logError(
        'Firebase not initialized',
        'PointService.hasEnoughPoints',
      );
      return true; // Assume user has enough points in development
    }

    final result = await errorHandler.handleAsync<bool>(
      () async {
        final userPoint = await getUserPoint();
        return userPoint != null && userPoint.point >= amount;
      },
      'PointService.hasEnoughPoints',
      'ポイント残高の確認中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
        return false;
      },
    );

    return result ?? false;
  }
}
