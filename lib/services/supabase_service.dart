import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service_interface.dart';

/// Implementation of the Supabase service
class SupabaseService implements SupabaseServiceInterface {
  /// Supabase URL - Replace with your Supabase URL
  static const String _supabaseUrl = 'https://awbrfvdyokwkpwrqmfwd.supabase.co';

  /// Supabase API Key - Replace with your Supabase API Key
  static const String _supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3YnJmdmR5b2t3a3B3cnFtZndkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ3MTcwODQsImV4cCI6MjA2MDI5MzA4NH0.e57mIz0nhuZpm-scH6k60w4ugzMNinaSthQTaeTZ2SQ';

  /// Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();

  /// Factory constructor
  factory SupabaseService() => _instance;

  /// Private constructor
  SupabaseService._internal();

  /// Initialize the Supabase client
  @override
  Future<void> initialize() async {
    // Check if Supabase is already initialized
    try {
      // If Supabase.instance can be accessed without error, it's already initialized
      Supabase.instance.client;
      print('SupabaseService: Supabase already initialized');
    } catch (e) {
      // If accessing Supabase.instance throws an error, initialize it
      print('SupabaseService: Initializing Supabase');
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseKey,
      );
    }
  }

  /// Get the Supabase client instance
  @override
  SupabaseClient get client => Supabase.instance.client;

  /// Get the current user
  @override
  User? get currentUser => client.auth.currentUser;

  /// Get the current session
  @override
  Session? get currentSession => client.auth.currentSession;

  /// Get the Supabase public anonymous key
  @override
  String get supabaseAnonKey => _supabaseKey;

  /// Sign in with email and password
  @override
  Future<AuthResponse> signInWithEmailAndPassword(
      String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  @override
  Future<AuthResponse> signUpWithEmailAndPassword(
      String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign out the current user
  @override
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Reset password
  @override
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// Update user data
  @override
  Future<void> updateUserData(Map<String, dynamic> userData) async {
    await client.from('users').upsert(userData).eq('id', currentUser?.id ?? '');
  }

  /// Ensure the session is valid and refresh it if needed
  /// Returns true if a valid session exists or was successfully refreshed
  /// Returns false if no session exists or refresh failed
  @override
  Future<bool> ensureValidSession() async {
    final session = client.auth.currentSession;

    if (session == null) {
      print('SupabaseService: No session exists');
      return false; // セッションなし
    }

    final expiresAt = session.expiresAt;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 期限切れが近い場合（5分以内）にリフレッシュ
    if (expiresAt != null && expiresAt - now < 300) {
      try {
        print('SupabaseService: Session expiring soon, refreshing...');
        await client.auth.refreshSession();
        print('SupabaseService: Session refreshed successfully');
        return true;
      } catch (e) {
        print('SupabaseService: Session refresh error: $e');
        return false;
      }
    }

    return true; // 有効なセッションあり
  }
}
