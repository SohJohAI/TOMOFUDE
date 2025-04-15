// This file provides Dart-side fixes for Firebase web package compatibility issues

import 'package:js/js.dart';
import 'package:firebase_core_web/firebase_core_web_interop.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Export Timestamp class from cloud_firestore
export 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// Define PromiseJsImpl type for Firebase web packages
@JS('PromiseJsImpl')
class PromiseJsImpl<T> {
  external PromiseJsImpl(Function executor);
  external PromiseJsImpl then(Function onFulfilled, [Function onRejected]);
  external PromiseJsImpl catchError(Function onRejected);
}

/// Define dartify function for Firebase web packages
@JS('dartify')
external dynamic dartify(dynamic jsObject);

/// Define jsify function for Firebase web packages
@JS('jsify')
external dynamic jsify(dynamic dartObject, [dynamic customJsify]);

/// Define handleThenable function for Firebase web packages
@JS('handleThenable')
external dynamic handleThenable(dynamic promise);

/// Define ActionCodeInfo for Firebase Auth Web
@JS()
class ActionCodeInfo {
  external dynamic get data;
}

/// Define ConfirmationResultJsImpl for Firebase Auth Web
@JS()
class ConfirmationResultJsImpl {
  external PromiseJsImpl<dynamic> confirm(String verificationCode);
}

/// Define IdTokenResultImpl for Firebase Auth Web
@JS()
class IdTokenResultImpl {
  external String get token;
  external dynamic get claims;
  external dynamic get expirationTime;
  external dynamic get authTime;
  external dynamic get issuedAtTime;
  external String get signInProvider;
}

/// Define MultiFactorSessionJsImpl for Firebase Auth Web
@JS()
class MultiFactorSessionJsImpl {}

/// Define TotpSecretJsImpl for Firebase Auth Web
@JS()
class TotpSecretJsImpl {}

/// Define UserJsImpl for Firebase Auth Web
@JS()
class UserJsImpl {
  external PromiseJsImpl<void> delete();
  external PromiseJsImpl<String> getIdToken(bool? forceRefresh);
  external PromiseJsImpl<IdTokenResultImpl> getIdTokenResult(
      bool? forceRefresh);
  external PromiseJsImpl<void> reload();
}

/// Define AuthJsImpl for Firebase Auth Web
@JS()
class AuthJsImpl {
  external PromiseJsImpl<void> signOut();
}
