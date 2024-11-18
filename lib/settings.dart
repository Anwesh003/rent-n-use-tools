import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
            onTap: () {
              // Add functionality for language selection if needed
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            onTap: () {
              // Add functionality for notifications settings if needed
            },
          ),
          ListTile(
            leading: Icon(Icons.security),
            title: Text('Security'),
            onTap: () {
              // Add functionality for security settings if needed
            },
          ),
        ],
      ),
    );
  }
}
