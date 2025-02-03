import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RentedToolsPage extends StatelessWidget {
  final String userId; // The ID of the user whose tools are being fetched

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
            print('Error fetching tools: ${snapshot.error}');
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
                'No tools have been rented yet.',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.grey[600],
                ),
              ),
            );
          }

          final tools = snapshot.data!.docs;

          // Filter out tools that have no bookings
          final rentedTools = tools.where((tool) {
            final toolData = tool.data() as Map<String, dynamic>?;
            final bookings =
                List<Map<String, dynamic>>.from(toolData?['bookings'] ?? []);
            return bookings.isNotEmpty;
          }).toList();

          if (rentedTools.isEmpty) {
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

          return ListView.builder(
            itemCount: rentedTools.length,
            itemBuilder: (context, index) {
              final tool = rentedTools[index];
              final toolData = tool.data() as Map<String, dynamic>;
              final toolName = toolData['toolName'] ?? 'Unnamed Tool';
              final bookings =
                  List<Map<String, dynamic>>.from(toolData['bookings'] ?? []);

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
