import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SeeYourToolsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                color: Colors.redAccent),
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
              child: Text('You have no tools listed.',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            );
          }

          // Fetch the tools
          final tools = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    tool['toolName'],
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text('Quantity: ${tool['quantity']}',
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                      Text('Price: \$${tool['price']} per day',
                          style: TextStyle(fontSize: 16, color: Colors.green)),
                      Text('Location: ${tool['location']}',
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                      Text('Contact: ${tool['contact']}',
                          style: TextStyle(fontSize: 16, color: Colors.blue)),
                      SizedBox(height: 10),
                      Text('Description:',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      Text(tool['description'],
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      // Delete the tool when the delete button is pressed
                      await FirebaseFirestore.instance
                          .collection('tools')
                          .doc(tool.id)
                          .delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tool deleted successfully!')),
                      );
                    },
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
