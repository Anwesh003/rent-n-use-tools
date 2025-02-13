import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Uri _emailUri =
      Uri(scheme: 'mailto', path: 'yantraprasamvidha@gmail.com');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'About',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const ListTile(
              leading: Icon(Icons.info),
              title: Text('Version'),
              subtitle: Text('1.1.3+11'),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              onTap: () => _showPrivacyPolicyDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.contact_mail),
              title: const Text('Contact Us'),
              onTap: () => _showContactUsDialog(context),
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
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Us'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For any queries or support, please contact us at:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.email, size: 18, color: Colors.teal),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _launchEmail,
                  child: const Text(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail() async {
    if (!await launchUrl(_emailUri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_emailUri');
    }
  }
}
