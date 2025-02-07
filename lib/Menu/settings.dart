import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State variable for theme mode
  // bool _isDarkMode = false;

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
            // About Section
            SizedBox(height: 20),
            Text(
              'About',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Version Info
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Version'),
              subtitle: Text('1.1.3+6'),
            ),
            // Privacy Policy
            ListTile(
              leading: Icon(Icons.privacy_tip),
              title: Text('Privacy Policy'),
              onTap: () {
                _showPrivacyPolicyDialog(context);
              },
            ),
            // Contact Us
            ListTile(
              leading: Icon(Icons.contact_mail),
              title: Text('Contact Us'),
              onTap: () {
                _showContactUsDetails(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            'Welcome to our app! We’re glad you’re here. Here’s a quick overview of how we handle your data:\n\n'
            '1. **Data Storage**: We use Firebase and Blomp to store data securely. These platforms are trusted and widely used for managing user information.\n\n'
            '2. **Your Data**: While we strive to keep your data safe, please remember that no system is completely immune to risks. We recommend being cautious about the information you share.\n\n'
            '3. **Responsibility**: By using this app, you acknowledge that we are not responsible for any data loss, misuse, or issues arising from third-party services like Firebase or Blomp.\n\n'
            '4. **Your Agreement**: By continuing to use this app, you agree to abide by our data policies. This means you understand how your data is handled and accept the associated risks.\n\n'
            'We’re committed to making your experience as smooth and secure as possible. If you have any questions or concerns, feel free to reach out to us through the "Contact Us" section in the settings.\n\n'
            'Thank you for using our app!',
            style: TextStyle(
                fontSize: 16, height: 1.5), // Add line height for readability
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

  // Show a dialog for Contact Us details
  void _showContactUsDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Us'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For any queries or support, please contact us at:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.email, size: 18, color: Colors.teal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Email: yantraprasamvidha@gmail.com',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
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
