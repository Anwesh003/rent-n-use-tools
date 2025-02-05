import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../MainScreen/BookingPage.dart'; // For booking functionality
import '../MainScreen/FullToolDetails.dart'; // For full tool details

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

class ToolsScreen extends StatefulWidget {
  final String userId;

  ToolsScreen({required this.userId});

  @override
  _ToolsScreenState createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  List _tools = [];
  Set _starredToolIds = {};
  bool _isLoading = false;
  bool _hasMore = true;
  int _documentLimit = 5;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _fetchTools();
    _fetchStarredTools();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !_isLoading &&
          _hasMore) {
        _fetchTools();
      }
    });
  }

  Future<void> _fetchTools() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      Query query = _firestore
          .collection('tools')
          .where('isAvailable', isEqualTo: true)
          .orderBy('toolName')
          .limit(_documentLimit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _lastDocument = querySnapshot.docs.last;
          _tools.addAll(querySnapshot.docs);
          if (querySnapshot.docs.length < _documentLimit) {
            _hasMore = false;
          }
        });
      } else {
        setState(() {
          _hasMore = false;
        });
      }
    } catch (e) {
      print('Error fetching tools: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchStarredTools() async {
    try {
      final snapshot = await _firestore
          .collection('starred_tools')
          .doc(widget.userId)
          .collection('tools')
          .get();

      setState(() {
        _starredToolIds = snapshot.docs.map((doc) => doc.id).toSet();
      });
    } catch (e) {
      print('Error fetching starred tools: $e');
    }
  }

  Future<void> _toggleStar(String toolId) async {
    try {
      final starredDoc = _firestore
          .collection('starred_tools')
          .doc(widget.userId)
          .collection('tools')
          .doc(toolId);

      final doc = await starredDoc.get();

      if (doc.exists) {
        await starredDoc.delete();
        setState(() {
          _starredToolIds.remove(toolId);
        });
      } else {
        await starredDoc.set({'toolId': toolId});
        setState(() {
          _starredToolIds.add(toolId);
        });
      }
    } catch (e) {
      print('Error toggling star: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _tools.isEmpty && !_isLoading
          ? Center(
              child: Text(
                'No tools are currently available.',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.grey[600],
                ),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: _tools.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _tools.length) {
                  return Center(child: CircularProgressIndicator());
                }

                final tool = _tools[index];
                final imageUrl = tool['imageUrl'] as String?;
                final int quantity =
                    tool['quantity'] is num ? tool['quantity'].toInt() : 0;
                final double price =
                    tool['price'] is num ? tool['price'].toDouble() : 0.0;
                final bool isAvailable = tool['isAvailable'] ?? true;

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullToolDetails(
                            toolId: tool.id, // Firestore document ID
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
                          // Tool Image
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: imageUrl != null
                                ? FutureBuilder<Uint8List?>(
                                    future: imageCacheManager
                                        .getImage(imageUrl.split('/').last),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (snapshot.hasError ||
                                          snapshot.data == null) {
                                        return Center(
                                          child: Text(
                                            'Failed to load image.',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 16,
                                            ),
                                          ),
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
                                  )
                                : Center(
                                    child: Text(
                                      'No image uploaded yet',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                          ),
                          SizedBox(height: 16),
                          // Tool Name and Star Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  tool['toolName'] ?? 'Unknown Tool',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDarkMode ? Colors.white : Colors.teal,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _starredToolIds.contains(tool.id)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                ),
                                onPressed: () => _toggleStar(tool.id),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          // Price
                          Text(
                            'Price: ₹${price.toStringAsFixed(2)} per day',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode
                                  ? Colors.greenAccent
                                  : Colors.green,
                            ),
                          ),
                          SizedBox(height: 8),
                          // Quantity
                          Text(
                            'Quantity: $quantity',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          // Location
                          Text(
                            'Location: ${tool['location'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          // Description
                          Text(
                            'Description: ${tool['description'] ?? 'No description available'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          // Book Now Button
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingPage(
                                    toolId: tool.id,
                                    toolName: tool['toolName'],
                                    price: price,
                                    totalQuantity: quantity,
                                  ),
                                ),
                              );
                            },
                            child: Text('Book Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
