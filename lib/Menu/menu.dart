import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../toolsprovider/tools_provider.dart';
import 'profile.dart';
import 'settings.dart';
import 'your_rentals_page.dart';

Future<void> _launchGoogleLens(BuildContext context) async {
  const googleLensUrl =
      'intent://lens/#Intent;scheme=google;package=com.google.ar.lens;end';
  const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.google.ar.lens';

  try {
    // Check if Google Lens can be launched
    bool canLaunchLens = await canLaunchUrl(Uri.parse(googleLensUrl));
    print('Can launch Google Lens: $canLaunchLens');
    if (canLaunchLens) {
      // Open Google Lens
      await launchUrl(Uri.parse(googleLensUrl));
    } else {
      // Redirect to Play Store
      await launchUrl(Uri.parse(playStoreUrl));
    }
  } catch (e) {
    // Show an error message if something goes wrong
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to open Google Lens: $e')),
    );
  }
}

class Menu extends StatelessWidget {
  final Function(String) onMenuOptionSelected;

  Menu({required this.onMenuOptionSelected});

  @override
  Widget build(BuildContext context) {
    // Determine theme colors dynamically for consistency
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final shadowColor = theme.shadowColor;
    final isDarkMode = theme.brightness == Brightness.dark;
    final iconColor = isDarkMode ? Colors.white : theme.primaryColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/vcetlogo.png',
              height: 125,
            ),
            const SizedBox(height: 24),
            _buildMenuItem(
              icon: Icons.account_circle,
              title: 'Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              cardColor: cardColor,
              shadowColor: shadowColor,
              iconColor: iconColor,
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
              cardColor: cardColor,
              shadowColor: shadowColor,
              iconColor: iconColor,
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.business_center,
              title: 'Become Tools Provider',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ToolsProviderPage()),
                );
              },
              cardColor: cardColor,
              shadowColor: shadowColor,
              iconColor: iconColor,
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.shopping_cart,
              title: 'Your Rentals',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => YourRentalsPage()),
                );
              },
              cardColor: cardColor,
              shadowColor: shadowColor,
              iconColor: iconColor,
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.camera_alt, // Use a camera icon for Google Lens
              title: 'Google Lens',
              onTap: () {
                _launchGoogleLens(context); // Launch Google Lens
              },
              cardColor: cardColor,
              shadowColor: shadowColor,
              iconColor: iconColor,
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.exit_to_app,
              title: 'Logout',
              onTap: () {
                _showLogoutConfirmationDialog(context);
              },
              cardColor: cardColor,
              shadowColor: shadowColor,
              iconColor: iconColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color cardColor,
    required Color shadowColor,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

void _showLogoutConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Logout'),
      content: Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('No'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop(); // Close the dialog
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: Text('Yes'),
        ),
      ],
    ),
  );
}
