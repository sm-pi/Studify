// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:studify/screens/add_friends_screen.dart';
import 'package:studify/screens/register_screen.dart';
import 'package:studify/widgets/custom_button.dart';
import 'package:studify/widgets/custom_text_field.dart';
import 'package:studify/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// We no longer need role_selection_screen.dart

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showError("Please enter both email and password.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      User? user = await _authService.signInWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddFriendsScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "An unknown error occurred.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      // --- THIS IS THE FIX ---
      // We go back to expecting a simple User? object
      User? user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
        // All users (new or old) go to the same place
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddFriendsScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "An unknown error occurred.");
    } on GoogleSignInException catch (e) {
      _showError(e.description ?? "Google Sign-In failed.");
    } catch (e) {
      _showError("An unknown error occurred.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... your build method is unchanged ...
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 60),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 180,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.school,
                          size: 120,
                          color: Colors.indigo,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text("Login",
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800])),
                    const SizedBox(height: 40),
                    CustomTextField(
                      hintText: "University Email",
                      controller: emailController,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hintText: "Password",
                      obscureText: true,
                      controller: passwordController,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : () {},
                        child: const Text("Forgot Password?"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: "Login",
                      onPressed: _isLoading ? () {} : _handleLogin,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: const Icon(Icons.mail_outline),
                      label: const Text("Login with Gmail"),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: _isLoading ? null : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ),
                          ),
                          child: Text("Sign up",
                              style: TextStyle(color: Colors.indigo[700])),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.white.withOpacity(0.5),
                    child: const CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}