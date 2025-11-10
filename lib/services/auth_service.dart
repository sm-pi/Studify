// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:studify/services/database_services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final String _requiredDomain = "bubt.edu.bd";

  bool _isBubtEmail(String email) {
    if (!email.contains('@')) return false;
    String domain = email.split('@').last.toLowerCase();
    if (domain == _requiredDomain) return true;
    if (domain.endsWith("." + _requiredDomain)) return true;
    return false;
  }

  void _handleAuthException(FirebaseAuthException e) {
    print("Error: ${e.message} (Code: ${e.code})");
  }

  /// --- 1. Sign in with Google ---
  /// Returns a User? just like the other methods
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      if (!_isBubtEmail(googleUser.email)) {
        await _googleSignIn.signOut();
        throw FirebaseAuthException(code: 'invalid-email-domain', message: 'Only emails from the $_requiredDomain domain are allowed.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (user != null && isNewUser) {
        await DatabaseService(uid: user.uid).createUserProfile(
          name: user.displayName ?? 'New User',
          email: user.email!,
        );
      }

      return user; // <-- REVERTED TO THIS

    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      print("GoogleSignInException: ${e.description} (Code: ${e.code})");
      rethrow;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      rethrow;
    } catch (e) {
      print("An unknown error occurred: $e");
      return null;
    }
  }

  /// --- 2. Register (Sign Up) with Email & Password ---
  Future<User?> registerWithEmail(String email, String password, String name) async {
    try {
      if (!_isBubtEmail(email)) {
        throw FirebaseAuthException(code: 'invalid-email-domain', message: 'Please use a valid $_requiredDomain email to register.');
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;

      if (user != null) {
        await DatabaseService(uid: user.uid).createUserProfile(
          name: name,
          email: email,
        );
      }

      await user?.sendEmailVerification();
      return user;

    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      rethrow;
    } catch (e) {
      print("An unknown error occurred: $e");
      return null;
    }
  }

  /// --- 3. Sign In (Login) with Email & Password ---
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      if (!_isBubtEmail(email)) {
        throw FirebaseAuthException(code: 'invalid-email-domain', message: 'Only emails from the $_requiredDomain domain are allowed.');
      }
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      rethrow;
    } catch (e) {
      print("An unknown error occurred: $e");
      return null;
    }
  }

  /// --- 4. Sign Out ---
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}