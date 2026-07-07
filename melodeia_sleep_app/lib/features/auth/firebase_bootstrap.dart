import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrapStatus {
  const FirebaseBootstrapStatus({required this.isReady, this.message});

  final bool isReady;
  final String? message;
}

class FirebaseBootstrap {
  static Future<FirebaseBootstrapStatus> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      return const FirebaseBootstrapStatus(isReady: true);
    } on Object {
      return FirebaseBootstrapStatus(
        isReady: false,
        message:
            'Firebase is not configured yet. Run flutterfire configure before cloud sync.',
      );
    }
  }
}
