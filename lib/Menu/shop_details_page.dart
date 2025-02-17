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
                          ? Colors.white // Light text for dark mode
                          : Colors.black, // Dark text for light mode
                    ),
                  ),
                  backgroundColor: Theme.of(context).brightness ==
                          Brightness.dark
                      ? Colors.blueGrey[700] // Darker background for dark mode
                      : Colors.blue[100], // Lighter background for light mode
                ),
              ],
            ),
            SizedBox(
                height:
                    8), // Add spacing between shop name/type and phone number
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
            SizedBox(height: 8), // Add spacing between phone number and address
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
            SizedBox(height: 8), // Add spacing between address and description
            // Description
            Text(
              'Description:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
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
