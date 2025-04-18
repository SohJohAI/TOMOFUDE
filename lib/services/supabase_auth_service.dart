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

/// Service for handling user authentication using Supabase.
///
/// This service provides methods for user registration, login, and logout
/// using Supabase Authentication.
class SupabaseAuthService implements AuthServiceInterface {
  /// Singleton instance
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();

  /// Factory constructor to return the same instance
  factory SupabaseAuthService() => _instance;

  /// The Supabase service
  final SupabaseServiceInterface _supabaseService;

  /// Stream controller for auth state changes
  final _authStateController = StreamController<User?>.broadcast();

  /// Private constructor
  SupabaseAuthService._internal()
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
        print('Supabase AuthService initialized');

        // Check if there's already a session
        final session = _supabaseService.currentSession;
        if (session?.user != null) {
          final user = User.fromSupabaseUser(session!.user);
          _authStateController.add(user);
        }
      },
      'SupabaseAuthService.initialize',
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

        final user = response.user;
        if (user == null) {
          // ユーザーがnullの場合はメール確認待ちの可能性がある
          print('ユーザー登録済みだがメール確認待ち状態。');
          // ここでUIに案内を表示する処理を追加できる
        } else {
          // ユーザーが取得できた場合のみデータを登録
          try {
            // response.userから直接IDを取得して使用
            await _supabaseService.client.from('users').insert({
              'id': user.id,
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
      'SupabaseAuthService.signUpWithEmail',
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
      'SupabaseAuthService.signInWithEmail',
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
      'SupabaseAuthService.signInWithGoogle',
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
      'SupabaseAuthService.signOut',
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
