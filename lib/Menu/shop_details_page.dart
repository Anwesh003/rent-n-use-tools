import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopDetailsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Details'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('shops').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No shops available.'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var shopData =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildShopCard(
                context: context,
                shopName: shopData['shopName'] ?? 'Unknown Shop',
                phone: shopData['phone'] ?? 'No phone available',
                address: shopData['address'] ?? 'No address available',
                description:
                    shopData['description'] ?? 'No description available.',
                type: shopData['type'] ?? 'Unknown Type',
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShopCard({
    required BuildContext context,
    required String shopName,
    required String phone,
    required String address,
    required String description,
    required String type,
  }) {
    // Replace literal '\n' with actual newline characters
    final formattedDescription = description.replaceAll(r'\n', '\n');

    // Parse the description for bold text
    List<TextSpan> parsedDescription = _parseDescription(formattedDescription);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Name and Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    shopName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(
                    type,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.blueGrey[700]
                          : Colors.blue[100],
                ),
              ],
            ),
            SizedBox(height: 8),
            // Phone Number
            InkWell(
              onTap: () => _launchPhone(context, phone),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      phone,
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            // Address
            Row(
              children: [
                Icon(Icons.location_on, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Description
            Text(
              'Description:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style:
                    DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                children: parsedDescription,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _parseDescription(String description) {
    // Split the description by '**' to find bold segments
    List<String> parts = description.split('**');
    List<TextSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        // Odd-indexed parts are bold
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(fontWeight: FontWeight.bold),
        ));
      } else {
        // Even-indexed parts are normal text
        spans.add(TextSpan(text: parts[i]));
      }
    }

    return spans;
  }

  Future<void> _launchPhone(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $phoneNumber')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching phone: $e')),
      );
    }
  }
}
