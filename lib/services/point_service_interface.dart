import '../models/user_point.dart';
import '../models/point_history.dart';

/// Interface for point-related services
///
/// This interface defines the contract for point-related services,
/// allowing for different implementations (e.g., Firebase, mock, etc.)
abstract class PointServiceInterface {
  /// Initialize the service
  ///
  /// This method should be called before using the service.
  Future<void> initialize();

  /// Get current user's point information
  Future<UserPoint?> getUserPoint();

  /// Get user's point history
  Future<List<PointHistory>> getPointHistory({int limit = 50});

  /// Consume points for a specific purpose
  Future<bool> consumePoints(int amount, String purpose);

  /// Apply a referral code to get bonus points
  Future<bool> applyReferralCode(String code);

  /// Get the user's referral code
  Future<String?> getReferralCode();

  /// Check if the user has enough points for a purchase
  Future<bool> hasEnoughPoints(int amount);
}
