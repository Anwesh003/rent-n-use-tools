import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Menu extends StatelessWidget {
  final Function(String) onMenuOptionSelected;

  Menu({required this.onMenuOptionSelected});

  @override
  Widget build(BuildContext context) {
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
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () => onMenuOptionSelected('Settings'),
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.business_center,
              title: 'Become Tools Provider',
              onTap: () {
                // Navigate to BecomeToolsProvider screen
                Navigator.pushNamed(context, '/becomeToolsProvider');
              },
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.exit_to_app,
              title: 'Logout',
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10), // Make tap area rounded
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            SizedBox(width: 16),
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
