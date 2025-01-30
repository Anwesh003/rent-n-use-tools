import 'package:flutter/material.dart';

import 'put_it_to_rent_page.dart'; // Import Put It to Rent Page
import 'rented_tools_page.dart'; // Import Rented Tools Page
import 'see_your_tools_page.dart'; // Import See Your Tools Page

class ToolsProviderPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Determine if the theme is light or dark
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become Tools Provider'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.black
              : Colors.white, // Set background color based on theme
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            Text(
              'Welcome to Tools Provider Page',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? Colors.white
                    : Colors.black, // Set text color based on theme
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            // Button to "See Your Tools"
            _buildButton(
              context,
              'See Your Tools',
              Icons.visibility,
              Colors.teal,
              SeeYourToolsPage(),
            ),
            const SizedBox(height: 30),
            // Button to "Put It to Rent"
            _buildButton(
              context,
              'Put It to Rent',
              Icons.add_business,
              Colors.teal,
              PutItToRentPage(),
            ),
            const SizedBox(height: 30),
            // Button to "Who Rented/Booked Your Tools"
            _buildButton(
              context,
              'Who Rented/Booked Your Tools',
              Icons.people,
              Colors.teal,
              RentedToolsPage(
                  userId:
                      'currentUser'), // Replace 'currentUser' with actual user ID
            ),
          ],
        ),
      ),
    );
  }

  // Reusable button builder
  Widget _buildButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    Widget targetPage,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      icon: Icon(icon, color: Colors.white, size: 24),
      label: Text(
        text,
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 40.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
    );
  }
}
