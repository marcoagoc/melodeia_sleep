import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth}) {
    _firebaseAuth = firebaseAuth;
  }

  FirebaseAuth? _firebaseAuth;

  FirebaseAuth get _auth => _firebaseAuth ??= FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth?.currentUser;

  Future<User?> ensureAnonymousUser({required bool firebaseReady}) async {
    if (!firebaseReady) return null;
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    final credential = await _auth.signInAnonymously();
    return credential.user;
  }

  bool get canUpgradeAccount => currentUser?.isAnonymous ?? false;
}
