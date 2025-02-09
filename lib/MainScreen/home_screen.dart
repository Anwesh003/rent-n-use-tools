import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Menu/menu.dart'; // Import Menu widget from menu.dart
import '../Menu/profile.dart'; // Import ProfileScreen
import '../main.dart';
import 'boyerssearch.dart';
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
  bool isLoading = true; // Loading state
  bool isProfileComplete = false; // Track profile completion status

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _screens = [
        StarScreen(userId: user.uid), // Star Screen
        ToolsScreen(userId: user.uid), // Tools Screen with userId
      ];
    } else {
      _screens = [
        Center(child: Text('Please log in to access features.')),
        Center(child: Text('Please log in to access features.')),
      ];
    }
  }

  // Check if the user's profile is complete
  Future<void> _checkProfileCompletion() async {
    setState(() {
      isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            isProfileComplete = data['name']?.isNotEmpty == true &&
                data['phone']?.isNotEmpty == true &&
                data['house']?.isNotEmpty == true &&
                data['area']?.isNotEmpty == true &&
                data['landmark']?.isNotEmpty == true &&
                data['pincode']?.isNotEmpty == true &&
                data['city']?.isNotEmpty == true &&
                data['state']?.isNotEmpty == true;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() {
      isLoading = false;
    });

    // If profile is incomplete, show the prompt
    if (!isProfileComplete && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showProfilePrompt();
      });
    }
  }

  // Show a prompt to complete the profile
  void _showProfilePrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Incomplete Profile'),
          content: Text(
              'Your profile is incomplete. Please fill out your details to continue.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              child: Text('Fill Profile'),
            ),
          ],
        );
      },
    );
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

    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _isVisible
          ? AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/yantraprasamvidha.png',
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image_not_supported,
                            size: 40, color: Colors.white);
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Yantra Prasamvidha',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              backgroundColor: Colors.teal,
              elevation: 4,
              actions: [
                IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    _showSearchDialog(context); // Show search dialog
                  },
                ),
              ],
            )
          : null, // Hide the AppBar if _isVisible is false
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

void _showSearchDialog(BuildContext context) {
  final TextEditingController _searchController = TextEditingController();
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Search Tools'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter tool name or description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final query = _searchController.text.trim();
                if (query.isNotEmpty) {
                  Navigator.pop(context); // Close the dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BoyerSearchScreen(
                        userId: FirebaseAuth.instance.currentUser!.uid,
                        searchQuery: query, // Pass the search query
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a search query.')),
                  );
                }
              },
              child: Text('Search'),
            ),
          ],
        ),
      );
    },
  );
}
