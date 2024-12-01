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
  bool _isLoading = false;
  String _emailError = '';
  String _passwordError = '';

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    setState(() {
      _emailError = '';
      _passwordError = '';
      _isLoading = true;
    });

    // Validate email format
    if (email.isEmpty ||
        !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$')
            .hasMatch(email)) {
      setState(() {
        _emailError = 'Please enter a valid email address';
        _isLoading = false;
      });
      return;
    }

    // Validate password length
    if (password.isEmpty || password.length < 6) {
      setState(() {
        _passwordError = 'Password must be at least 6 characters long';
        _isLoading = false;
      });
      return;
    }

    try {
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
                          .signOut(); // Sign out if email is not verified
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        print("Login Failed");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Login Failed"),
            content: Text("Invalid email or password. Please try again."),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Login Error: $e");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Login Error"),
          content: Text("An error occurred during login. Please try again."),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 50),
                Icon(
                  Icons.lock,
                  size: 120,
                  color: Colors.teal,
                ),
                SizedBox(height: 20),
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Please login to your account.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 40),
                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.teal),
                    prefixIcon: Icon(Icons.email, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    errorText: _emailError.isEmpty ? null : _emailError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),
                // Password Field
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.teal),
                    prefixIcon: Icon(Icons.lock, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    errorText: _passwordError.isEmpty ? null : _passwordError,
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 30),
                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.teal, // Button color (instead of 'primary')
                    padding:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 100.0),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30.0), // More rounded corners
                    ),
                    elevation: 5, // Subtle shadow
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                SizedBox(height: 20),
                // Sign Up Navigation
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Forgot your password? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to Reset Password Screen
                        Navigator.pushNamed(context, '/reset-password');
                      },
                      child: Text(
                        'Reset here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.teal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
