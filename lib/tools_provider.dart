import 'package:flutter/material.dart';

class ToolsProvider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Become Tools Provider'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to the Tools Provider Page!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Here you can register to become a tools provider.',
              style: TextStyle(fontSize: 18),
            ),
            // Add more content or form fields here as needed.
          ],
        ),
      ),
    );
  }
}
