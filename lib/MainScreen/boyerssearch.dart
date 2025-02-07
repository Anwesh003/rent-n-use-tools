import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart'; // For fuzzy matching
import 'package:http/http.dart' as http;

import 'BookingPage.dart';
import 'FullToolDetails.dart';

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
      final Map<String, dynamic> authPayload = {
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
      final Map<String, dynamic> authData = jsonDecode(authResponse.body);
      final List<dynamic>? catalog = authData['token']?['catalog'];
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

final ImageCacheManager imageCacheManager = ImageCacheManager();

/// Boyer–Moore Search Algorithm Implementation
class BoyerMoore {
  static List<int> _buildBadCharacterTable(String pattern) {
    final table = List.filled(256, pattern.length);
    for (var i = 0; i < pattern.length - 1; i++) {
      table[pattern.codeUnitAt(i)] = pattern.length - 1 - i;
    }
    return table;
  }

  /// Returns the starting index of [pattern] in [text] or -1 if not found.
  static int indexOf(String text, String pattern) {
    final n = text.length;
    final m = pattern.length;
    if (m == 0) return 0;
    if (m > n) return -1;
    final badCharTable = _buildBadCharacterTable(pattern);
    int s = 0; // shift of the pattern with respect to text
    while (s <= n - m) {
      int j = m - 1;
      while (j >= 0 && pattern[j] == text[s + j]) {
        j--;
      }
      if (j < 0) {
        return s; // match found at shift s
      }
      s += badCharTable[text.codeUnitAt(s + j)];
    }
    return -1; // no match found
  }

  static bool containsAny(String text, List<String> tokens) {
    for (final token in tokens) {
      if (indexOf(text, token) != -1) {
        return true;
      }
    }
    return false;
  }
}

/// Advanced Search using Fuzzy Matching
class AdvancedSearch {
  static bool fuzzyMatch(String text, List<String> tokens) {
    // Adjust threshold to make matching more flexible
    final fuzzy = Fuzzy(
      [text],
      options: FuzzyOptions(threshold: 0.3),
    );
    for (final token in tokens) {
      final results = fuzzy.search(token);
      if (results.isNotEmpty) {
        return true;
      }
    }
    return false;
  }
}

/// Main Screen with Search Functionality
class BoyerSearchScreen extends StatefulWidget {
  final String userId;
  final String? searchQuery; // Optional search query

  BoyerSearchScreen({required this.userId, this.searchQuery});

  @override
  _BoyerSearchScreenState createState() => _BoyerSearchScreenState();
}

class _BoyerSearchScreenState extends State<BoyerSearchScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _tools = [];
  Set<String> _starredToolIds = {};
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
      // Only allow pagination when no search query is provided
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !_isLoading &&
          _hasMore &&
          (widget.searchQuery == null || widget.searchQuery!.isEmpty)) {
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
      List<Map<String, dynamic>> tools = [];
      // If a search query is provided, fetch all available tools to filter locally
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        QuerySnapshot querySnapshot = await _firestore
            .collection('tools')
            .where('isAvailable', isEqualTo: true)
            .orderBy('toolName')
            .get();
        tools = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      } else {
        // Regular paginated fetch
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
          tools = querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
          _lastDocument = querySnapshot.docs.last;
          if (querySnapshot.docs.length < _documentLimit) {
            _hasMore = false;
          }
        } else {
          _hasMore = false;
        }
      }

      // Filter tools based on search query if provided
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        final lowerQuery = widget.searchQuery!.toLowerCase();
        final tokens = lowerQuery.split(' ');
        print("Search Query: $lowerQuery");
        print("Tokens: $tokens");

        tools = tools.where((tool) {
          final toolName = tool['toolName']?.toString().toLowerCase() ?? '';
          final description =
              tool['description']?.toString().toLowerCase() ?? '';

          // Basic search using Boyer–Moore
          final basicMatch = BoyerMoore.containsAny(toolName, tokens) ||
              BoyerMoore.containsAny(description, tokens);

          // Advanced fuzzy matching
          final advancedMatch = AdvancedSearch.fuzzyMatch(toolName, tokens) ||
              AdvancedSearch.fuzzyMatch(description, tokens);

          return basicMatch || advancedMatch;
        }).toList();
      }

      setState(() {
        // For search, replace the tools list; otherwise, append for pagination.
        if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
          _tools = tools;
        } else {
          _tools.addAll(tools);
        }
      });
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

  void _showSearchDialog(BuildContext context) {
    final TextEditingController _searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Search Tools'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Enter tool name or description',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final query = _searchController.text.trim();
                  if (query.isNotEmpty) {
                    Navigator.pop(context); // Close the dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BoyerSearchScreen(
                          userId: widget.userId,
                          searchQuery: query, // Pass the new search query
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a search query.')),
                    );
                  }
                },
                child: Text('Search'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.searchQuery != null ? 'Search Results' : 'Available Tools',
        ),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Exit search mode
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              _showSearchDialog(context); // Show search dialog
            },
          ),
        ],
      ),
      body: _tools.isEmpty && !_isLoading
          ? Center(
              child: Text(
                widget.searchQuery != null
                    ? 'No tools found for "${widget.searchQuery}".'
                    : 'No tools are currently available.',
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
                            toolId: tool['id'],
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
                                ? FutureBuilder(
                                    future: imageCacheManager
                                        .getImage(imageUrl.split('/').last),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
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
                                  _starredToolIds.contains(tool['id'])
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                ),
                                onPressed: () => _toggleStar(tool['id']),
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
                                    toolId: tool['id'],
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
