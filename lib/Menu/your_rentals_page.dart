import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ImageCacheManager {
  final Map<String, Uint8List> _cache = {};
  Future<Uint8List?> getImage(String fileName) async {
    if (_cache.containsKey(fileName)) {
      return _cache[fileName];
    }
    final imageBytes = await _fetchPrivateImage(fileName);
    if (imageBytes != null) {
      _cache[fileName] = imageBytes;
    }
    return imageBytes;
  }

  Future<Uint8List?> _fetchPrivateImage(String? fileName) async {
    if (fileName == null || fileName.isEmpty) {
      print("Error: File name is null or empty.");
      return null;
    }
    try {
      // Step 1: Authenticate with Blomp (OpenStack API)
      final String authUrl = 'https://authenticate.blomp.com/v3/auth/tokens';
      final String username =
          'anweshkrishnab6324@gmail.com'; // Replace with secure credentials
      final String password =
          '5cmYC5!QzP!NsKG'; // Replace with secure credentials
      final String bucketName =
          'anweshkrishnab6324@gmail.com'; // Replace with your bucket name

      final Map authPayload = {
        "auth": {
          "identity": {
            "methods": ["password"],
            "password": {
              "user": {
                "name": username,
                "domain": {"id": "default"},
                "password": password,
              },
            },
          },
        },
      };

      final http.Response authResponse = await http.post(
        Uri.parse(authUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(authPayload),
      );

      if (authResponse.statusCode != 201) {
        print("Authentication failed: ${authResponse.body}");
        return null;
      }

      // Extract the token from the response headers
      final String? authToken = authResponse.headers['x-subject-token'];
      if (authToken == null) {
        print(
            "Error: X-Subject-Token header not found in authentication response.");
        return null;
      }

      // Step 2: Fetch the storage URL from the catalog
      final Map authData = jsonDecode(authResponse.body);
      final List? catalog = authData['token']?['catalog'];
      if (catalog == null || catalog.isEmpty) {
        print("Error: No catalog found in authentication response.");
        return null;
      }

      final String? storageUrl = catalog
          .firstWhere(
            (service) => service['type'] == 'object-store',
            orElse: () => null,
          )?['endpoints']
          ?.firstWhere(
            (endpoint) => endpoint['interface'] == 'public',
            orElse: () => null,
          )?['url'];

      if (storageUrl == null) {
        print("Error: Storage URL not found in authentication response.");
        return null;
      }

      // Step 3: Build the image URL and fetch the image
      final String imageUrl = '$storageUrl/$bucketName/tool_images/$fileName';
      final http.Response imageResponse = await http.get(
        Uri.parse(imageUrl),
        headers: {'X-Auth-Token': authToken},
      );

      if (imageResponse.statusCode != 200) {
        print(
            "Failed to fetch image. Status code: ${imageResponse.statusCode}");
        print("Response body: ${imageResponse.body}");
        return null;
      }

      // Return the image bytes
      return imageResponse.bodyBytes;
    } catch (e) {
      print("Error fetching private image: $e");
      return null;
    }
  }
}

final imageCacheManager = ImageCacheManager();

class YourRentalsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Rentals'),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('tools').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
          final List<Map<String, dynamic>> rentedTools = [];
          for (final toolDoc in tools) {
            final toolData = toolDoc.data() as Map?;
            if (toolData == null) continue;
            final bookings =
                List<Map<String, dynamic>>.from(toolData['bookings'] ?? []);
            for (final booking in bookings) {
              if (booking['userId'] == currentUser.uid) {
                rentedTools.add({
                  'toolId': toolDoc.id, // Add tool ID for Firestore reference
                  'toolName': toolData['toolName'] ?? 'Unnamed Tool',
                  'price': toolData['price'] ?? 'N/A',
                  'quantityBooked': booking['quantityBooked'] ?? 0,
                  'description': toolData['description'] ?? 'No description',
                  'imageUrl': toolData['imageUrl'] ?? '', // Optional image URL
                  'toolOwnerUserId': toolData['userId'], // Owner's user ID
                  'startDate': booking['startDate'] ?? 'Unknown Start Date',
                  'endDate': booking['endDate'] ?? 'Unknown End Date',
                  'isAccepted': booking['isAccepted'] ?? false,
                  'isRejected': booking['isRejected'] ?? false,
                  'isGiven': booking['isGiven'] ?? false,
                  'isReturned': booking['isReturned'] ?? false,
                });
              }
            }
          }

          // Sort rented tools by startDate in ascending order
          rentedTools.sort((a, b) {
            final dateA = DateTime.tryParse(a['startDate']) ?? DateTime(9999);
            final dateB = DateTime.tryParse(b['startDate']) ?? DateTime(9999);
            return dateA.compareTo(dateB);
          });

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

              // Determine the status of the rental
              final bool isAccepted = rental['isAccepted'];
              final bool isRejected = rental['isRejected'];
              final bool isGiven = rental['isGiven'];
              final bool isReturned = rental['isReturned'];

              String status;
              Color statusColor;

              if (isRejected) {
                status = 'Rejected';
                statusColor = Colors.red;
              } else if (isAccepted && !isGiven) {
                status = 'Accepted but Not Taken';
                statusColor = Colors.orange;
              } else if (isAccepted && isGiven && !isReturned) {
                status = 'Taken';
                statusColor = Colors.blue;
              } else if (isAccepted && isGiven && isReturned) {
                status = 'Returned';
                statusColor = Colors.green;
              } else {
                status = 'Pending';
                statusColor = Colors.grey;
              }

              // Fetch the owner's details from the users collection
              return FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(rental['toolOwnerUserId'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (userSnapshot.hasError || !userSnapshot.hasData) {
                    return ListTile(title: Text('Owner details unavailable'));
                  }

                  final userData = userSnapshot.data!.data() as Map?;
                  final ownerName = userData?['name'] ?? 'Unknown Owner';
                  final ownerPhone = userData?['phone'] ?? 'N/A';
                  final ownerAddress =
                      '${userData?['house'] ?? ''}, ${userData?['area'] ?? ''}, ${userData?['city'] ?? ''}, ${userData?['state'] ?? ''}, ${userData?['pincode'] ?? ''}';

                  // Format the rental dates
                  final formattedStartDate =
                      rental['startDate'] != 'Unknown Start Date'
                          ? DateFormat('d MMM yyyy')
                              .format(DateTime.parse(rental['startDate']))
                          : 'Unknown Start Date';
                  final formattedEndDate =
                      rental['endDate'] != 'Unknown End Date'
                          ? DateFormat('d MMM yyyy')
                              .format(DateTime.parse(rental['endDate']))
                          : 'Unknown End Date';
                  final dateRange =
                      rental['startDate'] != 'Unknown Start Date' &&
                              rental['endDate'] != 'Unknown End Date'
                          ? 'From $formattedStartDate to $formattedEndDate'
                          : 'Unknown Date Range';

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tool Image (if available)
                          if (rental['imageUrl'].isNotEmpty)
                            FutureBuilder(
                              future: imageCacheManager
                                  .getImage(rental['imageUrl'].split('/').last),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                if (snapshot.hasError ||
                                    snapshot.data == null) {
                                  return Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.image_not_supported,
                                        size: 50),
                                  );
                                }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    snapshot.data!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
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
                          const SizedBox(height: 8),

                          // Rental Details
                          Row(
                            children: [
                              const Icon(Icons.attach_money,
                                  size: 16, color: Colors.teal),
                              const SizedBox(width: 4),
                              Text(
                                'Price: ₹${rental['price']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
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
                            dateRange,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),

                          // Status Indicator
                          Row(
                            children: [
                              Icon(Icons.circle, size: 12, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                'Status: $status',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),

                          // Cancel Button (Only for Pending Bookings)
                          if (status == 'Pending')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      // Remove the booking from Firestore
                                      final toolRef = FirebaseFirestore.instance
                                          .collection('tools')
                                          .doc(rental['toolId']);
                                      await FirebaseFirestore.instance
                                          .runTransaction((transaction) async {
                                        final toolDoc =
                                            await transaction.get(toolRef);
                                        if (!toolDoc.exists) {
                                          throw Exception(
                                              'Tool document not found.');
                                        }

                                        final toolData = toolDoc.data();
                                        final bookings =
                                            List<Map<String, dynamic>>.from(
                                                toolData?['bookings'] ?? []);

                                        // Find and remove the specific booking
                                        final updatedBookings =
                                            bookings.where((booking) {
                                          return booking['userId'] !=
                                                  currentUser.uid ||
                                              booking['startDate'] !=
                                                  rental['startDate'] ||
                                              booking['endDate'] !=
                                                  rental['endDate'];
                                        }).toList();

                                        transaction.update(toolRef,
                                            {'bookings': updatedBookings});
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Booking canceled successfully!')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Error canceling booking: $e')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.cancel, size: 16),
                                  label: const Text('Cancel Booking'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                  ),
                                ),
                              ],
                            ),

                          // Tool Owner Details
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person,
                                  size: 16, color: Colors.teal),
                              const SizedBox(width: 4),
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone,
                                  size: 16, color: Colors.teal),
                              const SizedBox(width: 4),
                              Text(
                                'Phone: $ownerPhone',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.teal),
                              const SizedBox(width: 4),
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
