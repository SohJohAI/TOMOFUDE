import 'package:flutter/foundation.dart';
import '../models/user_point.dart';
import '../models/point_history.dart';
import '../services/point_service.dart';
import '../services/auth_service.dart';

/// Provider for managing payment-related state.
///
/// This provider manages the state of the user's points, referral code,
/// and point history.
class PaymentProvider with ChangeNotifier {
  final PointService _pointService = PointService();
  final AuthService _authService = AuthService();

  UserPoint? _userPoint;
  List<PointHistory> _pointHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// Gets the current user's point information.
  UserPoint? get userPoint => _userPoint;

  /// Gets the current user's point history.
  List<PointHistory> get pointHistory => _pointHistory;

  /// Gets whether the provider is currently loading data.
  bool get isLoading => _isLoading;

  /// Gets the error message, if any.
  String? get errorMessage => _errorMessage;

  /// Gets whether the user is authenticated.
  bool get isAuthenticated {
    try {
      final user = _authService.currentUser;
      return user != null;
    } catch (e) {
      // Handle the case when Firebase Auth is not initialized
      print('Error checking authentication: $e');
      return false;
    }
  }

  /// Initializes the provider.
  ///
  /// This method is called when the provider is first created.
  /// It loads the user's point information and point history.
  Future<void> initialize() async {
    try {
      if (!isAuthenticated) return;

      await Future.wait([
        loadUserPoint(),
        loadPointHistory(),
      ]);
    } catch (e) {
      // Handle initialization errors
      print('Error initializing PaymentProvider: $e');
      _setError('Firebase may not be properly initialized: $e');
    }
  }

  /// Loads the user's point information.
  Future<void> loadUserPoint() async {
    if (!isAuthenticated) return;

    _setLoading(true);
    _clearError();

    try {
      _userPoint = await _pointService.getUserPoint();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user point: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Loads the user's point history.
  Future<void> loadPointHistory() async {
    if (!isAuthenticated) return;

    _setLoading(true);
    _clearError();

    try {
      _pointHistory = await _pointService.getPointHistory();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load point history: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Applies a referral code.
  ///
  /// Returns true if the referral code was applied successfully.
  Future<bool> applyReferralCode(String code) async {
    if (!isAuthenticated) return false;

    _setLoading(true);
    _clearError();

    try {
      final success = await _pointService.applyReferralCode(code);

      if (success) {
        // Reload user point and point history
        await loadUserPoint();
        await loadPointHistory();
      }

      return success;
    } catch (e) {
      _setError('Failed to apply referral code: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Consumes points for a specific purpose.
  ///
  /// Returns true if the points were consumed successfully.
  Future<bool> consumePoints(int amount, String purpose) async {
    if (!isAuthenticated) return false;

    _setLoading(true);
    _clearError();

    try {
      final success = await _pointService.consumePoints(amount, purpose);

      if (success) {
        // Reload user point and point history
        await loadUserPoint();
        await loadPointHistory();
      }

      return success;
    } catch (e) {
      _setError('Failed to consume points: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Checks if the user has enough points for a purchase.
  Future<bool> hasEnoughPoints(int amount) async {
    if (!isAuthenticated) return false;

    if (_userPoint != null) {
      return _userPoint!.point >= amount;
    }

    return await _pointService.hasEnoughPoints(amount);
  }

  /// Sets the loading state.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Sets an error message.
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clears the error message.
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
