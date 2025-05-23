import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../utils/error_handler.dart';
import 'auth_service_interface.dart';
import 'supabase_service_interface.dart';
import 'service_locator.dart';

/// A user class that maps Supabase User to the app's User model
class User {
  final String uid;
  final String email;
  final String? displayName;

  User({
    required this.uid,
    required this.email,
    this.displayName,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
    );
  }

  /// Create a User from a Supabase User
  factory User.fromSupabaseUser(supabase.User supabaseUser) {
    return User(
      uid: supabaseUser.id,
      email: supabaseUser.email ?? '',
      displayName: supabaseUser.userMetadata?['name'] as String? ??
          supabaseUser.email?.split('@').first,
    );
  }
}

/// A user credential class that wraps Supabase AuthResponse
class UserCredential {
  final User? user;
  final bool isNewUser;

  UserCredential({
    this.user,
    this.isNewUser = false,
  });

  /// Create a UserCredential from a Supabase AuthResponse
  factory UserCredential.fromAuthResponse(supabase.AuthResponse response) {
    final supabaseUser = response.user;
    return UserCredential(
      user: supabaseUser != null ? User.fromSupabaseUser(supabaseUser) : null,
      // Determine if this is a new user based on the response
      isNewUser: response.session != null && response.user?.createdAt != null,
    );
  }
}

/// Service for handling user authentication using Supabase for web platforms.
///
/// This service provides methods for user registration, login, and logout
/// using Supabase Authentication on web platforms.
class AuthService implements AuthServiceInterface {
  /// Singleton instance
  static final AuthService _instance = AuthService._internal();

  /// Factory constructor to return the same instance
  factory AuthService() => _instance;

  /// The Supabase service
  final SupabaseServiceInterface _supabaseService;

  /// Stream controller for auth state changes
  final _authStateController = StreamController<User?>.broadcast();

  /// Private constructor
  AuthService._internal()
      : _supabaseService = serviceLocator<SupabaseServiceInterface>() {
    // Listen for auth state changes from Supabase
    _supabaseService.client.auth.onAuthStateChange.listen((data) {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;

      switch (event) {
        case supabase.AuthChangeEvent.signedIn:
        case supabase.AuthChangeEvent.userUpdated:
          if (session?.user != null) {
            final user = User.fromSupabaseUser(session!.user);
            _authStateController.add(user);
          }
          break;
        case supabase.AuthChangeEvent.signedOut:
        case supabase.AuthChangeEvent.userDeleted:
          _authStateController.add(null);
          break;
        default:
          break;
      }
    });
  }

  /// Initialize the service
  @override
  Future<void> initialize() async {
    return errorHandler.handleAsync(
      () async {
        print('Supabase AuthService for Web initialized');

        // Check if there's already a session
        final session = _supabaseService.currentSession;
        if (session?.user != null) {
          final user = User.fromSupabaseUser(session!.user);
          _authStateController.add(user);
        }
      },
      'AuthService.initialize',
      '認証サービスの初期化中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
      },
    );
  }

  /// Get current user
  @override
  User? get currentUser {
    final supabaseUser = _supabaseService.currentUser;
    if (supabaseUser == null) return null;
    return User.fromSupabaseUser(supabaseUser);
  }

  /// Stream of auth state changes
  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  /// Sign up with email and password
  @override
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    return errorHandler.handleAsync<UserCredential?>(
      () async {
        final response = await _supabaseService.signUpWithEmailAndPassword(
          email,
          password,
        );

        // Create user record in the users table
        if (response.user != null) {
          try {
            await _supabaseService.updateUserData({
              'email': email,
              'plan': 'free',
              'points': 300,
            });
          } catch (e) {
            print('Error creating user record: $e');
            // Continue even if this fails, as the auth record is created
          }
        }

        return UserCredential.fromAuthResponse(response);
      },
      'AuthService.signUpWithEmail',
      'アカウント登録中にエラーが発生しました',
    );
  }

  /// Sign in with email and password
  @override
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    return errorHandler.handleAsync<UserCredential?>(
      () async {
        final response = await _supabaseService.signInWithEmailAndPassword(
          email,
          password,
        );

        return UserCredential.fromAuthResponse(response);
      },
      'AuthService.signInWithEmail',
      'ログイン中にエラーが発生しました',
    );
  }

  /// Sign in with Google
  @override
  Future<UserCredential?> signInWithGoogle() async {
    return errorHandler.handleAsync<UserCredential?>(
      () async {
        // Supabase doesn't have a direct method for Google sign-in in this implementation
        // This would need to be implemented using OAuth or a provider
        throw UnimplementedError(
            'Google sign-in is not implemented with Supabase yet');
      },
      'AuthService.signInWithGoogle',
      'Googleログイン中にエラーが発生しました',
    );
  }

  /// Sign out
  @override
  Future<void> signOut() async {
    return errorHandler.handleAsync(
      () async {
        await _supabaseService.signOut();
      },
      'AuthService.signOut',
      'ログアウト中にエラーが発生しました',
    );
  }

  /// Apply referral code during registration
  @override
  Future<bool> applyReferralCode(String referralCode) async {
    // This would need to be implemented with Supabase database operations
    // For now, return false as it's not implemented
    return false;
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
