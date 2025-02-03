import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State variable for theme mode
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header

            // About Section
            Text(
              'About',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Version Info
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Version'),
              subtitle: Text('1.2.2+4'),
            ),

            // Privacy Policy
            ListTile(
              leading: Icon(Icons.privacy_tip),
              title: Text('Privacy Policy'),
              onTap: () {
                _showPrivacyPolicyDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Update the app's theme
  void _updateTheme(bool isDarkMode) {
    // Notify the parent widget or app state to change the theme
    final Brightness brightness =
        isDarkMode ? Brightness.dark : Brightness.light;
    ThemeData newTheme = isDarkMode
        ? ThemeData.dark().copyWith(
            primaryColor: Colors.teal,
            appBarTheme: AppBarTheme(backgroundColor: Colors.teal),
          )
        : ThemeData.light().copyWith(
            primaryColor: Colors.teal,
            appBarTheme: AppBarTheme(backgroundColor: Colors.teal),
          );

    // Use a global state management solution (e.g., Provider, Riverpod) to update the theme.
    // For simplicity, we'll use a callback here.
    _applyTheme(newTheme);
  }

  // Apply the theme globally
  void _applyTheme(ThemeData theme) {
    // If you're using a state management solution like Provider, update the theme there.
    // Otherwise, you can use a simple callback or rebuild the app with the new theme.
    // For now, we'll just print the theme change.
    print('Theme changed to ${theme.brightness}');
  }

  // Show a dialog for privacy policy
  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            'This app collects no personal data. All information is stored securely on your device. '
            'By using this app, you agree to our terms of service.',
            style: TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
