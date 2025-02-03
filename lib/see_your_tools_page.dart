import 'dart:io'; // For HttpClient and related classes
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'edit_tool_page.dart';

class SeeYourToolsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('See Your Tools')),
        body: Center(
          child: Text(
            'You must be logged in to see your tools.',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.redAccent),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Tools'),
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
            return Center(child: CircularProgressIndicator());
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
              final imageUrl = tool['imageUrl'] as String?;
              final int quantity = tool['quantity'] is num
                  ? tool['quantity'].toInt()
                  : int.tryParse(tool['quantity'].toString()) ?? 0;
              final double price = tool['price'] is num
                  ? tool['price'].toDouble()
                  : double.tryParse(tool['price'].toString()) ?? 0.0;
              final bool isAvailable =
                  tool['isAvailable'] ?? true; // Default to true

              return Card(
                margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                      GestureDetector(
                        onTap: imageUrl != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenImage(
                                      imageUrl: imageUrl,
                                    ),
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
                      SizedBox(height: 16),
                      Text(
                        tool['toolName'] ?? 'Unknown Tool',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.teal,
                        ),
                      ),
                      SizedBox(height: 10),
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
                      SizedBox(height: 12),
                      Text(
                        'Description:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        tool['description'] ?? 'No description available',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Availability:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
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
                                              : 'Tool is now unavailable.')),
                                    );
                                  } catch (e) {
                                    print('Error updating availability: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
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
                            icon: Icon(Icons.edit, color: Colors.teal),
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

  FullScreenImage({required this.imageUrl});

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
        child: FutureBuilder(
          future: _fetchImage(imageUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Failed to load image.',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              );
            }
            if (!snapshot.hasData) {
              return Center(
                child: Text(
                  'No image available.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }
            return Center(
              child: InteractiveViewer(
                boundaryMargin: EdgeInsets.all(20.0),
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

  Future<Uint8List?> _fetchImage(String url) async {
    try {
      final HttpClient httpClient = HttpClient();
      httpClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              true; // Ignore SSL errors

      final HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        // Read the response bytes and flatten the List<List<int>> into List<int>
        final List<List<int>> byteChunks =
            await response.cast<List<int>>().toList();
        final List<int> bytes =
            byteChunks.expand((chunk) => chunk).toList(); // Flatten the chunks
        return Uint8List.fromList(bytes); // Convert to Uint8List
      } else {
        print('Failed to fetch image. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching image: $e');
      return null;
    }
  }
}
