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

  /// Private constructor
  AuthService._internal();

  /// Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Google Sign In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
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
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was canceled');
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
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Apply referral code during registration
  /// This should be called after successful registration
  Future<void> applyReferralCode(String referralCode) async {
    try {
      // Check if the user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if the referral code exists
      final codeDoc =
          await _firestore.collection('referralCodes').doc(referralCode).get();

      if (!codeDoc.exists) {
        throw Exception('Invalid referral code');
      }

      final codeData = codeDoc.data() as Map<String, dynamic>;

      // Check if the code is active
      if (!(codeData['isActive'] ?? true)) {
        throw Exception('Referral code is inactive');
      }

      // Check if the code has expired
      final expiryDate = (codeData['expiryDate'] as Timestamp).toDate();
      if (expiryDate.isBefore(DateTime.now())) {
        throw Exception('Referral code has expired');
      }

      // Update the user document with the referral code
      await _firestore.collection('users').doc(user.uid).update({
        'referredBy': referralCode,
      });

      // Note: The actual point bonuses will be handled by Cloud Functions
    } catch (e) {
      print('Error applying referral code: $e');
      rethrow;
    }
  }
}
