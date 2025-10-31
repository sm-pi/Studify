import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studify/widgets/custom_button.dart';
import 'package:studify/widgets/custom_text_field.dart';
import 'package:studify/main.dart';

void main() {
  testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(UniversityConnectApp());

    // Verify that the Login screen shows the correct widgets.

    // Checks for the "Login" title
    expect(find.text('Login'), findsOneWidget);

    // Checks for the email field
    expect(find.widgetWithText(CustomTextField, 'University Email'), findsOneWidget);

    // Checks for the password field
    expect(find.widgetWithText(CustomTextField, 'Password'), findsOneWidget);

    // Checks for the "Login" button
    expect(find.widgetWithText(CustomButton, 'Login'), findsOneWidget);
  });
}