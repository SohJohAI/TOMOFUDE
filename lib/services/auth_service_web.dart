// This is a web-specific version of auth_service.dart that doesn't use Firebase
// to avoid compatibility issues with Firebase web packages

import 'auth_service_interface.dart';
import 'package:flutter/foundation.dart';

/// Service for handling user authentication.
///
/// This service provides methods for user registration, login, and logout
/// using Firebase Authentication.
class AuthService implements AuthServiceInterface {
  /// Singleton instance
  static final AuthService _instance = AuthService._internal();

  /// Factory constructor to return the same instance
  factory AuthService() => _instance;

  /// Private constructor
  AuthService._internal() {
    // Constructor is empty, initialization is done in initialize() method
  }

  /// Initialize the service
  @override
  Future<void> initialize() async {
    debugPrint('Web version of AuthService initialized, Firebase is disabled');
  }

  /// Get current user
  @override
  dynamic get currentUser {
    return null;
  }

  /// Stream of auth state changes
  @override
  Stream<dynamic> get authStateChanges {
    // Return an empty stream
    return Stream.value(null);
  }

  /// Sign up with email and password
  @override
  Future<dynamic> signUpWithEmail(String email, String password) async {
    debugPrint('Firebase not initialized on web, cannot sign up');
    return null;
  }

  /// Sign in with email and password
  @override
  Future<dynamic> signInWithEmail(String email, String password) async {
    debugPrint('Firebase not initialized on web, cannot sign in');
    return null;
  }

  /// Sign in with Google
  @override
  Future<dynamic> signInWithGoogle() async {
    debugPrint('Firebase not initialized on web, cannot sign in with Google');
    return null;
  }

  /// Sign out
  @override
  Future<void> signOut() async {
    debugPrint('Firebase not initialized on web, cannot sign out');
    return;
  }

  /// Apply referral code during registration
  @override
  Future<bool> applyReferralCode(String referralCode) async {
    debugPrint('Firebase not initialized on web, cannot apply referral code');
    return false;
  }
}
