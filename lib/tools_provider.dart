import 'package:flutter/material.dart';

import 'put_it_to_rent_page.dart'; // Import Put It to Rent Page
import 'see_your_tools_page.dart'; // Import See Your Tools Page

class ToolsProviderPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Become Tools Provider'),
        backgroundColor: Color.fromARGB(255, 135, 211, 255), // AppBar color
        elevation: 0, // Remove the shadow
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 25, 125, 255),
              Color.fromARGB(255, 33, 6, 153)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title with a larger font size
            Text(
              'Welcome to Tools Provider Page',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50),
            // Button to "See Your Tools"
            _buildButton(
              context,
              'See Your Tools',
              Icons.visibility,
              Colors.blue,
              SeeYourToolsPage(),
            ),
            SizedBox(height: 30),
            // Button to "Put It to Rent"
            _buildButton(
              context,
              'Put It to Rent',
              Icons.add_business,
              Colors.green,
              PutItToRentPage(),
            ),
          ],
        ),
      ),
    );
  }

  // A reusable button builder to reduce redundancy
  Widget _buildButton(BuildContext context, String text, IconData icon,
      Color color, Widget targetPage) {
    return ElevatedButton.icon(
      onPressed: () {
        // Navigate to the corresponding page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      icon: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
      label: Text(
        text,
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color, // Use backgroundColor instead of primary
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Rounded corners
        ),
        elevation: 5, // Button shadow for a modern look
      ),
    );
  }
}
