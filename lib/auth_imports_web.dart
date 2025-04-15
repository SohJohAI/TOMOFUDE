// This file contains mock Firebase Auth implementations for web platforms
import 'package:js/js.dart';
import 'firebase_web_fix.dart';

// Mock User class
class User {
  final String uid = 'mock-user-id';
  final String? email = 'mock@example.com';
  final String? displayName = 'Mock User';

  Future<void> delete() async {
    print('Mock User.delete');
    return Future.value();
  }

  Future<String> getIdToken([bool? forceRefresh]) async {
    print('Mock User.getIdToken');
    return 'mock-id-token';
  }

  Future<IdTokenResult> getIdTokenResult([bool? forceRefresh]) async {
    print('Mock User.getIdTokenResult');
    return IdTokenResult();
  }

  Future<void> reload() async {
    print('Mock User.reload');
    return Future.value();
  }
}

// Mock IdTokenResult class
class IdTokenResult {
  final String token = 'mock-token';
  final DateTime authTime = DateTime.now();
  final DateTime issuedAtTime = DateTime.now();
  final DateTime expirationTime = DateTime.now().add(Duration(hours: 1));
  final Map<String, dynamic> claims = {};
}

// Mock UserCredential class
class UserCredential {
  final User? user = User();
  final AdditionalUserInfo? additionalUserInfo = AdditionalUserInfo();
}

// Mock AdditionalUserInfo class
class AdditionalUserInfo {
  final bool isNewUser = false;
}

// Mock FirebaseAuth class
class FirebaseAuth {
  static final FirebaseAuth _instance = FirebaseAuth._();
  static FirebaseAuth get instance => _instance;

  FirebaseAuth._();

  User? get currentUser => null;

  Stream<User?> authStateChanges() {
    return Stream.value(null);
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    print('Mock createUserWithEmailAndPassword: $email');
    return UserCredential();
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    print('Mock signInWithEmailAndPassword: $email');
    return UserCredential();
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    print('Mock signInWithCredential');
    return UserCredential();
  }

  Future<void> signOut() async {
    print('Mock signOut');
  }
}

// Mock GoogleSignIn class
class GoogleSignIn {
  Future<GoogleSignInAccount?> signIn() async {
    print('Mock GoogleSignIn.signIn');
    return null;
  }

  Future<void> signOut() async {
    print('Mock GoogleSignIn.signOut');
  }
}

// Mock GoogleSignInAccount class
class GoogleSignInAccount {
  final String id = 'mock-google-id';
  final String email = 'mock@example.com';
  final String displayName = 'Mock Google User';

  Future<GoogleSignInAuthentication> get authentication async {
    return GoogleSignInAuthentication();
  }
}

// Mock GoogleSignInAuthentication class
class GoogleSignInAuthentication {
  final String? accessToken = 'mock-access-token';
  final String? idToken = 'mock-id-token';
}

// Mock AuthCredential class
class AuthCredential {
  final String providerId = 'mock-provider';
}

// Mock GoogleAuthProvider class
class GoogleAuthProvider {
  static AuthCredential credential({
    String? idToken,
    String? accessToken,
  }) {
    return AuthCredential();
  }
}

// Mock FirebaseFirestore class
class FirebaseFirestore {
  static final FirebaseFirestore _instance = FirebaseFirestore._();
  static FirebaseFirestore get instance => _instance;

  FirebaseFirestore._();

  CollectionReference collection(String path) {
    return CollectionReference();
  }
}

// Mock CollectionReference class
class CollectionReference {
  DocumentReference doc([String? path]) {
    return DocumentReference();
  }

  Query where(String field, {required String isEqualTo, int? limit}) {
    return Query();
  }

  Query limit(int limit) {
    return Query();
  }

  Future<DocumentReference> add(Map<String, dynamic> data) async {
    print('Mock CollectionReference.add: $data');
    return DocumentReference();
  }

  Query orderBy(String field, {bool descending = false}) {
    print('Mock CollectionReference.orderBy: $field, descending: $descending');
    return Query();
  }

  AggregateQuery count() {
    print('Mock CollectionReference.count');
    return AggregateQuery();
  }
}

// Mock AggregateQuery class
class AggregateQuery {
  Future<AggregateQuerySnapshot> get() async {
    print('Mock AggregateQuery.get');
    return AggregateQuerySnapshot();
  }
}

// Mock AggregateQuerySnapshot class
class AggregateQuerySnapshot {
  final int count = 0;
}

// Mock DocumentReference class
class DocumentReference {
  Future<void> set(Map<String, dynamic> data) async {
    print('Mock DocumentReference.set: $data');
  }

  Future<void> update(Map<String, dynamic> data) async {
    print('Mock DocumentReference.update: $data');
  }

  Future<DocumentSnapshot> get() async {
    return DocumentSnapshot();
  }

  CollectionReference collection(String path) {
    return CollectionReference();
  }
}

// Mock Query class
class Query {
  Future<QuerySnapshot> get() async {
    return QuerySnapshot();
  }

  Query limit(int limit) {
    return this;
  }
}

// Mock QuerySnapshot class
class QuerySnapshot {
  final List<DocumentSnapshot> docs = [];
}

// Mock DocumentSnapshot class
class DocumentSnapshot {
  final String id = 'mock-doc-id';
  final bool exists = false;

  Map<String, dynamic>? data() {
    return {};
  }
}

// Mock Timestamp class
class Timestamp {
  final int seconds;
  final int nanoseconds;

  Timestamp(this.seconds, this.nanoseconds);

  static Timestamp now() {
    final now = DateTime.now();
    return Timestamp(now.millisecondsSinceEpoch ~/ 1000, 0);
  }

  static Timestamp fromDate(DateTime date) {
    return Timestamp(date.millisecondsSinceEpoch ~/ 1000, 0);
  }

  DateTime toDate() {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }
}

// Mock FieldValue class
class FieldValue {
  static FieldValue serverTimestamp() {
    return FieldValue();
  }

  static FieldValue increment(int value) {
    return FieldValue();
  }
}

// Mock FirebaseFunctions class
class FirebaseFunctions {
  static final FirebaseFunctions _instance = FirebaseFunctions._();
  static FirebaseFunctions get instance => _instance;

  FirebaseFunctions._();

  HttpsCallable httpsCallable(String name) {
    return HttpsCallable();
  }
}

// Mock HttpsCallable class
class HttpsCallable {
  Future<HttpsCallableResult> call([dynamic data]) async {
    print('Mock HttpsCallable.call: $data');
    return HttpsCallableResult();
  }
}

// Mock HttpsCallableResult class
class HttpsCallableResult {
  final dynamic data = {};
}
