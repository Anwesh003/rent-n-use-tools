import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RentedToolsPage extends StatelessWidget {
  final String userId;

  RentedToolsPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Who Rented Your Tools'),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tools')
            .where('userId', isEqualTo: userId) // Fetch tools owned by the user
            .snapshots(),
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
            print('No tools found for user ID: $userId');
            return Center(
              child: Text(
                'No tools have been rented yet.',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.grey[600],
                ),
              ),
            );
          }

          final tools = snapshot.data!.docs;
          print('Fetched Tools: ${tools.map((doc) => doc.data())}');

          return ListView.builder(
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              final toolData = tool.data() as Map<String, dynamic>?;
              if (toolData == null) {
                return ListTile(
                  title: Text('Invalid Tool Data'),
                  subtitle: Text('This tool has no valid information.'),
                );
              }

              final toolName = toolData['toolName'] ?? 'Unnamed Tool';
              final bookings =
                  List<Map<String, dynamic>>.from(toolData['bookings'] ?? []);
              print('Tool Name: $toolName, Bookings: $bookings');

              if (bookings.isEmpty) {
                return ListTile(
                  title: Text(toolName),
                  subtitle: Text('No bookings yet'),
                );
              }

              return ExpansionTile(
                title: Text(toolName),
                children: bookings.map((booking) {
                  final renterUserId = booking['userId'] ?? 'Unknown User';
                  final startDate =
                      booking['startDate'] ?? 'Unknown Start Date';
                  final endDate = booking['endDate'] ?? 'Unknown End Date';
                  final quantityBooked = booking['quantityBooked'] ?? 0;

                  return ListTile(
                    leading: Icon(Icons.person, color: Colors.teal),
                    title: Text('Renter ID: $renterUserId'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Date: $startDate'),
                        Text('End Date: $endDate'),
                        Text('Quantity Booked: $quantityBooked'),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
