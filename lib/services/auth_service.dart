import 'package:flutter/foundation.dart' show kIsWeb;

// Import Firebase packages conditionally
import '../auth_imports.dart' if (dart.library.html) '../auth_imports_web.dart';
import '../utils/error_handler.dart';
import 'auth_service_interface.dart';

/// Service for handling user authentication.
///
/// This service provides methods for user registration, login, and logout
/// using Firebase Authentication.
class AuthService implements AuthServiceInterface {
  /// Singleton instance
  static final AuthService _instance = AuthService._internal();

  /// Factory constructor to return the same instance
  factory AuthService() => _instance;

  /// Firebase Auth instance
  late final FirebaseAuth _auth;

  /// Google Sign In instance
  late final GoogleSignIn _googleSignIn;

  /// Firestore instance
  late final FirebaseFirestore _firestore;

  /// Flag indicating whether Firebase is initialized
  bool _isFirebaseInitialized = false;

  /// Private constructor
  AuthService._internal() {
    // Constructor is empty, initialization is done in initialize() method
  }

  /// Initialize the service
  @override
  Future<void> initialize() async {
    return errorHandler.handleAsync(
      () async {
        // Skip Firebase initialization on web platform
        if (kIsWeb) {
          print(
              'Running on web platform, skipping Firebase Auth initialization');
          _isFirebaseInitialized = false;
          return;
        }

        _auth = FirebaseAuth.instance;
        _googleSignIn = GoogleSignIn();
        _firestore = FirebaseFirestore.instance;
        _isFirebaseInitialized = true;
        print('Firebase Auth initialized successfully');
      },
      'AuthService.initialize',
      '認証サービスの初期化中にエラーが発生しました',
      onError: (errorMessage) {
        _isFirebaseInitialized = false;
        print(errorMessage);
      },
    );
  }

  /// Get current user
  User? get currentUser {
    if (!_isFirebaseInitialized) {
      errorHandler.logError(
        'Firebase not initialized',
        'AuthService.currentUser',
      );
      return null;
    }

    try {
      return _auth.currentUser;
    } catch (e) {
      errorHandler.logError(
        e,
        'AuthService.currentUser',
      );
      return null;
    }
  }

  /// Stream of auth state changes
  Stream<User?> get authStateChanges {
    if (!_isFirebaseInitialized) {
      errorHandler.logError(
        'Firebase not initialized',
        'AuthService.authStateChanges',
      );
      // Return an empty stream if Firebase is not initialized
      return Stream.value(null);
    }

    try {
      return _auth.authStateChanges();
    } catch (e) {
      errorHandler.logError(
        e,
        'AuthService.authStateChanges',
      );
      return Stream.value(null);
    }
  }

  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    if (!_isFirebaseInitialized) {
      errorHandler.logError(
        'Firebase not initialized',
        'AuthService.signUpWithEmail',
      );
      return null;
    }

    return errorHandler.handleAsync<UserCredential?>(
      () async {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Create user document in Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'displayName': email.split('@')[0],
          'createdAt': FieldValue.serverTimestamp(),
          'point': 1000, // Initial free points
          'freePoint': 1000,
          'paidPoint': 0,
          'referralCode': _generateReferralCode(),
        });

        return credential;
      },
      'AuthService.signUpWithEmail',
      'アカウント登録中にエラーが発生しました',
    );
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (!_isFirebaseInitialized) {
      errorHandler.logError(
        'Firebase not initialized',
        'AuthService.signInWithEmail',
      );
      return null;
    }

    return errorHandler.handleAsync<UserCredential?>(
      () async {
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      },
      'AuthService.signInWithEmail',
      'ログイン中にエラーが発生しました',
    );
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    if (!_isFirebaseInitialized) {
      errorHandler.logError(
        'Firebase not initialized',
        'AuthService.signInWithGoogle',
      );
      return null;
    }

    return errorHandler.handleAsync<UserCredential?>(
      () async {
        // Trigger the authentication flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          errorHandler.logError(
            'Google sign in was canceled',
            'AuthService.signInWithGoogle',
          );
          return null;
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        final userCredential = await _auth.signInWithCredential(credential);

        // Check if this is a new user
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          // Create user document in Firestore
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName,
            'createdAt': FieldValue.serverTimestamp(),
            'point': 1000, // Initial free points
            'freePoint': 1000,
            'paidPoint': 0,
            'referralCode': _generateReferralCode(),
          });
        }

        return userCredential;
      },
      'AuthService.signInWithGoogle',
      'Googleログイン中にエラーが発生しました',
    );
  }

  /// Sign out
  Future<void> signOut() async {
    if (!_isFirebaseInitialized) {
      errorHandler.logError(
        'Firebase not initialized',
        'AuthService.signOut',
      );
      return;
    }

    return errorHandler.handleAsync(
      () async {
        await _googleSignIn.signOut();
        await _auth.signOut();
      },
      'AuthService.signOut',
      'ログアウト中にエラーが発生しました',
    );
  }

  /// Apply referral code during registration
  Future<bool> applyReferralCode(String referralCode) async {
    if (!_isFirebaseInitialized) {
      errorHandler.logError(
        'Firebase not initialized',
        'AuthService.applyReferralCode',
      );
      return false;
    }

    final result = await errorHandler.handleAsync<bool>(
      () async {
        // Check if the user is authenticated
        final user = _auth.currentUser;
        if (user == null) {
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

        // Check if the referral code exists
        final codeQuery = await _firestore
            .collection('users')
            .where('referralCode', isEqualTo: referralCode)
            .limit(1)
            .get();

        if (codeQuery.docs.isEmpty) {
          errorHandler.logError(
            'Invalid referral code',
            'AuthService.applyReferralCode',
          );
          return false;
        }

        final referrerDoc = codeQuery.docs.first;
        final referrerId = referrerDoc.id;

        // Check if the user is trying to use their own code
        if (referrerId == user.uid) {
          errorHandler.logError(
            'Cannot use own referral code',
            'AuthService.applyReferralCode',
          );
          return false;
        }

        // Update the user document with the referral code
        await _firestore.collection('users').doc(user.uid).update({
          'referredBy': referralCode,
          'referredById': referrerId,
        });

        // Add points to the referrer
        await _firestore.collection('users').doc(referrerId).update({
          'point': FieldValue.increment(500),
          'freePoint': FieldValue.increment(500),
        });

        // Add points to the user
        await _firestore.collection('users').doc(user.uid).update({
          'point': FieldValue.increment(500),
          'freePoint': FieldValue.increment(500),
        });

        // Add to referral history
        await _firestore
            .collection('users')
            .doc(referrerId)
            .collection('referrals')
            .add({
          'referredUserId': user.uid,
          'referredUserEmail': user.email,
          'timestamp': FieldValue.serverTimestamp(),
          'points': 500,
        });

        // Add to point history for referrer
        await _firestore
            .collection('users')
            .doc(referrerId)
            .collection('history')
            .add({
          'type': 'referral_bonus',
          'amount': 500,
          'description': '紹介ボーナス',
          'timestamp': FieldValue.serverTimestamp(),
          'expiryDate': DateTime.now().add(const Duration(days: 90)),
        });

        // Add to point history for user
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .add({
          'type': 'referral_bonus',
          'amount': 500,
          'description': '紹介ボーナス',
          'timestamp': FieldValue.serverTimestamp(),
          'expiryDate': DateTime.now().add(const Duration(days: 90)),
        });

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
