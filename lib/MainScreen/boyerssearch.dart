import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../MainScreen/BookingPage.dart'; // For booking functionality
import '../MainScreen/FullToolDetails.dart'; // For full tool details

class BoyerMoore {
  static List<int> _buildBadCharacterTable(String pattern) {
    final table = <int>[];
    for (var i = 0; i < 256; i++) {
      table.add(pattern.length);
    }
    for (var i = 0; i < pattern.length - 1; i++) {
      table[pattern.codeUnitAt(i)] = pattern.length - 1 - i;
    }
    return table;
  }

  static int indexOf(String text, String pattern) {
    if (pattern.isEmpty || text.isEmpty) return -1;

    final badCharTable = _buildBadCharacterTable(pattern);
    int i = pattern.length - 1;

    while (i < text.length) {
      int j = pattern.length - 1;

      while (j >= 0 && text[i] == pattern[j]) {
        i--;
        j--;
      }

      if (j < 0) {
        return i + 1; // Match found
      }

      i += badCharTable[text.codeUnitAt(i)];
    }

    return -1; // No match found
  }
}

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
        List<Map<String, dynamic>> tools = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Add Firestore document ID to the map
          return data;
        }).toList();

        // Filter tools based on search query
        if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
          final lowerQuery = widget.searchQuery!.toLowerCase();
          tools = tools.where((tool) {
            final toolName = tool['toolName']?.toString().toLowerCase() ?? '';
            final description =
                tool['description']?.toString().toLowerCase() ?? '';
            return BoyerMoore.indexOf(toolName, lowerQuery) != -1 ||
                BoyerMoore.indexOf(description, lowerQuery) != -1;
          }).toList();
        }

        setState(() {
          _lastDocument = querySnapshot.docs.last;
          _tools.addAll(tools); // Add tools as maps
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
}
