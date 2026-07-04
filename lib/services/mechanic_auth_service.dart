import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mechfixes/data/models/mechanic_record.dart';

/// Result returned after a successful mechanic authentication flow.
class MechanicAuthResult {
  const MechanicAuthResult({
    required this.user,
    required this.profile,
    required this.isNewUser,
  });

  final User user;
  final MechanicRecord profile;
  final bool isNewUser;

  bool get needsOnboarding => profile.shopName.trim().isEmpty;
}

/// Firebase Authentication + Firestore bootstrap for the Mechanic panel.
class MechanicAuthService {
  MechanicAuthService._();

  static final MechanicAuthService instance = MechanicAuthService._();

  static const String mechanicsCollection = 'mechanics';

  static bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<MechanicAuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _ensureFirebaseReady();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Account could not be created.',
        );
      }

      if (fullName.trim().isNotEmpty) {
        await user.updateDisplayName(fullName.trim());
      }

      final profile = await _createMechanicDocument(
        uid: user.uid,
        email: user.email ?? email.trim(),
        fullName: fullName.trim(),
      );

      return MechanicAuthResult(user: user, profile: profile, isNewUser: true);
    } on FirebaseAuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  Future<MechanicAuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureFirebaseReady();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No account found for this email.',
        );
      }

      final profile = await _loadOrCreateMechanicProfile(
        uid: user.uid,
        email: user.email ?? email.trim(),
        fullName: user.displayName ?? '',
      );

      return MechanicAuthResult(user: user, profile: profile, isNewUser: false);
    } on FirebaseAuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _ensureFirebaseReady();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  Future<MechanicRecord?> fetchMechanicProfile(String uid) async {
    if (!isFirebaseReady) return null;

    final doc = await _db.collection(mechanicsCollection).doc(uid).get();
    if (!doc.exists) return null;

    return MechanicRecord.fromFirestore(doc);
  }

  Future<void> signOut() => _auth.signOut();

  // ─── Private helpers ───────────────────────────────────────────────────────

  Future<MechanicRecord> _loadOrCreateMechanicProfile({
    required String uid,
    required String email,
    required String fullName,
  }) async {
    final existing = await fetchMechanicProfile(uid);
    if (existing != null) return existing;

    return _createMechanicDocument(uid: uid, email: email, fullName: fullName);
  }

  Future<MechanicRecord> _createMechanicDocument({
    required String uid,
    required String email,
    required String fullName,
  }) async {
    final profile = MechanicRecord(
      uid: uid,
      email: email,
      fullName: fullName,
      shopName: '',
      phone: '',
      address: '',
      specialties: const [],
      isVerified: false,
      isDemo: false,
    );

    await _db
        .collection(mechanicsCollection)
        .doc(uid)
        .set(profile.toFirestore(includeDefaults: true), SetOptions(merge: true));

    return profile;
  }

  void _ensureFirebaseReady() {
    if (!isFirebaseReady) {
      throw FirebaseAuthException(
        code: 'firebase-not-configured',
        message: 'Firebase is not configured. Run flutterfire configure first.',
      );
    }
  }

  Exception _mapAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return FirebaseAuthException(
          code: error.code,
          message: 'An account already exists with this email.',
        );
      case 'invalid-email':
        return FirebaseAuthException(
          code: error.code,
          message: 'Please enter a valid email address.',
        );
      case 'weak-password':
        return FirebaseAuthException(
          code: error.code,
          message: 'Password is too weak. Use at least 8 characters.',
        );
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return FirebaseAuthException(
          code: error.code,
          message: 'Invalid email or password.',
        );
      case 'user-disabled':
        return FirebaseAuthException(
          code: error.code,
          message: 'This account has been disabled.',
        );
      case 'too-many-requests':
        return FirebaseAuthException(
          code: error.code,
          message: 'Too many attempts. Please try again later.',
        );
      default:
        return FirebaseAuthException(
          code: error.code,
          message: error.message ?? 'Authentication failed. Please try again.',
        );
    }
  }
}
