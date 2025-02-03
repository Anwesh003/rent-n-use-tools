import 'package:flutter/material.dart';

import 'BookingPage.dart'; // Import the BookingPage

class FullToolDetails extends StatelessWidget {
  final String toolId; // Use a unique tool ID instead of toolName
  final String toolName;
  final int totalQuantity;
  final double price;
  final String location;
  final String contact;
  final String description;
  final String imageUrl;
  final bool isAvailable;

  const FullToolDetails({
    Key? key,
    required this.toolId,
    required this.toolName,
    required this.totalQuantity,
    required this.price,
    required this.location,
    required this.contact,
    required this.description,
    required this.imageUrl,
    required this.isAvailable,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(toolName),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool Image
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImage(imageUrl: imageUrl),
                  ),
                );
              },
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.error, size: 50, color: Colors.red),
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Tool Name
            Text(
              toolName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.teal,
              ),
            ),
            SizedBox(height: 8),
            // Availability Status
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  isAvailable ? 'Available' : 'Not Available',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Price
            Text(
              'Price: ₹${price.toStringAsFixed(2)} per day',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.greenAccent : Colors.green,
              ),
            ),
            SizedBox(height: 8),
            // Quantity
            Text(
              'Total Quantity: $totalQuantity',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            // Location
            Text(
              'Location: $location',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            // Contact
            Text(
              'Contact: $contact',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.blueAccent : Colors.blue,
              ),
            ),
            SizedBox(height: 16),
            // Description
            Text(
              'Description:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            // Book Now Button
            ElevatedButton(
              onPressed: isAvailable
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingPage(
                            toolId: toolId, // Pass the unique tool ID
                            toolName: toolName,
                            price: price,
                            totalQuantity: totalQuantity,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvailable ? Colors.teal : Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                isAvailable ? 'Book Now' : 'Not Available',
                style: TextStyle(
                  color: isAvailable ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// FullScreenImage Widget
class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

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
        child: Center(
          child: InteractiveViewer(
            boundaryMargin: EdgeInsets.all(20.0),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(Icons.error, size: 50, color: Colors.red),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
