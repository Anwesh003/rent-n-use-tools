import 'package:flutter/material.dart';

class StarScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange, // Brown background for Star screen
      child: Center(
        child: Text(
          'Welcome to the Star Screen!',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
