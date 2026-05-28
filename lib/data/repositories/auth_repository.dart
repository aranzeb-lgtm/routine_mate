import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User> signInAnonymouslyIfNeeded() async {
    final existing = _auth.currentUser;
    if (existing != null) {
      debugPrint('Signed in as: ${existing.uid}');
      return existing;
    }
    final credential = await _auth.signInAnonymously();
    final user = credential.user!;
    debugPrint('Signed in as: ${user.uid}');
    return user;
  }

  Future<String> requireUserId() async {
    final user = await signInAnonymouslyIfNeeded();
    return user.uid;
  }

  Future<void> signOut() async {
    debugPrint('[Auth] signOut start');
    await _auth.signOut();
    debugPrint('[Auth] signOut success');
  }
}
