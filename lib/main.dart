import 'package:flutter/material.dart';
import 'package:studify/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:studify/firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart'; // <-- 1. IMPORT GOOGLE SIGN-IN

Future<void> main() async {
  // 2. Ensure all native code is ready
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GoogleSignIn.instance.initialize(
    serverClientId: "914674489473-aaqrjp0shq1krljvqmhrk52hm223s957.apps.googleusercontent.com",
  );
  // ---------------------------------

  runApp(UniversityConnectApp());
}

class UniversityConnectApp extends StatelessWidget {
  const UniversityConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Studify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: LoginScreen(),
    );
  }
}