import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling user authentication.
///
/// This service provides methods for user registration, login, and logout
/// using Firebase Authentication.
///
/// Note: This requires Firebase packages to be installed.
/// Run 'flutter pub get' after adding Firebase dependencies to pubspec.yaml.
class AuthService {
  // This class will be implemented after Firebase setup

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
    try {
      _auth = FirebaseAuth.instance;
      _googleSignIn = GoogleSignIn();
      _firestore = FirebaseFirestore.instance;
      _isFirebaseInitialized = true;
    } catch (e) {
      print('Firebase not initialized in AuthService: $e');
      _isFirebaseInitialized = false;
    }
  }

  /// Get current user
  User? get currentUser {
    if (!_isFirebaseInitialized) return null;
    try {
      return _auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Stream of auth state changes
  Stream<User?> get authStateChanges {
    if (!_isFirebaseInitialized) {
      // Return an empty stream if Firebase is not initialized
      return Stream.value(null);
    }
    try {
      return _auth.authStateChanges();
    } catch (e) {
      print('Error getting auth state changes: $e');
      return Stream.value(null);
    }
  }

  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized, cannot sign up');
      return null;
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // User creation in Firestore will be handled by Cloud Functions
      // through the onUserCreate trigger

      return credential;
    } catch (e) {
      print('Error signing up with email: $e');
      return null;
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized, cannot sign in');
      return null;
    }

    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in with email: $e');
      return null;
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized, cannot sign in with Google');
      return null;
    }

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google sign in was canceled');
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
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized, cannot sign out');
      return;
    }

    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Apply referral code during registration
  /// This should be called after successful registration
  Future<bool> applyReferralCode(String referralCode) async {
    if (!_isFirebaseInitialized) {
      print('Firebase not initialized, cannot apply referral code');
      return false;
    }

    try {
      // Check if the user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated');
        return false;
      }

      // Check if the referral code exists
      final codeDoc =
          await _firestore.collection('referralCodes').doc(referralCode).get();

      if (!codeDoc.exists) {
        print('Invalid referral code');
        return false;
      }

      final codeData = codeDoc.data() as Map<String, dynamic>;

      // Check if the code is active
      if (!(codeData['isActive'] ?? true)) {
        print('Referral code is inactive');
        return false;
      }

      // Check if the code has expired
      final expiryDate = (codeData['expiryDate'] as Timestamp).toDate();
      if (expiryDate.isBefore(DateTime.now())) {
        print('Referral code has expired');
        return false;
      }

      // Update the user document with the referral code
      await _firestore.collection('users').doc(user.uid).update({
        'referredBy': referralCode,
      });

      // Note: The actual point bonuses will be handled by Cloud Functions
      return true;
    } catch (e) {
      print('Error applying referral code: $e');
      return false;
    }
  }
}
