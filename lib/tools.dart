import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ToolsScreen extends StatefulWidget {
  final String userId; // User ID passed to the screen

  ToolsScreen({required this.userId});

  @override
  _ToolsScreenState createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _tools = [];
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
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[200],
      body: _tools.isEmpty && _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16.0),
              itemCount: _tools.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _tools.length) {
                  return Center(child: CircularProgressIndicator());
                }

                final tool = _tools[index].data() as Map<String, dynamic>;
                final toolId = _tools[index].id;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 6,
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tool['toolName'] ?? 'Unknown Tool',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _starredToolIds.contains(toolId)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.orange,
                              ),
                              onPressed: () => _toggleStar(toolId),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          tool['description'] ?? 'No description available',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Quantity: ${tool['quantity'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Price: \$${tool['price'] ?? 'N/A'} per day',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isDarkMode ? Colors.greenAccent : Colors.green,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Contact: ${tool['contact'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.blueAccent : Colors.blue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Address: ${tool['location'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.orangeAccent
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
