import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'BookingPage.dart'; // Import the BookingPage

/// Image Cache Manager for Private Images
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

class FullToolDetails extends StatelessWidget {
  final String toolId; // Use a unique tool ID instead of toolName
  final String toolName;
  final int totalQuantity;
  final double price;
  final String location;
  final String contact;
  final String description;
  final String imageUrl;
  final bool isAvailable;

  const FullToolDetails({
    Key? key,
    required this.toolId,
    required this.toolName,
    required this.totalQuantity,
    required this.price,
    required this.location,
    required this.contact,
    required this.description,
    required this.imageUrl,
    required this.isAvailable,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(toolName),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool Image
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImage(imageUrl: imageUrl),
                  ),
                );
              },
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FutureBuilder<Uint8List?>(
                  future: imageCacheManager.getImage(imageUrl.split('/').last),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || snapshot.data == null) {
                      return Center(
                        child: Icon(Icons.error, size: 50, color: Colors.red),
                      );
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            // Tool Name
            Text(
              toolName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.teal,
              ),
            ),
            SizedBox(height: 8),
            // Availability Status
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  isAvailable ? 'Available' : 'Not Available',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Price
            Text(
              'Price: ₹${price.toStringAsFixed(2)} per day',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.greenAccent : Colors.green,
              ),
            ),
            SizedBox(height: 8),
            // Quantity
            Text(
              'Total Quantity: $totalQuantity',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            // Location
            Text(
              'Location: $location',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            // Contact
            Text(
              'Contact: $contact',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.blueAccent : Colors.blue,
              ),
            ),
            SizedBox(height: 16),
            // Description
            Text(
              'Description:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),

            // Book Now Button and Ratings Details
            Column(
              children: [
                ElevatedButton(
                  onPressed: isAvailable
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingPage(
                                toolId: toolId, // Pass the unique tool ID
                                toolName: toolName,
                                price: price,
                                totalQuantity: totalQuantity,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAvailable ? Colors.teal : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20, // Increase vertical padding for height
                      horizontal: 60, // Increase horizontal padding for width
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    isAvailable ? 'Book Now' : 'Not Available',
                    style: TextStyle(
                      color: isAvailable ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder(
                  future: _fetchFeedback(toolId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Text('No ratings available.');
                    }
                    final feedbackData = snapshot.data!;
                    final double averageRating = feedbackData['averageRating'];
                    final List<dynamic> reviews = feedbackData['reviews'];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Average Rating
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              '${averageRating.toStringAsFixed(1)} (${reviews.length} reviews)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Individual Reviews
                        if (reviews.isNotEmpty)
                          Column(
                            children: reviews.map((review) {
                              return ListTile(
                                leading: const Icon(Icons.account_circle,
                                    size: 40, color: Colors.teal),
                                title: Text(
                                  review['feedback'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${review['rating']} stars'),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                        else
                          const Text('No reviews yet.'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// FullScreenImage Widget
class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: FutureBuilder<Uint8List?>(
          future: imageCacheManager.getImage(imageUrl.split('/').last),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Icon(Icons.error, size: 50, color: Colors.red),
              );
            }
            return InteractiveViewer(
              boundaryMargin: EdgeInsets.all(20.0),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>> _fetchFeedback(String toolId) async {
  final toolDoc =
      await FirebaseFirestore.instance.collection('tools').doc(toolId).get();
  final feedbacks =
      List<Map<String, dynamic>>.from(toolDoc.data()?['feedbacks'] ?? []);

  if (feedbacks.isEmpty) {
    return {'averageRating': 0.0, 'reviews': []};
  }

  // Calculate average rating
  final totalRating = feedbacks.fold(
      0.0,
      (double sum, feedback) =>
          sum + feedback['rating']); // Use 0.0 to ensure double
  final averageRating =
      totalRating / feedbacks.length; // Ensure this is treated as a double

  return {
    'averageRating': averageRating, // Return as double
    'reviews': feedbacks,
  };
}
