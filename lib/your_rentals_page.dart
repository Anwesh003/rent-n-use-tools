import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class YourRentalsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Rentals'),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tools').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(
              child: Text(
                'Something went wrong!',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No rentals found.',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.grey[600],
                ),
              ),
            );
          }

          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            return Center(
              child: Text(
                'You must be logged in to view your rentals.',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          }

          final tools = snapshot.data!.docs;
          final rentedTools = <Map<String, dynamic>>[];

          for (final toolDoc in tools) {
            final toolData = toolDoc.data() as Map<String, dynamic>?;
            if (toolData == null) continue;

            final bookings =
                List<Map<String, dynamic>>.from(toolData['bookings'] ?? []);
            for (final booking in bookings) {
              if (booking['userId'] == currentUser.uid) {
                rentedTools.add({
                  'toolName': toolData['toolName'],
                  'startDate': booking['startDate'],
                  'endDate': booking['endDate'],
                  'quantityBooked': booking['quantityBooked'],
                });
              }
            }
          }

          if (rentedTools.isEmpty) {
            return Center(
              child: Text(
                'You have not rented any tools yet.',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.grey[600],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: rentedTools.length,
            itemBuilder: (context, index) {
              final rental = rentedTools[index];
              return ListTile(
                leading: Icon(Icons.shopping_cart, color: Colors.teal),
                title: Text(rental['toolName']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Date: ${rental['startDate']}'),
                    Text('End Date: ${rental['endDate']}'),
                    Text('Quantity Booked: ${rental['quantityBooked']}'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
