import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'FullToolDetails.dart'; // Import the FullToolDetails page

class StarScreen extends StatelessWidget {
  final String userId; // User ID passed to the screen
  StarScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
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
          return StreamBuilder(
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
                  final tool = tools[index].data() as Map;
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
                              totalQuantity: tool['quantity'] ?? 0,
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
                                FutureBuilder<Uint8List?>(
                                  future: _fetchPrivateImage(tool['imageUrl']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      );
                                    }
                                    if (snapshot.hasError ||
                                        snapshot.data == null) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.image,
                                            size: 40, color: Colors.white),
                                      );
                                    }
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        snapshot.data!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
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

  /// Fetches a private image securely using Blomp (OpenStack API)
  Future<Uint8List?> _fetchPrivateImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
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
      final String fileName = imageUrl.split('/').last;
      final String fullImageUrl =
          '$storageUrl/$bucketName/tool_images/$fileName';

      final http.Response imageResponse = await http.get(
        Uri.parse(fullImageUrl),
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
