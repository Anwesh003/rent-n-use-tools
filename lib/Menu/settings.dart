import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
            SizedBox(height: 20),
            Text(
              'About',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Version'),
              subtitle: Text('1.1.3+9'),
            ),
            ListTile(
              leading: Icon(Icons.privacy_tip),
              title: Text('Privacy Policy'),
              onTap: () {
                _showPrivacyPolicyDialog(context);
              },
            ),
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
            '1. **Data Storage**: We use Firebase and Blomp to store data securely.\n\n'
            '2. **Your Data**: While we strive to keep your data safe, please remember that no system is completely immune to risks.\n\n'
            '3. **Responsibility**: By using this app, you acknowledge that we are not responsible for any data loss, misuse, or issues arising from third-party services.\n\n'
            '4. **Your Agreement**: By continuing to use this app, you agree to abide by our data policies.\n\n'
            'We’re committed to making your experience as smooth and secure as possible.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

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
                  GestureDetector(
                    onTap: () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: 'yantraprasamvidha@gmail.com',
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not open email app')),
                        );
                      }
                    },
                    child: Text(
                      'yantraprasamvidha@gmail.com',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.teal,
                        decoration: TextDecoration.underline,
                      ),
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
              Navigator.pop(context);
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
