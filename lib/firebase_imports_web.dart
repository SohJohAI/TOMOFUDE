// This file contains mock Firebase implementations for web platforms

// Mock Firebase class
class Firebase {
  static Future<FirebaseApp> initializeApp({FirebaseOptions? options}) async {
    print('Mock Firebase initialization for web');
    return FirebaseApp();
  }
}

// Mock FirebaseApp class
class FirebaseApp {
  final String name = 'mock-app';
  final FirebaseOptions options = FirebaseOptions();
}

// Mock FirebaseOptions class
class FirebaseOptions {
  const FirebaseOptions({
    this.apiKey,
    this.appId,
    this.messagingSenderId,
    this.projectId,
    this.authDomain,
    this.storageBucket,
    this.measurementId,
  });

  final String? apiKey;
  final String? appId;
  final String? messagingSenderId;
  final String? projectId;
  final String? authDomain;
  final String? storageBucket;
  final String? measurementId;
}

// Mock DefaultFirebaseOptions class
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'mock-api-key',
      appId: 'mock-app-id',
      messagingSenderId: 'mock-sender-id',
      projectId: 'mock-project-id',
    );
  }
}
