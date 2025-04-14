import 'dart:async';

/// Service for handling user authentication.
///
/// This service provides methods for user registration, login, and logout.
/// It uses a mock implementation when Firebase is not available.
class AuthService {
  /// Singleton instance
  static final AuthService _instance = AuthService._internal();

  /// Factory constructor to return the same instance
  factory AuthService() => _instance;

  /// Flag indicating whether Firebase is initialized
  bool _isFirebaseInitialized = false;

  /// Mock user data
  final Map<String, dynamic>? _mockUser = {
    'uid': 'mock-user-id',
    'email': 'user@example.com',
    'displayName': 'Mock User',
  };

  /// Private constructor
  AuthService._internal() {
    // Firebase initialization is disabled for now
    _isFirebaseInitialized = false;
    print('Using mock AuthService implementation');
  }

  /// Get current user
  Map<String, dynamic>? get currentUser {
    // Return mock user data
    return _mockUser;
  }

  /// Stream of auth state changes
  Stream<Map<String, dynamic>?> get authStateChanges {
    // Return a stream with mock user data
    return Stream.value(_mockUser);
  }

  /// Sign up with email and password
  Future<Map<String, dynamic>?> signUpWithEmail(
      String email, String password) async {
    print('Mock sign up with email: $email');
    return _mockUser;
  }

  /// Sign in with email and password
  Future<Map<String, dynamic>?> signInWithEmail(
      String email, String password) async {
    print('Mock sign in with email: $email');
    return _mockUser;
  }

  /// Sign in with Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    print('Mock sign in with Google');
    return _mockUser;
  }

  /// Sign out
  Future<void> signOut() async {
    print('Mock sign out');
  }

  /// Apply referral code during registration
  Future<bool> applyReferralCode(String referralCode) async {
    print('Mock apply referral code: $referralCode');

    // Validate code format
    if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(referralCode)) {
      return false;
    }

    // Simulate success for valid format
    return true;
  }
}
