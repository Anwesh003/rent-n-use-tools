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
            print('Error fetching rentals: ${snapshot.error}');
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
                'No tools available in the database.',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.grey[600],
                ),
              ),
            );
          }

          // Get the current user
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            return Center(
              child: Text(
                'You must be logged in to view your rentals.',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          }

          // Extract rented tools for the current user
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
                  'toolName': toolData['toolName'] ?? 'Unnamed Tool',
                  'price': toolData['price'] ?? 'N/A',
                  'quantityBooked': booking['quantityBooked'] ?? 0,
                  'description': toolData['description'] ?? 'No description',
                  'imageUrl': toolData['imageUrl'] ?? '', // Optional image URL
                  'toolOwnerUserId': toolData['userId'], // Owner's user ID
                  'startDate': booking['startDate'] ?? 'Unknown Start Date',
                  'endDate': booking['endDate'] ?? 'Unknown End Date',
                });
              }
            }
          }

          // If no rentals are found for the user
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

              // Fetch the owner's details from the users collection
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(rental['toolOwnerUserId'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (userSnapshot.hasError || !userSnapshot.hasData) {
                    return ListTile(
                      title: Text('Owner details unavailable'),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  final ownerName = userData?['name'] ?? 'Unknown Owner';
                  final ownerAddress =
                      '${userData?['house'] ?? ''}, ${userData?['area'] ?? ''}, ${userData?['city'] ?? ''}, ${userData?['state'] ?? ''}, ${userData?['pincode'] ?? ''}';

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tool Image (if available)
                          if (rental['imageUrl'].isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                rental['imageUrl'],
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.image_not_supported,
                                      size: 50);
                                },
                              ),
                            ),
                          SizedBox(
                              height: rental['imageUrl'].isNotEmpty ? 12 : 0),

                          // Tool Name
                          Text(
                            rental['toolName'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),

                          // Rental Details
                          Text(
                            'Price: ₹${rental['price']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'Quantity Booked: ${rental['quantityBooked']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'Description: ${rental['description']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),

                          // Rental Dates
                          Text(
                            'Start Date: ${rental['startDate']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'End Date: ${rental['endDate']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),

                          // Tool Owner Details
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.teal),
                              SizedBox(width: 4),
                              Text(
                                'Owner: $ownerName',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: Colors.teal),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Address: $ownerAddress',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
