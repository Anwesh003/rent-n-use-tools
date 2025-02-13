import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class ReportedProblemsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchReportedTools(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No reports have been submitted yet. \nEverything seems to be working fine.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          final reportedTools = snapshot.data!;
          return ListView.builder(
            itemCount: reportedTools.length,
            itemBuilder: (context, index) {
              final tool = reportedTools[index];
              final toolName = tool['toolName'];
              final problems = tool['problems'] as List<dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        toolName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    ...problems.map((problem) {
                      final problemDescription = problem['problem'] as String;
                      final reporterUserId = problem['userId'] as String?;
                      final timestamp = problem['timestamp'] as Timestamp;
                      final formattedDate = DateFormat('d MMM yyyy, hh:mm a')
                          .format(timestamp.toDate());

                      // Fetch reporter's details from Firestore
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(reporterUserId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const ListTile(
                              title: Text('Loading reporter details...'),
                            );
                          }
                          if (userSnapshot.hasError || !userSnapshot.hasData) {
                            return ListTile(
                              title: Text('Failed to load reporter details.'),
                            );
                          }
                          final userData = userSnapshot.data!.data()
                              as Map<String, dynamic>?;
                          final reporterName =
                              userData?['name'] ?? 'Unknown User';
                          final reporterPhone = userData?['phone'] ?? 'N/A';
                          final house = userData?['house'] ?? 'N/A';
                          final area = userData?['area'] ?? 'N/A';
                          final city = userData?['city'] ?? 'N/A';
                          final state = userData?['state'] ?? 'N/A';
                          final pincode = userData?['pincode'] ?? 'N/A';
                          final address =
                              '$house, $area, $city, $state, $pincode';

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person,
                                        size: 16, color: Colors.teal),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Reported by: $reporterName',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.phone,
                                        size: 16, color: Colors.teal),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Phone: $reporterPhone',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        size: 16, color: Colors.teal),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Address: $address',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  problemDescription,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Divider(),
                              ],
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Fetch reported tools from Firestore
  Future<List<Map<String, dynamic>>> _fetchReportedTools() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    try {
      // Fetch tools where the current user is the owner
      final toolsSnapshot = await FirebaseFirestore.instance
          .collection('tools')
          .where('userId', isEqualTo: user.uid)
          .get();
      final reportedTools = <Map<String, dynamic>>[];
      for (final toolDoc in toolsSnapshot.docs) {
        final toolData = toolDoc.data();
        final problems =
            List<Map<String, dynamic>>.from(toolData['problems'] ?? []);
        if (problems.isNotEmpty) {
          reportedTools.add({
            'toolId': toolDoc.id,
            'toolName': toolData['toolName'] ?? 'Unnamed Tool',
            'problems': problems,
          });
        }
      }
      return reportedTools;
    } catch (e) {
      print("Error fetching reported tools: $e");
      return [];
    }
  }
}
