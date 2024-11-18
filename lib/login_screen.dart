import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter/material.dart';

import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isNotEmpty && password.isNotEmpty) {
      var user = await _authService.login(email, password);

      // Check if the user is logged in successfully
      if (user != null) {
        // Check if the email is verified
        if (user.emailVerified) {
          Navigator.pushReplacementNamed(
              context, '/home'); // Navigate to Home Screen
        } else {
          // Show alert to the user to verify their email
          await user.sendEmailVerification();
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Verify Email"),
                content: Text("Please verify your email before proceeding."),
                actions: <Widget>[
                  TextButton(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                      FirebaseAuth.instance
                          .signOut(); // Sign out the user if email is not verified
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        print("Login Failed");
      }
    } else {
      print("Fields cannot be empty");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text('Login')),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
