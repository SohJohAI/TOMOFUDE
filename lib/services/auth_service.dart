import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/error_handler.dart';
import 'auth_service_interface.dart';

/// A simple user class to replace Firebase User
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
}

/// A simple user credential class to replace Firebase UserCredential
class UserCredential {
  final User? user;
  final bool isNewUser;

  UserCredential({
    this.user,
    this.isNewUser = false,
  });
}

/// Service for handling user authentication.
///
/// This service provides methods for user registration, login, and logout
/// using local storage instead of Firebase Authentication.
class AuthService implements AuthServiceInterface {
  /// Singleton instance
  static final AuthService _instance = AuthService._internal();

  /// Factory constructor to return the same instance
  factory AuthService() => _instance;

  /// Current user
  User? _currentUser;

  /// Auth state controller
  final _authStateController = Stream<User?>.empty().asBroadcastStream();

  /// Key for storing users in SharedPreferences
  static const String _usersKey = 'auth_users';

  /// Key for storing current user in SharedPreferences
  static const String _currentUserKey = 'auth_current_user';

  /// Private constructor
  AuthService._internal() {
    // Constructor is empty, initialization is done in initialize() method
  }

  /// Initialize the service
  @override
  Future<void> initialize() async {
    return errorHandler.handleAsync(
      () async {
        print('Local AuthService initialized');

        // Load current user from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final currentUserJson = prefs.getString(_currentUserKey);

        if (currentUserJson != null) {
          final Map<String, dynamic> json = jsonDecode(currentUserJson);
          _currentUser = User.fromJson(json);
          print('Loaded current user: ${_currentUser?.email}');
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
  User? get currentUser => _currentUser;

  /// Stream of auth state changes
  @override
  Stream<User?> get authStateChanges => _authStateController;

  /// Sign up with email and password
  @override
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    return errorHandler.handleAsync<UserCredential?>(
      () async {
        // Check if user already exists
        final users = await _getUsers();
        final existingUser = users.where((u) => u['email'] == email).toList();

        if (existingUser.isNotEmpty) {
          throw Exception('User with this email already exists');
        }

        // Create new user
        final uid = const Uuid().v4();
        final user = User(
          uid: uid,
          email: email,
          displayName: email.split('@')[0],
        );

        // Add user to users list
        users.add({
          'uid': uid,
          'email': email,
          'password': password, // In a real app, this should be hashed
          'displayName': user.displayName,
          'createdAt': DateTime.now().toIso8601String(),
          'referralCode': _generateReferralCode(),
        });

        // Save users
        await _saveUsers(users);

        // Set as current user
        _currentUser = user;
        await _saveCurrentUser(user);

        return UserCredential(user: user, isNewUser: true);
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
        // Get users
        final users = await _getUsers();

        // Find user with matching email and password
        final userJson = users.firstWhere(
          (u) => u['email'] == email && u['password'] == password,
          orElse: () => throw Exception('Invalid email or password'),
        );

        // Create user object
        final user = User(
          uid: userJson['uid'],
          email: userJson['email'],
          displayName: userJson['displayName'],
        );

        // Set as current user
        _currentUser = user;
        await _saveCurrentUser(user);

        return UserCredential(user: user, isNewUser: false);
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
        // This is a mock implementation
        print('Mock Google sign in');

        // Create a mock user
        final uid = const Uuid().v4();
        final user = User(
          uid: uid,
          email: 'google_user@example.com',
          displayName: 'Google User',
        );

        // Check if user already exists
        final users = await _getUsers();
        final existingUser =
            users.where((u) => u['email'] == user.email).toList();

        bool isNewUser = false;

        if (existingUser.isEmpty) {
          // Add user to users list
          users.add({
            'uid': uid,
            'email': user.email,
            'password': '', // No password for Google sign in
            'displayName': user.displayName,
            'createdAt': DateTime.now().toIso8601String(),
            'referralCode': _generateReferralCode(),
          });

          // Save users
          await _saveUsers(users);
          isNewUser = true;
        }

        // Set as current user
        _currentUser = user;
        await _saveCurrentUser(user);

        return UserCredential(user: user, isNewUser: isNewUser);
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
        _currentUser = null;

        // Remove current user from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_currentUserKey);
      },
      'AuthService.signOut',
      'ログアウト中にエラーが発生しました',
    );
  }

  /// Apply referral code during registration
  @override
  Future<bool> applyReferralCode(String referralCode) async {
    final result = await errorHandler.handleAsync<bool>(
      () async {
        // Check if the user is authenticated
        if (_currentUser == null) {
          errorHandler.logError(
            'User not authenticated',
            'AuthService.applyReferralCode',
          );
          return false;
        }

        // Validate code format
        if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(referralCode)) {
          errorHandler.logError(
            'Invalid referral code format',
            'AuthService.applyReferralCode',
          );
          return false;
        }

        // Get users
        final users = await _getUsers();

        // Find user with matching referral code
        final referrerList =
            users.where((u) => u['referralCode'] == referralCode).toList();

        if (referrerList.isEmpty) {
          errorHandler.logError(
            'Invalid referral code',
            'AuthService.applyReferralCode',
          );
          return false;
        }

        final referrer = referrerList.first;

        // Check if the user is trying to use their own code
        if (referrer['uid'] == _currentUser?.uid) {
          errorHandler.logError(
            'Cannot use own referral code',
            'AuthService.applyReferralCode',
          );
          return false;
        }

        // Find current user in users list
        final currentUserIndex =
            users.indexWhere((u) => u['uid'] == _currentUser?.uid);

        if (currentUserIndex == -1) {
          errorHandler.logError(
            'Current user not found in users list',
            'AuthService.applyReferralCode',
          );
          return false;
        }

        // Update current user with referral code
        users[currentUserIndex]['referredBy'] = referralCode;
        users[currentUserIndex]['referredById'] = referrer['uid'];

        // Save users
        await _saveUsers(users);

        return true;
      },
      'AuthService.applyReferralCode',
      '紹介コードの適用中にエラーが発生しました',
      onError: (errorMessage) {
        print(errorMessage);
        return false;
      },
    );

    return result ?? false;
  }

  /// Get users from SharedPreferences
  Future<List<Map<String, dynamic>>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey);

    if (usersJson == null) {
      return [];
    }

    return usersJson
        .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
        .toList();
  }

  /// Save users to SharedPreferences
  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = users.map((user) => jsonEncode(user)).toList();
    await prefs.setStringList(_usersKey, usersJson);
  }

  /// Save current user to SharedPreferences
  Future<void> _saveCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
  }

  /// Generate a random referral code
  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final code = List.generate(8, (index) {
      final randomIndex =
          (random.codeUnitAt(index % random.length) + index) % chars.length;
      return chars[randomIndex];
    }).join();
    return code;
  }
}
