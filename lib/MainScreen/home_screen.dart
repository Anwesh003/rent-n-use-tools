import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Menu/menu.dart'; // Import Menu widget from menu.dart
import '../main.dart';
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

  // List of screens to display based on the selected index
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
      ];
    } else {
      // Handle the case where user is not logged in
      _screens = [
        Center(child: Text('Please log in to access features.')),
        Center(child: Text('Please log in to access features.')),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isMenuVisible = false; // Hide menu when an item is tapped
    });
  }

  void _showMenu() {
    setState(() {
      _selectedIndex = 2; // Set the selected index to "Menu"
      _isMenuVisible = true; // Show menu options
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: _isVisible
          ? AppBar(
              title: Row(
                children: [
                  Image.asset(
                    'assets/yantra.jpg',
                    height: 50,
                    width: 50,
                  ),
                  SizedBox(width: 8),
                  Text('Yantra Prasamvidha'),
                ],
              ),
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
          ? Menu(onMenuOptionSelected: (option) {
              setState(() {
                _isMenuVisible = false; // Hide menu after selection
              });
            })
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
    final isSelected = _selectedIndex == index;
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
