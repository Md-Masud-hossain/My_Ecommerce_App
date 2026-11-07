import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost/ecommerce_api';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // While an email sign-up is in progress, Firebase signs the new user in
  // automatically. We hide that from AuthGate so the app does not jump to the
  // home page; the user must login after signing up.
  static bool _registering = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authChanges =>
      _auth.authStateChanges().where((_) => !_registering);

  // ---------- Sign up (email + password) ----------
  Future<void> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    _registering = true;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(name.trim());

      try {
        await _syncUser(name: name.trim(), phone: phone.trim());
      } catch (e) {
        // Could not save to MySQL: remove the new account so the user
        // can simply try signing up again.
        await cred.user?.delete();
        rethrow;
      }

      // Sign out so the user has to login after creating the account.
      await _auth.signOut();
    } finally {
      _registering = false;
    }
  }

  // ---------- Login (email + password) ----------
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _syncUser();
  }

  // ---------- Google ----------
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
    } else {
      await _auth.signInWithProvider(provider);
    }
    await _syncUser();
  }

  // ---------- Password reset ----------
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

  // ---------- Save the user in the backend (MySQL) ----------
  // If this fails, it is retried on the next login, so no data is lost.
  Future<void> _syncUser({String? name, String? phone}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await user.getIdToken(true);

    final res = await http.post(
      Uri.parse('$baseUrl/sync_user.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': token,
        'name': name ?? '',
        'phone': phone ?? '',
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['message'] ?? 'Could not save user data');
    }
  }

  // ---------- Friendly error messages ----------
  static String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return 'Google sign-in was cancelled.';
        case 'network-request-failed':
          return 'Please check your internet connection.';
        default:
          return e.message ?? 'Something went wrong.';
      }
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}
