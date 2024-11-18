import 'package:flutter/material.dart';

class ToolsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightBlue, // Light blue background
      child: Center(
        child: Text(
          'Tools are displayed here!',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
