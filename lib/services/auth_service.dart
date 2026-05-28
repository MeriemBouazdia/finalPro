// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import '../core/errors/app_exception.dart';

/// Wraps [FirebaseAuth] operations and translates errors into [AppException].
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Creates a new Firebase Auth user and returns the created [User].
  /// Throws [AppException] on any auth failure.
  Future<User> createUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e));
    }
  }

  /// Returns a fresh ID token for [user].
  Future<String> getIdToken(User user) async {
    try {
      final token = await user.getIdToken();
      return token!;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e));
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }
}
