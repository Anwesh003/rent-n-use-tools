import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'FullToolDetails.dart'; // Import the FullToolDetails page

class StarScreen extends StatelessWidget {
  final String userId; // User ID passed to the screen
  StarScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('starred_tools')
            .doc(userId)
            .collection('tools')
            .snapshots(), // Listen to real-time updates
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Error fetching starred tools: ${snapshot.error}');
            return Center(
              child: Text(
                'Something went wrong!',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No starred tools yet!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          // Extract tool IDs from the starred tools collection
          final toolIds = snapshot.data!.docs.map((doc) => doc.id).toList();
          // Fetch tool details using the tool IDs
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tools')
                .where(FieldPath.documentId, whereIn: toolIds)
                .snapshots(), // Listen to real-time updates for tool details
            builder: (context, toolsSnapshot) {
              if (toolsSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (toolsSnapshot.hasError) {
                print('Error fetching tool details: ${toolsSnapshot.error}');
                return Center(
                  child: Text(
                    'Something went wrong!',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                );
              }
              if (!toolsSnapshot.hasData || toolsSnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No starred tools yet!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              final tools = toolsSnapshot.data!.docs;
              return ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: tools.length,
                itemBuilder: (context, index) {
                  final tool = tools[index].data() as Map<String, dynamic>;
                  final toolId = tools[index].id;
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 6,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullToolDetails(
                              toolId: toolId, // Pass the Firestore document ID
                              toolName: tool['toolName'] ?? 'Unknown Tool',
                              totalQuantity: tool['quantity'] ??
                                  0, // Correct parameter name
                              price: tool['price']?.toDouble() ?? 0.0,
                              location: tool['location'] ?? 'N/A',
                              contact: tool['contact'] ?? 'N/A',
                              description: tool['description'] ??
                                  'No description available',
                              imageUrl: tool['imageUrl'] ?? '',
                              isAvailable: tool['isAvailable'] ?? false,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: tool['imageUrl'] != null &&
                                          tool['imageUrl'].isNotEmpty
                                      ? Image.network(
                                          tool['imageUrl'],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            print(
                                                'Image failed to load: ${tool['imageUrl']}');
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(Icons.image,
                                                  size: 40,
                                                  color: Colors.white),
                                            );
                                          },
                                        )
                                      : Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.image,
                                              size: 40, color: Colors.white),
                                        ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tool['toolName'] ?? 'Unknown Tool',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(tool['description'] ??
                                          'No description available'),
                                      SizedBox(height: 4),
                                      Text(
                                          'Quantity: ${tool['quantity'] ?? 'N/A'}'),
                                      SizedBox(height: 4),
                                      Text(
                                          'Price: \$${tool['price'] ?? 'N/A'} per day'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tool['isAvailable'] == true
                                      ? 'Available'
                                      : 'Not Available',
                                  style: TextStyle(
                                    color: tool['isAvailable'] == true
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
