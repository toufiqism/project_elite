import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  bool _loading = false;
  bool get isLoading => _loading;

  String? _error;
  String? get error => _error;

  AuthController() {
    _auth.authStateChanges().listen((_) => notifyListeners());
  }

  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _message(e.code);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _message(e.code);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the picker
        _loading = false;
        notifyListeners();
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _message(e.code);
      return false;
    } catch (_) {
      _error = 'Google sign-in failed. Please try again.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Deletes the Firebase Auth user. Caller is responsible for wiping
  /// Firestore data and local Hive boxes BEFORE invoking this.
  ///
  /// Returns null on success, or an error message. If Firebase rejects with
  /// `requires-recent-login`, the user must sign in again, then retry.
  Future<String?> deleteAccount() async {
    final u = _auth.currentUser;
    if (u == null) return 'Not signed in.';
    try {
      await u.delete();
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'For your security, please sign out and sign back in, '
            'then try deleting again.';
      }
      return _message(e.code);
    } catch (_) {
      return 'Could not delete your account. Please try again.';
    }
  }

  Future<void> signOut() async {
    // Google sign-out is best-effort — it may throw if this session used
    // email/password (no active Google session). Never let it block Firebase.
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _message(String code) => switch (code) {
        'invalid-email' => 'Invalid email address.',
        'user-not-found' => 'No account found for this email.',
        'wrong-password' || 'invalid-credential' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'An account already exists for this email.',
        'weak-password' => 'Password must be at least 6 characters.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        _ => 'Authentication failed. Please try again.',
      };
}
