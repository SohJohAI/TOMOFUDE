// This is a web-specific version of point_service.dart that doesn't use Firebase
// to avoid compatibility issues with Firebase web packages

import '../models/user_point.dart';
import '../models/point_history.dart';
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

  /// Flag indicating whether Firebase is initialized
  bool _isFirebaseInitialized = false;

  /// Private constructor
  PointService._internal() {
    // Constructor is empty, initialization is done in initialize() method
  }

  /// Initialize the service
  @override
  Future<void> initialize() async {
    print('Web version of PointService initialized, Firebase is disabled');
    _isFirebaseInitialized = false;
  }

  /// Get current user's point information
  Future<UserPoint?> getUserPoint() async {
    print('Firebase not initialized on web, returning mock data');
    return _getMockUserPoint();
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
    print('Firebase not initialized on web, returning mock data');
    return _getMockPointHistory();
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
    print('Firebase not initialized on web, simulating point consumption');
    return true; // Simulate successful consumption in development
  }

  /// Apply a referral code to get bonus points
  Future<bool> applyReferralCode(String code) async {
    print(
        'Firebase not initialized on web, simulating referral code application');
    return true; // Simulate successful referral in development
  }

  /// Get the user's referral code
  Future<String?> getReferralCode() async {
    return 'MOCK1234'; // Return mock referral code in development
  }

  /// Check if the user has enough points for a purchase
  Future<bool> hasEnoughPoints(int amount) async {
    return true; // Assume user has enough points in development
  }
}
