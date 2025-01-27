import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StarScreen extends StatelessWidget {
  final String userId; // User ID passed to the screen

  StarScreen({required this.userId});

  Future<List<DocumentSnapshot>> _fetchStarredTools() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('starred_tools')
        .doc(userId)
        .collection('tools')
        .get();

    final toolIds = querySnapshot.docs.map((doc) => doc.id).toList();

    if (toolIds.isEmpty) {
      return [];
    }

    final toolsSnapshot = await FirebaseFirestore.instance
        .collection('tools')
        .where(FieldPath.documentId, whereIn: toolIds)
        .get();

    return toolsSnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Starred Tools'),
      // ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchStarredTools(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No starred tools yet!'));
          }

          final tools = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index].data() as Map<String, dynamic>;
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 6,
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool['toolName'] ?? 'Unknown Tool',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(tool['description'] ?? 'No description available'),
                      SizedBox(height: 4),
                      Text('Quantity: ${tool['quantity'] ?? 'N/A'}'),
                      SizedBox(height: 4),
                      Text('Price: \$${tool['price'] ?? 'N/A'} per day'),
                      SizedBox(height: 8),
                      Text('Contact: ${tool['contact'] ?? 'N/A'}'),
                      SizedBox(height: 4),
                      Text('Address: ${tool['location'] ?? 'N/A'}'),
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
