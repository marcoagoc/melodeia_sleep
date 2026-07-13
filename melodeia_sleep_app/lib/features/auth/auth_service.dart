import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth}) {
    _firebaseAuth = firebaseAuth;
  }

  FirebaseAuth? _firebaseAuth;

  FirebaseAuth get _auth => _firebaseAuth ??= FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<User?> ensureAnonymousUser({required bool firebaseReady}) async {
    if (!firebaseReady) return null;
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    final credential = await _auth.signInAnonymously();
    return credential.user;
  }

  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  bool get isSignedIn => currentUser != null && !isAnonymous;

  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  bool get canUpgradeAccount => currentUser?.isAnonymous ?? false;
}
