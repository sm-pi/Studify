import 'package:flutter/material.dart';
import 'package:studify_app/screens/login_screen.dart';

void main() {
  runApp(UniversityConnectApp());
}
//Main File
class UniversityConnectApp extends StatelessWidget {
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