import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService();
  static final AuthService instance = AuthService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Mechanic sign-up (saves to 'mechanics' collection) ──────────────────

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('Sign-up failed. Please try again.');

      await _db.collection('mechanics').doc(user.uid).set({
        'email': email.trim(),
        'isVerified': false,
        'isDemo': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return credential;
    } on FirebaseAuthException catch (e) {
      // translate + rethrow — MUST reach the UI catch block
      throw Exception(_translate(e.code));
    } catch (e) {
      rethrow; // already an Exception; don't double-wrap
    }
  }

  // ─── Mechanic sign-in ─────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Explicit null-guard: if Firebase returns without a user, treat as failure
      if (credential.user == null) {
        throw Exception('Sign-in failed. No user returned by Firebase.');
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_translate(e.code));
    } catch (e) {
      rethrow;
    }
  }

  // ─── User sign-in ─────────────────────────────────────────────────────────

  Future<void> signInUser(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_translate(e.code));
    }
  }

  // ─── User sign-up (saves to 'users' collection) ───────────────────────────

  Future<void> signUpUser(String email, String password, String fullName) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'email': email,
        'fullName': fullName,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseAuthException catch (e) {
      throw Exception(_translate(e.code));
    }
  }

  // ─── Mechanic sign-in (via AuthService) ──────────────────────────────────

  Future<void> signInMechanic(String email, String password) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user == null) {
        throw Exception('Sign-in failed. No user returned by Firebase.');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_translate(e.code));
    }
  }

  // ─── Mechanic sign-up (saves to 'mechanics' collection) ──────────────────

  Future<void> signUpMechanic(String email, String password, String fullName) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) throw Exception('Sign-up failed. Please try again.');

      if (fullName.trim().isNotEmpty) {
        await user.updateDisplayName(fullName.trim());
      }

      await FirebaseFirestore.instance
          .collection('mechanics')
          .doc(user.uid)
          .set({
        'email': email,
        'fullName': fullName.trim(),
        'shopName': '',
        'phone': '',
        'address': '',
        'specialties': [],
        'selectedSkills': [],
        'isVerified': false,
        'isDemo': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseAuthException catch (e) {
      throw Exception(_translate(e.code));
    }
  }

  // ─── Sign-out ─────────────────────────────────────────────────────────────

  Future<void> signOut() => _auth.signOut();

  // ─── Error code → user-friendly string ───────────────────────────────────
  //
  // Covers both legacy codes (Firebase SDK <5) and modern codes (SDK 5+/web).

  static String _translate(String code) {
    // Normalise: some web SDK versions return uppercase or mixed codes
    final c = code.toLowerCase().trim();

    switch (c) {
      // ── Credential errors ──
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
      case 'invalid_login_credentials':       // Firebase SDK 5+ web alias
      case 'invalid-login-credentials':
        return 'Incorrect email or password. Please try again.';

      // ── Email errors ──
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';

      // ── Account state ──
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';

      // ── Password ──
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';

      // ── Rate limiting ──
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again later.';

      // ── Network / channel (web SDK) ──
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'channel-error':                   // Flutter web JS bridge failure
        return 'Connection error. Please refresh and try again.';

      // ── Configuration ──
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Contact support.';
      case 'app-not-authorized':
        return 'App not authorized to use Firebase Authentication.';

      default:
        return 'Authentication failed. Please try again. (code: $code)';
    }
  }
}
