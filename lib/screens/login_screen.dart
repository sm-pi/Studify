import 'package:flutter/material.dart';
import 'package:studify_app/screens/add_friends_screen.dart'; // Replace 'package_name'
import 'package:studify_app/screens/register_screen.dart'; // Replace 'package_name'
import 'package:studify_app/widgets/custom_button.dart'; // Replace 'package_name'
import 'package:studify_app/widgets/custom_text_field.dart'; // Replace 'package_name'

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 5),
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Forgot password tapped")));
                    },
                    child: const Text("Forgot Password?"),
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: "Login",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFriendsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Login with Gmail tapped")));
                  },
                  icon: const Icon(Icons.mail_outline),
                  label: const Text("Login with Gmail"),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.push(
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
                const SizedBox(height: 30),
                Text(
                  "Please use your university email address for verification.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}