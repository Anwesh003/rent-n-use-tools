import 'package:flutter/material.dart';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Makes the AppBar transparent so the image can be seen behind it.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context); // Close the full-screen view on tap.
        },
        onDoubleTap: () {
          // Optional: Add a double-tap to reset zoom.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Zoom reset')),
          );
        },
        child: Center(
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(20.0),
            minScale: 0.5, // Minimum zoom level
            maxScale: 4.0, // Maximum zoom level
            constrained:
                false, // Allows the image to exceed screen bounds when zoomed.
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 50, color: Colors.red),
                      SizedBox(height: 10),
                      Text(
                        'Error loading image',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
