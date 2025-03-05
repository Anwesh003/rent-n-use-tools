import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'aboutus.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Uri _emailUri =
      Uri(scheme: 'mailto', path: 'yantraprasamvidha@gmail.com');

  // Variables to store fetched links
  String? _userManualLink;
  String? _privacyPolicyLink;

  // Reference to Firestore collection and document
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'externallinks';
  final String _documentName = 'appLinks';

  // Fetch links from Firestore when the widget initializes
  @override
  void initState() {
    super.initState();
    _fetchLinksFromFirestore();
  }

  // Method to fetch links from Firestore
  Future<void> _fetchLinksFromFirestore() async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(_collectionName).doc(_documentName).get();

      if (documentSnapshot.exists) {
        setState(() {
          _userManualLink = documentSnapshot.get('userManual');
          _privacyPolicyLink = documentSnapshot.get('privacyPolicy');
        });
      } else {
        print('Document does not exist in Firestore');
      }
    } catch (e) {
      print('Error fetching links from Firestore: $e');
    }
  }

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
              subtitle: Text('1.1.3+15'),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('User Manual'),
              onTap: _launchUserManual,
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              onTap: _launchPrivacyPolicy,
            ),
            ListTile(
              leading: const Icon(Icons.contact_mail),
              title: const Text('Contact Us'),
              onTap: _showContactUsDialog,
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('About Us'),
              onTap: () => _showAboutUsDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUserManual() async {
    if (_userManualLink == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User Manual link not available')),
      );
      return;
    }

    final Uri userManualUri = Uri.parse(_userManualLink!);
    if (!await launchUrl(userManualUri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $userManualUri');
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    if (_privacyPolicyLink == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy Policy link not available')),
      );
      return;
    }

    final Uri privacyPolicyUri = Uri.parse(_privacyPolicyLink!);
    if (!await launchUrl(privacyPolicyUri,
        mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $privacyPolicyUri');
    }
  }

  void _showContactUsDialog() {
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

void _showAboutUsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AboutUsPage(), // Imported AboutUsPage
  );
}
