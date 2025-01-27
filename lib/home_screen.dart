import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'main.dart';
import 'menu.dart'; // Import Menu widget from menu.dart
import 'profile.dart'; // Import ProfileScreen from profile.dart
import 'settings.dart'; // Import SettingsScreen from settings.dart
import 'star.dart'; // Import StarScreen from star.dart
import 'tools.dart'; // Import ToolsScreen from tools.dart

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // Default to Tools screen
  bool _isVisible = true; // Show appBar and bottomBar by default
  bool _isMenuVisible = false; // Show menu options when true
  bool _isProfileVisible = false; // Show Profile screen when true
  bool _isSettingsVisible = false; // Show Settings screen when true

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    // Ensure the user is logged in and initialize screens
    if (user != null) {
      _screens = [
        StarScreen(userId: user.uid), // Star Screen
        ToolsScreen(userId: user.uid), // Tools Screen with userId
        ProfileScreen(), // Placeholder for Profile tab (not used)
      ];
    } else {
      // Handle the case where user is not logged in
      _screens = [
        Center(child: Text('Please log in to access features.')),
        Center(child: Text('Please log in to access features.')),
        Center(child: Text('Please log in to access features.')),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isMenuVisible = false;
      _isProfileVisible = false;
      _isSettingsVisible = false;
    });
  }

  void _showMenu() {
    setState(() {
      _isMenuVisible = true;
      _isProfileVisible = false;
      _isSettingsVisible = false;
    });
  }

  void _onMenuOptionSelected(String option) {
    setState(() {
      _isMenuVisible = false;
    });

    if (option == 'Profile') {
      setState(() {
        _isProfileVisible = true;
        _isSettingsVisible = false;
      });
    } else if (option == 'Settings') {
      setState(() {
        _isSettingsVisible = true;
        _isProfileVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: _isVisible
          ? AppBar(
              title: Text('Rent and use'),
              actions: [
                IconButton(
                  icon: Icon(
                    isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  ),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                ),
              ],
            )
          : null,
      body: _isMenuVisible
          ? Menu(onMenuOptionSelected: _onMenuOptionSelected)
          : _isProfileVisible
              ? ProfileScreen()
              : _isSettingsVisible
                  ? SettingsScreen()
                  : IndexedStack(
                      index: _selectedIndex,
                      children: _screens,
                    ),
      bottomNavigationBar: _isVisible
          ? BottomAppBar(
              child: Container(
                height: 60,
                color: isDarkMode ? Colors.black : Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomNavigationBarItem(
                      icon: Icons.star,
                      label: 'Star',
                      index: 0,
                      isDarkMode: isDarkMode,
                    ),
                    _buildBottomNavigationBarItem(
                      icon: Icons.home,
                      label: 'Home',
                      index: 1,
                      isDarkMode: isDarkMode,
                    ),
                    _buildBottomNavigationBarItem(
                      icon: Icons.menu,
                      label: 'Menu',
                      index: 2,
                      isDarkMode: isDarkMode,
                      onTap: _showMenu,
                    ),
                  ],
                ),
              ),
              elevation: 8,
            )
          : null,
    );
  }

  Widget _buildBottomNavigationBarItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDarkMode,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedIndex == index && !_isMenuVisible;
    return GestureDetector(
      onTap: onTap ?? () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? (isDarkMode ? Colors.tealAccent : Colors.blue)
                : (isDarkMode ? Colors.white54 : Colors.black),
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? (isDarkMode ? Colors.tealAccent : Colors.blue)
                  : (isDarkMode ? Colors.white54 : Colors.black),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
