import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensures that the Flutter engine is initialized
  await Firebase.initializeApp(); // Initialize Firebase

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rent and Use',
      initialRoute: '/',
      routes: {
        '/': (context) => AuthCheck(),
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance
          .authStateChanges(), // FirebaseAuth should be recognized now
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return HomeScreen(); // User is logged in
        } else {
          return LoginScreen(); // User is not logged in
        }
      },
    );
  }
}
