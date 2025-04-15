import 'package:flutter/foundation.dart' show kIsWeb;

/// Interface for authentication services
///
/// This interface defines the contract for authentication services,
/// allowing for different implementations (e.g., Firebase, mock, etc.)
abstract class AuthServiceInterface {
  /// Initialize the service
  ///
  /// This method should be called before using the service.
  Future<void> initialize();

  /// Get current user
  dynamic get currentUser;

  /// Stream of auth state changes
  Stream<dynamic> get authStateChanges;

  /// Sign up with email and password
  Future<dynamic> signUpWithEmail(String email, String password);

  /// Sign in with email and password
  Future<dynamic> signInWithEmail(String email, String password);

  /// Sign in with Google
  Future<dynamic> signInWithGoogle();

  /// Sign out
  Future<void> signOut();

  /// Apply referral code during registration
  Future<bool> applyReferralCode(String referralCode);
}
