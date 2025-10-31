import 'package:flutter/material.dart';
import 'package:studify/screens/add_friends_screen.dart';
import 'package:studify/widgets/custom_button.dart';
import 'package:studify/widgets/custom_text_field.dart';

class RegisterScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  RegisterScreen({super.key});

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
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text("Join the community",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                const SizedBox(height: 26),
                CustomTextField(
                    hintText: "Full Name", controller: nameController),
                const SizedBox(height: 16),
                CustomTextField(
                    hintText: "University Email (Gmail)",
                    controller: emailController),
                const SizedBox(height: 16),
                CustomTextField(
                    hintText: "Password",
                    obscureText: true,
                    controller: passwordController),
                const SizedBox(height: 22),
                CustomButton(
                  text: "Register",
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddFriendsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  "By registering, you agree to our Terms of Service and Privacy Policy.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}