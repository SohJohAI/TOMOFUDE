import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling user authentication.
///
/// This service provides methods for user registration, login, and logout
/// using Firebase Authentication.
class AuthService {
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
      print('Firebase Auth initialized successfully');
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
      final userCredential = await _auth.signInWithCredential(credential);

      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
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

      // Validate code format
      if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(referralCode)) {
        print('Invalid referral code format');
        return false;
      }

      // Check if the referral code exists
      final codeQuery = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (codeQuery.docs.isEmpty) {
        print('Invalid referral code');
        return false;
      }

      final referrerDoc = codeQuery.docs.first;
      final referrerId = referrerDoc.id;

      // Check if the user is trying to use their own code
      if (referrerId == user.uid) {
        print('Cannot use own referral code');
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
    } catch (e) {
      print('Error applying referral code: $e');
      return false;
    }
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
