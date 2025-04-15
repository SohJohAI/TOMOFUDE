import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_point.dart';
import '../models/point_history.dart';
import '../utils/error_handler.dart';
import 'point_service_interface.dart';
import 'auth_service.dart';

/// Service for handling point-related operations.
///
/// This service provides methods for getting user points, consuming points,
/// and retrieving point history.
class PointService implements PointServiceInterface {
  /// Singleton instance
  static final PointService _instance = PointService._internal();

  /// Factory constructor to return the same instance
  factory PointService() => _instance;

  /// Auth service
  late final AuthService _authService;

  /// Key for storing user points in SharedPreferences
  static const String _userPointsKey = 'user_points';

  /// Key for storing point history in SharedPreferences
  static const String _pointHistoryKey = 'point_history';

  /// Private constructor
  PointService._internal() {
    // Constructor is empty, initialization is done in initialize() method
  }

  /// Initialize the service
  @override
  Future<void> initialize() async {
    return errorHandler.handleAsync(
      () async {
        print('Local PointService initialized');
        _authService = AuthService();
      },
      'PointService.initialize',
      'ポイントサービスの初期化中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
      },
    );
  }

  /// Get current user's point information
  @override
  Future<UserPoint?> getUserPoint() async {
    return errorHandler.handleAsync<UserPoint?>(
      () async {
        // Check if the user is authenticated
        final user = _authService.currentUser;
        if (user == null) {
          errorHandler.logError(
            'User not authenticated',
            'PointService.getUserPoint',
          );
          return _getMockUserPoint();
        }

        // Get user points from SharedPreferences
        final userPoints = await _getUserPoints();

        // Find user point for current user
        final userPointJson = userPoints[user.uid];

        if (userPointJson == null) {
          // Create new user point
          final userPoint = UserPoint(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName ?? user.email.split('@')[0],
            point: 1000,
            freePoint: 1000,
            paidPoint: 0,
            referralCode: _generateReferralCode(),
            createdAt: DateTime.now(),
            lastResetDate: DateTime.now(),
            referralCount: 0,
          );

          // Save user point
          await _saveUserPoint(userPoint);

          return userPoint;
        }

        // Get referral count
        final referralCount = await _getReferralCount(user.uid);

        // Create UserPoint object
        return UserPoint(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          point: userPointJson['point'] ?? 0,
          freePoint: userPointJson['freePoint'] ?? 0,
          paidPoint: userPointJson['paidPoint'] ?? 0,
          referralCode: userPointJson['referralCode'] ?? '',
          createdAt: userPointJson['createdAt'] != null
              ? DateTime.parse(userPointJson['createdAt'])
              : DateTime.now(),
          lastResetDate: userPointJson['lastResetDate'] != null
              ? DateTime.parse(userPointJson['lastResetDate'])
              : null,
          referralCount: referralCount,
          referralExpiry: userPointJson['referralExpiry'] != null
              ? DateTime.parse(userPointJson['referralExpiry'])
              : null,
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
        // Get point history from SharedPreferences
        final pointHistory = await _getPointHistory();

        // Count referral bonus entries for this user
        return pointHistory
            .where((history) =>
                history.userId == userId &&
                history.type == PointHistory.referralBonus)
            .length;
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
  @override
  Future<List<PointHistory>> getPointHistory({int limit = 50}) async {
    final result = await errorHandler.handleAsync<List<PointHistory>>(
      () async {
        // Check if the user is authenticated
        final user = _authService.currentUser;
        if (user == null) {
          errorHandler.logError(
            'User not authenticated',
            'PointService.getPointHistory',
          );
          return _getMockPointHistory();
        }

        // Get point history from SharedPreferences
        final allHistory = await _getPointHistory();

        // Filter history for current user and sort by timestamp (descending)
        final userHistory = allHistory
            .where((history) => history.userId == user.uid)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Limit the number of entries
        if (userHistory.length > limit) {
          return userHistory.sublist(0, limit);
        }

        return userHistory;
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
  @override
  Future<bool> consumePoints(int amount, String purpose) async {
    final result = await errorHandler.handleAsync<bool>(
      () async {
        // Check if the user is authenticated
        final user = _authService.currentUser;
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

        // Update user point
        final updatedUserPoint = UserPoint(
          uid: userPoint.uid,
          email: userPoint.email,
          displayName: userPoint.displayName,
          point: userPoint.point - amount,
          freePoint: userPoint.freePoint - freePointsToUse,
          paidPoint: userPoint.paidPoint - paidPointsToUse,
          referralCode: userPoint.referralCode,
          createdAt: userPoint.createdAt,
          lastResetDate: userPoint.lastResetDate,
          referralCount: userPoint.referralCount,
          referralExpiry: userPoint.referralExpiry,
        );

        // Save updated user point
        await _saveUserPoint(updatedUserPoint);

        // Add to point history
        final history = PointHistory(
          id: const Uuid().v4(),
          userId: user.uid,
          type: PointHistory.pointConsumption,
          amount: -amount,
          timestamp: DateTime.now(),
          description: purpose,
          expiryDate: null,
        );

        await _addPointHistory(history);

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
  @override
  Future<bool> applyReferralCode(String code) async {
    final result = await errorHandler.handleAsync<bool>(
      () async {
        // Check if the user is authenticated
        final user = _authService.currentUser;
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

        // Get user points
        final userPoints = await _getUserPoints();
        final userPointJson = userPoints[user.uid];

        if (userPointJson == null) {
          errorHandler.logError(
            'User point not found',
            'PointService.applyReferralCode',
          );
          return false;
        }

        // Check if the user has already used a referral code
        if (userPointJson['referredBy'] != null) {
          errorHandler.logError(
            'User has already used a referral code',
            'PointService.applyReferralCode',
          );
          return false;
        }

        // Find referrer with matching referral code
        String? referrerId;
        for (final entry in userPoints.entries) {
          if (entry.value['referralCode'] == code) {
            referrerId = entry.key;
            break;
          }
        }

        if (referrerId == null) {
          errorHandler.logError(
            'Invalid referral code',
            'PointService.applyReferralCode',
          );
          return false;
        }

        // Check if the user is trying to use their own code
        if (referrerId == user.uid) {
          errorHandler.logError(
            'Cannot use own referral code',
            'PointService.applyReferralCode',
          );
          return false;
        }

        // Update user point
        userPointJson['referredBy'] = code;
        userPointJson['referredById'] = referrerId;
        userPointJson['point'] = (userPointJson['point'] ?? 0) + 500;
        userPointJson['freePoint'] = (userPointJson['freePoint'] ?? 0) + 500;
        userPointJson['referralExpiry'] =
            DateTime.now().add(const Duration(days: 90)).toIso8601String();
        userPoints[user.uid] = userPointJson;

        // Update referrer point
        final referrerPointJson = userPoints[referrerId];
        if (referrerPointJson != null) {
          referrerPointJson['point'] = (referrerPointJson['point'] ?? 0) + 500;
          referrerPointJson['freePoint'] =
              (referrerPointJson['freePoint'] ?? 0) + 500;
          userPoints[referrerId] = referrerPointJson;
        }

        // Save user points
        await _saveUserPoints(userPoints);

        // Add to point history for user
        final userHistory = PointHistory(
          id: const Uuid().v4(),
          userId: user.uid,
          type: PointHistory.referralBonus,
          amount: 500,
          timestamp: DateTime.now(),
          description: '紹介ボーナス',
          expiryDate: DateTime.now().add(const Duration(days: 90)),
        );

        await _addPointHistory(userHistory);

        // Add to point history for referrer
        if (referrerPointJson != null) {
          final referrerHistory = PointHistory(
            id: const Uuid().v4(),
            userId: referrerId,
            type: PointHistory.referralBonus,
            amount: 500,
            timestamp: DateTime.now(),
            description: '紹介ボーナス',
            expiryDate: DateTime.now().add(const Duration(days: 90)),
          );

          await _addPointHistory(referrerHistory);
        }

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
  @override
  Future<String?> getReferralCode() async {
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
  @override
  Future<bool> hasEnoughPoints(int amount) async {
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

  /// Get user points from SharedPreferences
  Future<Map<String, Map<String, dynamic>>> _getUserPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final userPointsJson = prefs.getString(_userPointsKey);

    if (userPointsJson == null) {
      return {};
    }

    final Map<String, dynamic> userPointsMap = jsonDecode(userPointsJson);
    final Map<String, Map<String, dynamic>> result = {};

    userPointsMap.forEach((key, value) {
      result[key] = Map<String, dynamic>.from(value);
    });

    return result;
  }

  /// Save user points to SharedPreferences
  Future<void> _saveUserPoints(
      Map<String, Map<String, dynamic>> userPoints) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPointsKey, jsonEncode(userPoints));
  }

  /// Save a single user point to SharedPreferences
  Future<void> _saveUserPoint(UserPoint userPoint) async {
    final userPoints = await _getUserPoints();

    userPoints[userPoint.uid] = {
      'uid': userPoint.uid,
      'email': userPoint.email,
      'displayName': userPoint.displayName,
      'point': userPoint.point,
      'freePoint': userPoint.freePoint,
      'paidPoint': userPoint.paidPoint,
      'referralCode': userPoint.referralCode,
      'createdAt': userPoint.createdAt.toIso8601String(),
      'lastResetDate': userPoint.lastResetDate?.toIso8601String(),
      'referralExpiry': userPoint.referralExpiry?.toIso8601String(),
    };

    await _saveUserPoints(userPoints);
  }

  /// Get point history from SharedPreferences
  Future<List<PointHistory>> _getPointHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_pointHistoryKey);

    if (historyJson == null) {
      return [];
    }

    return historyJson.map((json) {
      final Map<String, dynamic> map = jsonDecode(json);
      return PointHistory(
        id: map['id'],
        userId: map['userId'],
        type: map['type'],
        amount: map['amount'],
        timestamp: DateTime.parse(map['timestamp']),
        description: map['description'],
        expiryDate: map['expiryDate'] != null
            ? DateTime.parse(map['expiryDate'])
            : null,
      );
    }).toList();
  }

  /// Add a point history entry to SharedPreferences
  Future<void> _addPointHistory(PointHistory history) async {
    final allHistory = await _getPointHistory();
    allHistory.add(history);

    final prefs = await SharedPreferences.getInstance();
    final historyJson = allHistory.map((h) => jsonEncode(h.toMap())).toList();
    await prefs.setStringList(_pointHistoryKey, historyJson);
  }

  /// Generate a random referral code
  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final code = List.generate(8, (index) {
      final randomIndex =
          (random.codeUnitAt(index % random.length) + index) % chars.length;
      return chars[randomIndex];
    }).join();
    return code;
  }
}
