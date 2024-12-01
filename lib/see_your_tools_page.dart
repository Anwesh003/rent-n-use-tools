import 'package:flutter/material.dart';

class SeeYourToolsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('See Your Tools')),
      body: Center(
        child: Text(
          'Here are your tools!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
