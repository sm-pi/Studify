// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:studify/screens/login_screen.dart'; // Import LoginScreen
import 'package:studify/widgets/custom_button.dart';
import 'package:studify/widgets/custom_text_field.dart';
import 'package:studify/services/auth_service.dart'; // Imports the service
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // This is the single, correct function
  void _handleRegister() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showMessage("Please enter email and password.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = await _authService.registerWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null && mounted) {
        _showMessage("Registration successful! Please check your email to verify.", isError: false);

        // This correctly sends the user back to the Login page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false, // Clear all routes
        );
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "An unknown error occurred.", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // The duplicated code that was here is now removed.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: SingleChildScrollView(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 8),
                    Text("Join the community",
                        style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                    const SizedBox(height: 26),
                    CustomTextField(
                        hintText: "Full Name", controller: nameController),
                    const SizedBox(height: 16),
                    CustomTextField(
                        hintText: "University Email (e.g., name@bubt.edu.bd)",
                        controller: emailController),
                    const SizedBox(height: 16),
                    CustomTextField(
                        hintText: "Password (min. 6 characters)",
                        obscureText: true,
                        controller: passwordController),
                    const SizedBox(height: 22),
                    CustomButton(
                      text: "Register",
                      onPressed: _isLoading ? () {} : _handleRegister,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "By registering, you agree to our Terms of Service and Privacy Policy.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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