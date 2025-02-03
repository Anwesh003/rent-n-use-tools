import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../toolsprovider/tools_provider.dart';
import 'your_rentals_page.dart';

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
            _buildMenuItem(
              icon: Icons.account_circle,
              title: 'Profile',
              onTap: () => onMenuOptionSelected('Profile'),
              cardColor: cardColor,
              shadowColor: shadowColor,
              iconColor: iconColor,
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () => onMenuOptionSelected('Settings'),
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
              icon: Icons.exit_to_app,
              title: 'Logout',
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
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
