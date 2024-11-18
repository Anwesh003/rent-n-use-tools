import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  bool _isVisible = true; // Flag to control visibility of appBar and bottomBar
  bool _isMenuVisible = false; // Flag to control showing menu options as cards
  bool _isProfileVisible =
      false; // Flag to control visibility of Profile screen
  bool _isSettingsVisible =
      false; // Flag to control visibility of Settings screen

  // List of screens to display
  final List<Widget> _screens = [
    StarScreen(), // Star Screen
    ToolsScreen(), // Tools Screen
    ProfileScreen(), // Profile Screen
  ];

  // Function to handle bottom bar item tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isMenuVisible = false; // Hide menu when other tabs are selected
      _isProfileVisible = false; // Hide profile if another tab is selected
      _isSettingsVisible = false; // Hide settings if another tab is selected
    });
  }

  // Function to show Menu options as cards
  void _showMenu() {
    setState(() {
      _isMenuVisible = true; // Show the menu (cards)
      _selectedIndex =
          2; // Set selected index to "Menu" tab when menu is visible
    });
  }

  // Function to navigate to the selected menu option
  void _onMenuOptionSelected(String option) {
    setState(() {
      _isMenuVisible = false; // Hide menu when an option is selected
    });

    if (option == 'Profile') {
      setState(() {
        _isProfileVisible = true; // Show profile inside the screen
        _isSettingsVisible = false; // Hide settings when profile is visible
      });
    } else if (option == 'Settings') {
      setState(() {
        _isSettingsVisible = true; // Show settings inside the screen
        _isProfileVisible = false; // Hide profile when settings is visible
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isVisible
          ? AppBar(
              title: Text('Welcome to Rent tools'),
              actions: [
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(
                        context, '/login'); // Redirect to Login
                  },
                ),
              ],
            )
          : null,
      body: _isMenuVisible
          ? Menu(
              onMenuOptionSelected:
                  _onMenuOptionSelected) // Use the Menu widget
          : _isProfileVisible
              ? ProfileScreen() // Show ProfileScreen within the body
              : _isSettingsVisible
                  ? SettingsScreen() // Show SettingsScreen within the body
                  : IndexedStack(
                      index:
                          _selectedIndex, // Displays the selected screen based on index
                      children: _screens,
                    ),
      bottomNavigationBar: _isVisible
          ? BottomAppBar(
              child: Container(
                height: 20, // Set the height of the BottomAppBar here
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _onItemTapped(0), // Navigate to StarScreen
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: _selectedIndex == 0
                                ? Colors.blue
                                : Colors.black,
                            size: 20, // Adjust icon size
                          ),
                          Text(
                            'Star',
                            style: TextStyle(
                              color: _selectedIndex == 0
                                  ? Colors.blue
                                  : Colors.black,
                              fontSize: 12, // Reduce text size
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _onItemTapped(1), // Navigate to ToolsScreen
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.home,
                            color: _selectedIndex == 1
                                ? Colors.blue
                                : Colors.black,
                            size: 20, // Adjust icon size
                          ),
                          Text(
                            'Home',
                            style: TextStyle(
                              color: _selectedIndex == 1
                                  ? Colors.blue
                                  : Colors.black,
                              fontSize: 12, // Reduce text size
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Menu button, which replaces Profile
                    GestureDetector(
                      onTap: _showMenu, // Show the menu cards when clicked
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu,
                            color: _selectedIndex == 2
                                ? Colors.blue
                                : Colors.black,
                            size: 20, // Adjust icon size
                          ),
                          Text(
                            'Menu',
                            style: TextStyle(
                              color: _selectedIndex == 2
                                  ? Colors.blue
                                  : Colors.black,
                              fontSize: 12, // Reduce text size
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              color: Colors.white,
              elevation: 10,
            )
          : null,
    );
  }
}
