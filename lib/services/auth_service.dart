// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Make sure this import is here

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Uses the correct .instance singleton
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final String _requiredDomain = "bubt.edu.bd";

  void _handleAuthException(FirebaseAuthException e) {
    print("Error: ${e.message} (Code: ${e.code})");
  }

  /// --- 1. Sign in with Google ---
  Future<User?> signInWithGoogle() async {
    try {
      // Uses the correct .authenticate() method
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // No null check needed, as .authenticate() throws on cancel

      // --- YOUR BUBT DOMAIN CHECK ---
      if (!googleUser.email.endsWith(_requiredDomain)) {
        await _googleSignIn.signOut();
        throw FirebaseAuthException(
          code: 'invalid-email-domain',
          message: 'Only emails from the $_requiredDomain domain are allowed.',
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;

    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        print('Google Sign-In was canceled by the user.');
        return null;
      }
      // Uses the correct e.description property
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
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      if (!email.endsWith(_requiredDomain)) {
        throw FirebaseAuthException(
          code: 'invalid-email-domain',
          message: 'Please use a valid $_requiredDomain email to register.',
        );
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.sendEmailVerification();

      return userCredential.user;

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
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

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