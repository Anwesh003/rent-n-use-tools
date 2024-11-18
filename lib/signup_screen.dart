import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String errorMessage = "";

  // Sign-up method with email, password, and password confirmation
  Future<void> signUpWithEmailPassword() async {
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      setState(() {
        errorMessage = "Passwords do not match. Please try again.";
      });
      return;
    }

    try {
      // Create user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: password,
      );

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      setState(() {
        errorMessage =
            "A verification email has been sent. Please check your inbox.";
      });

      // Optionally, navigate to home screen after sign-up
      Navigator.pushReplacementNamed(
          context, '/home'); // Navigate to Home Screen
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Password"),
            ),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Confirm Password"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: signUpWithEmailPassword,
              child: Text("Sign Up"),
            ),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
