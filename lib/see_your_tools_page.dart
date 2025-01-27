import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SeeYourToolsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Check if user is logged in
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('See Your Tools')),
        body: Center(
          child: Text(
            'You must be logged in to see your tools.',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.redAccent),
          ),
        ),
      );
    }

    // Fetch user's tools from Firestore
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Tools'),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tools')
            .where('userId',
                isEqualTo: user.uid) // Only fetch tools for the logged-in user
            .snapshots(),
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle errors
          if (snapshot.hasError) {
            return Center(
                child: Text('Something went wrong!',
                    style: TextStyle(fontSize: 18, color: Colors.red)));
          }

          // Handle no tools
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'You have no tools listed.',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.grey[600],
                ),
              ),
            );
          }

          // Fetch the tools
          final tools = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                elevation: 8, // Increased elevation for a stronger shadow
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16), // Softer rounded corners
                ),
                color: isDarkMode
                    ? Colors.grey[850]
                    : Colors.white, // Background color based on theme
                child: InkWell(
                  onTap: () {
                    // You can add onTap action if needed
                  },
                  borderRadius: BorderRadius.circular(16),
                  splashColor:
                      Colors.teal.withOpacity(0.3), // Splash effect on press
                  highlightColor: Colors.teal.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(
                        16.0), // Increased padding for better readability
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool['toolName'],
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.teal,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Quantity: ${tool['quantity']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          'Price: \$${tool['price']} per day',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isDarkMode ? Colors.greenAccent : Colors.green,
                          ),
                        ),
                        Text(
                          'Location: ${tool['location']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          'Contact: ${tool['contact']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.blueAccent : Colors.blue,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Description:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          tool['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
