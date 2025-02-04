import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'edit_tool_page.dart';

class SeeYourToolsPage extends StatelessWidget {
  const SeeYourToolsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('See Your Tools')),
        body: Center(
          child: Text(
            'You must be logged in to see your tools.',
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
        title: const Text('Your Tools'),
        backgroundColor: Colors.teal,
        elevation: 4,
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
          return ListView.builder(
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              final String? imageUrl = tool['imageUrl'] as String?;
              final int quantity = tool['quantity'] is num
                  ? tool['quantity'].toInt()
                  : int.tryParse(tool['quantity'].toString()) ?? 0;
              final double price = tool['price'] is num
                  ? tool['price'].toDouble()
                  : double.tryParse(tool['price'].toString()) ?? 0.0;
              final bool isAvailable = tool['isAvailable'] ?? true;

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: isDarkMode
                    ? (isAvailable ? Colors.grey[850] : Colors.grey[700])
                    : (isAvailable ? Colors.white : Colors.grey[300]),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tapping the image opens it in fullscreen.
                      GestureDetector(
                        onTap: imageUrl != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FullScreenImage(imageUrl: imageUrl),
                                  ),
                                );
                              }
                            : null,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    'No image uploaded yet',
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 16),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tool['toolName'] ?? 'Unknown Tool',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Quantity: $quantity',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Text(
                        'Price: ₹${price.toStringAsFixed(2)} per day',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.greenAccent : Colors.green,
                        ),
                      ),
                      Text(
                        'Location: ${tool['location'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Text(
                        'Contact: ${tool['contact'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.blueAccent : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Description:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tool['description'] ?? 'No description available',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Availability:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Switch(
                                value: isAvailable,
                                onChanged: (value) async {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('tools')
                                        .doc(tool.id)
                                        .update({'isAvailable': value});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(value
                                            ? 'Tool is now available.'
                                            : 'Tool is now unavailable.'),
                                      ),
                                    );
                                  } catch (e) {
                                    print('Error updating availability: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Failed to update availability.')),
                                    );
                                  }
                                },
                                activeColor: Colors.teal,
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.teal),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditToolPage(
                                    toolId: tool.id,
                                    toolName: tool['toolName'],
                                    quantity: quantity,
                                    price: price,
                                    location: tool['location'],
                                    contact: tool['contact'],
                                    description: tool['description'],
                                    imageUrl: imageUrl,
                                  ),
                                ),
                              );
                            },
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
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tapping anywhere on the image returns to the previous screen.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: FutureBuilder<Uint8List?>(
          future: _fetchImage(imageUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Failed to load image.',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Text(
                  'No image available.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }
            return Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(20.0),
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Fetch an image from a public URL.
/// The URL must be properly formatted.
Future<Uint8List?> _fetchImage(String url) async {
  try {
    final HttpClient httpClient = HttpClient();
    // Bypass SSL errors (only for development)
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    final Uri uri = Uri.parse(url);
    final HttpClientRequest request = await httpClient.getUrl(uri);
    final HttpClientResponse response = await request.close();

    if (response.statusCode == 200) {
      final List<List<int>> byteChunks =
          await response.cast<List<int>>().toList();
      final List<int> bytes = byteChunks.expand((chunk) => chunk).toList();
      return Uint8List.fromList(bytes);
    } else {
      print('Failed to fetch image. Status code: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching image: $e');
    return null;
  }
}

/// Fetch a private image from Blomp using authentication.
Future<Uint8List?> _fetchPrivateImage(String? fileName) async {
  if (fileName == null || fileName.isEmpty) {
    print("Error: File name is null or empty.");
    return null;
  }

  try {
    // Step 1: Authenticate with Blomp.
    final String authUrl = 'https://authenticate.blomp.com/v3/auth/tokens';
    final String username =
        'anweshkrishnab6324@gmail.com'; // Insecure: replace with a secure method.
    final String password =
        '5cmYC5!QzP!NsKG'; // Insecure: replace with a secure method.
    final String bucketName =
        'anweshkrishnab6324@gmail.com'; // Replace with your bucket name if needed.

    final Map<String, dynamic> authPayload = {
      "auth": {
        "identity": {
          "methods": ["password"],
          "password": {
            "user": {
              "name": username,
              "domain": {"id": "default"},
              "password": password
            }
          }
        }
      }
    };

    final HttpClient httpClient = HttpClient();
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

    // Perform authentication.
    final HttpClientRequest authRequest =
        await httpClient.postUrl(Uri.parse(authUrl));
    authRequest.headers.contentType = ContentType.json;
    authRequest.write(jsonEncode(authPayload));
    final HttpClientResponse authResponse = await authRequest.close();

    if (authResponse.statusCode != 201) {
      print(
          "Authentication failed: ${await authResponse.transform(utf8.decoder).join()}");
      return null;
    }

    // Extract the token.
    final String? authToken = authResponse.headers.value('x-subject-token');
    if (authToken == null) {
      print(
          "Error: X-Subject-Token header not found in authentication response.");
      return null;
    }

    // Build the final image URL safely using Dart's Uri constructor.
    final Uri imageUri = Uri(
      scheme: 'https',
      host: 'www.blomp.com',
      // Ensure the path starts with a slash.
      path: '/tool_images/$fileName',
    );
    print("Final image URL: ${imageUri.toString()}");

    final HttpClientRequest imageRequest = await httpClient.getUrl(imageUri);
    imageRequest.headers.add('X-Auth-Token', authToken);
    final HttpClientResponse imageResponse = await imageRequest.close();

    if (imageResponse.statusCode != 200) {
      print("Failed to fetch image. Status code: ${imageResponse.statusCode}");
      print(
          "Response body: ${await imageResponse.transform(utf8.decoder).join()}");
      return null;
    }

    final List<int> byteChunks = [];
    await for (final chunk in imageResponse) {
      byteChunks.addAll(chunk);
    }
    return Uint8List.fromList(byteChunks);
  } catch (e) {
    print("Error fetching private image: $e");
    return null;
  }
}
