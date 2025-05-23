import 'package:supabase_flutter/supabase_flutter.dart';

/// Interface for Supabase service
abstract class SupabaseServiceInterface {
  /// Initialize the Supabase client
  Future<void> initialize();

  /// Get the Supabase client instance
  SupabaseClient get client;

  /// Get the current user
  User? get currentUser;

  /// Get the current session
  Session? get currentSession;

  /// Get the Supabase public anonymous key
  String get supabaseAnonKey;

  /// Ensure the session is valid and refresh it if needed
  /// Returns true if a valid session exists or was successfully refreshed
  /// Returns false if no session exists or refresh failed
  Future<bool> ensureValidSession();

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword(
      String email, String password);

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmailAndPassword(
      String email, String password);

  /// Sign out the current user
  Future<void> signOut();

  /// Reset password
  Future<void> resetPassword(String email);

  /// Update user data
  Future<void> updateUserData(Map<String, dynamic> userData);
}
