import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/firestore_repository.dart';
import 'main_tab_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthRepository _auth = AuthRepository();
  final FirestoreRepository _firestore = FirestoreRepository();
  StreamSubscription<User?>? _authSub;
  String? _currentUid;
  String? _preparedUid;
  String? _renderedUid;
  bool _isSigningIn = false;
  Object? _initError;

  @override
  void initState() {
    super.initState();
    _authSub = _auth.authStateChanges.listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _onAuthChanged(User? user) {
    if (user == null) {
      debugPrint('[AuthGate] auth state changed: null');
      if (mounted) {
        setState(() {
          _currentUid = null;
          _preparedUid = null;
          _renderedUid = null;
        });
      }
      _ensureSignedIn();
      return;
    }
    debugPrint('[AuthGate] auth state changed: ${user.uid}');
    if (_currentUid == user.uid && _preparedUid == user.uid) {
      return;
    }
    if (mounted) {
      setState(() => _currentUid = user.uid);
    } else {
      _currentUid = user.uid;
    }
    _prepareUser(user.uid);
  }

  Future<void> _ensureSignedIn() async {
    if (_isSigningIn) return;
    _isSigningIn = true;
    try {
      await _auth.signInAnonymouslyIfNeeded();
    } catch (e, stackTrace) {
      debugPrint('[AuthGate] signIn failed: $e\n$stackTrace');
      if (!mounted) return;
      setState(() => _initError = e);
    } finally {
      _isSigningIn = false;
    }
  }

  Future<void> _prepareUser(String uid) async {
    debugPrint('[AuthGate] preparing user: $uid');
    try {
      await _firestore.ensureUserDocument(uid);
      await _firestore.ensureBaseDocuments(uid);
      if (!mounted) return;
      if (_currentUid != uid) return;
      debugPrint('[AuthGate] user ready: $uid');
      setState(() {
        _preparedUid = uid;
      });
    } catch (e, stackTrace) {
      debugPrint('[AuthGate] prepareUser failed: $e\n$stackTrace');
      if (!mounted) return;
      if (_currentUid != uid) return;
      setState(() => _initError = e);
    }
  }

  void _retry() {
    setState(() {
      _initError = null;
      _preparedUid = null;
    });
    _ensureSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return _AuthErrorScreen(error: _initError!, onRetry: _retry);
    }
    final uid = _currentUid;
    if (uid == null || _preparedUid != uid) {
      return const _AuthLoadingScreen();
    }
    if (_renderedUid != uid) {
      debugPrint('[AuthGate] rendering app for: $uid');
      _renderedUid = uid;
    }
    return KeyedSubtree(
      key: ValueKey(uid),
      child: MainTabScreen(currentUid: uid),
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '잠시만 기다려 주세요',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 56,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '로그인에 실패했어요',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
