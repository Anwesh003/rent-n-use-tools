import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package

class ImageCacheManager {
  final Map _cache = {};

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
    // Same implementation as before...
  }
}

final imageCacheManager = ImageCacheManager();

class RentedToolsPage extends StatelessWidget {
  const RentedToolsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rented Tools')),
        body: Center(
          child: Text(
            'You must be logged in to see rented tools.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.redAccent,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Who Rented Your Tools'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tools')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
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
                'You have no tools listed.',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.grey[600],
                ),
              ),
            );
          }

          final tools = snapshot.data!.docs;

          // Filter tools with valid bookings
          final rentedTools = tools.where((tool) {
            final toolData = tool.data() as Map<String, dynamic>?;
            final bookings = toolData?['bookings'];
            if (bookings == null || !(bookings is List) || bookings.isEmpty) {
              return false;
            }
            return true;
          }).toList();

          if (rentedTools.isEmpty) {
            return Center(
              child: Text(
                'No tools have been rented yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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

              // Count pending and rejected bookings
              final pendingBookingsCount = bookings
                  .where((booking) =>
                      booking['isAccepted'] == null || !booking['isAccepted'])
                  .length;
              final rejectedBookingsCount = bookings
                  .where((booking) => booking['isRejected'] == true)
                  .length;

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (pendingBookingsCount > 0)
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Text(
                            '$pendingBookingsCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (rejectedBookingsCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey,
                            child: Text(
                              '$rejectedBookingsCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    toolName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.teal,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.all(16),
                  children: bookings.map((booking) {
                    final renterUserId = booking['userId'] ?? 'Unknown User';
                    final startDate =
                        booking['startDate'] ?? 'Unknown Start Date';
                    final endDate = booking['endDate'] ?? 'Unknown End Date';
                    final quantityBooked = booking['quantityBooked'] ?? 0;
                    final isAccepted = booking['isAccepted'] ?? false;
                    final isRejected = booking['isRejected'] ?? false;

                    // Format dates to show only the date (e.g., "23 February 2025")
                    final formattedStartDate = startDate != 'Unknown Start Date'
                        ? DateFormat('d MMMM yyyy')
                            .format(DateTime.parse(startDate))
                        : 'Unknown Start Date';
                    final formattedEndDate = endDate != 'Unknown End Date'
                        ? DateFormat('d MMMM yyyy')
                            .format(DateTime.parse(endDate))
                        : 'Unknown End Date';

                    // Combine start and end dates into a single string
                    final dateRange = startDate != 'Unknown Start Date' &&
                            endDate != 'Unknown End Date'
                        ? 'From $formattedStartDate to $formattedEndDate'
                        : 'Unknown Date Range';

                    // Fetch user details for the renter
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(renterUserId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(
                            title: Text('Loading renter details...'),
                          );
                        }

                        if (userSnapshot.hasError || !userSnapshot.hasData) {
                          return ListTile(
                            title: Text('Failed to load renter details.'),
                          );
                        }

                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>?;

                        final name = userData?['name'] ?? 'Unknown Renter';
                        final phone = userData?['phone'] ?? 'N/A';
                        final house = userData?['house'] ?? 'N/A';
                        final area = userData?['area'] ?? 'N/A';
                        final city = userData?['city'] ?? 'N/A';
                        final state = userData?['state'] ?? 'N/A';
                        final pincode = userData?['pincode'] ?? 'N/A';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: Icon(
                                isRejected
                                    ? Icons.cancel_outlined
                                    : Icons.person,
                                color: isRejected ? Colors.red : Colors.teal,
                              ),
                              title: Text(
                                'Renter Name: $name',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDarkMode ? Colors.white : Colors.teal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Phone: $phone'),
                                  Text('Address: $house, $area'),
                                  Text('City: $city, State: $state'),
                                  Text('Pincode: $pincode'),
                                  const SizedBox(height: 8),
                                  Text(
                                    dateRange,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Quantity Booked: $quantityBooked',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (isRejected)
                                    Text(
                                      'Status: Rejected',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: isRejected || isAccepted
                                      ? null
                                      : () async {
                                          try {
                                            await FirebaseFirestore.instance
                                                .collection('tools')
                                                .doc(tool.id)
                                                .update({
                                              'bookings':
                                                  FieldValue.arrayRemove(
                                                      [booking])
                                            });
                                            await FirebaseFirestore.instance
                                                .collection('tools')
                                                .doc(tool.id)
                                                .update({
                                              'bookings':
                                                  FieldValue.arrayUnion([
                                                {
                                                  ...booking,
                                                  'isRejected': true,
                                                }
                                              ]),
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content:
                                                    Text('Booking rejected!'),
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Failed to reject booking.'),
                                              ),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('Reject'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: isRejected || isAccepted
                                      ? null
                                      : () async {
                                          try {
                                            await FirebaseFirestore.instance
                                                .collection('tools')
                                                .doc(tool.id)
                                                .update({
                                              'bookings':
                                                  FieldValue.arrayRemove(
                                                      [booking])
                                            });
                                            await FirebaseFirestore.instance
                                                .collection('tools')
                                                .doc(tool.id)
                                                .update({
                                              'bookings':
                                                  FieldValue.arrayUnion([
                                                {
                                                  ...booking,
                                                  'isAccepted': true,
                                                }
                                              ]),
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content:
                                                    Text('Booking accepted!'),
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Failed to accept booking.'),
                                              ),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Accept'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
