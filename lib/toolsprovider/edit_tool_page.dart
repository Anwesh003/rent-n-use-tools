import 'dart:convert'; // Add this import
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class EditToolPage extends StatefulWidget {
  final String toolId;
  final String toolName;
  final int quantity;
  final double price;
  final String location;
  final String contact;
  final String description;
  final String? imageUrl;

  EditToolPage({
    required this.toolId,
    required this.toolName,
    required this.quantity,
    required this.price,
    required this.location,
    required this.contact,
    required this.description,
    this.imageUrl,
  });

  @override
  _EditToolPageState createState() => _EditToolPageState();
}

class _EditToolPageState extends State<EditToolPage> {
  late TextEditingController _toolNameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _contactController;
  late TextEditingController _descriptionController;

  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _toolNameController = TextEditingController(text: widget.toolName);
    _quantityController =
        TextEditingController(text: widget.quantity.toString());
    _priceController = TextEditingController(text: widget.price.toString());
    _locationController = TextEditingController(text: widget.location);
    _contactController = TextEditingController(text: widget.contact);
    _descriptionController = TextEditingController(text: widget.description);
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    final newImageUrl = _selectedImage != null
        ? await _uploadImage(_selectedImage!)
        : widget.imageUrl;

    if (newImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('tools')
          .doc(widget.toolId)
          .update({
        'toolName': _toolNameController.text,
        'quantity': int.parse(_quantityController.text),
        'price': double.parse(_priceController.text),
        'location': _locationController.text,
        'contact': _contactController.text,
        'description': _descriptionController.text,
        'imageUrl': newImageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tool updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error updating tool: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update tool.')),
      );
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      print("Starting image upload process...");

      // Step 1: Compress and resize the image
      final compressedImage = await _compressAndResizeImage(image);
      if (compressedImage == null) {
        print("Error: Failed to compress or resize the image.");
        return null;
      }

      // Step 2: Authenticate with Blomp and get an access token
      final String authUrl = 'https://authenticate.blomp.com/v3/auth/tokens';
      final String username = 'anweshkrishnab6324@gmail.com'; // Blomp username
      final String password = '5cmYC5!QzP!NsKG'; // Securely store your password
      final String bucketName =
          'anweshkrishnab6324@gmail.com'; // Blomp bucket name

      print("Authenticating with Blomp...");
      print("Username: $username");
      print("Bucket Name: $bucketName");

      // Authentication payload
      final Map<String, dynamic> authPayload = {
        "auth": {
          "identity": {
            "methods": ["password"],
            "password": {
              "user": {
                "name": username,
                "domain": {"id": "default"},
                "password": password
              }
            }
          }
        }
      };

      print("Sending POST request to authenticate...");
      final authResponse = await http.post(
        Uri.parse(authUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(authPayload),
      );

      print("Authentication Response Status Code: ${authResponse.statusCode}");
      print("Authentication Response Body: ${authResponse.body}");

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

      print("Authentication successful. Access Token: $authToken");

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

      print("Storage URL: $storageUrl");

      // Step 3: Upload the compressed image to Blomp
      final fileName =
          'tool_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final uploadUrl = '$storageUrl/$bucketName/$fileName';

      print("Uploading image to URL: $uploadUrl");

      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'X-Auth-Token': authToken,
          'Content-Type': 'image/jpeg',
        },
        body: compressedImage, // Use the compressed image here
      );

      print("Image Upload Response Status Code: ${uploadResponse.statusCode}");
      print("Image Upload Response Body: ${uploadResponse.body}");

      if (uploadResponse.statusCode != 201) {
        print("Image upload failed: ${uploadResponse.body}");
        return null;
      }

      print("Image uploaded successfully.");

      // Step 4: Generate the public URL for the uploaded image
      final imageUrl = 'https://$bucketName.blomp.com/$fileName';
      print("Generated Public Image URL: $imageUrl");

      return imageUrl;
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

// Helper function to compress and resize the image
  Future<Uint8List?> _compressAndResizeImage(File imageFile) async {
    try {
      // Decode the image file
      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        print("Error: Failed to decode the image.");
        return null;
      }

      // Resize the image (e.g., reduce width and height to 800x600)
      final resizedImage =
          img.copyResize(decodedImage, width: 800, height: 600);

      // Compress the image iteratively until it's below 150KB
      int quality = 70; // Start with 70% quality
      Uint8List? compressedImage;

      do {
        compressedImage =
            Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
        quality -= 5; // Reduce quality by 5% each iteration
      } while (compressedImage.lengthInBytes > 150 * 1024 && quality > 10);

      if (quality <= 10) {
        print("Warning: Image could not be compressed below 150KB.");
      }

      print(
          "Image compressed and resized successfully. Final size: ${(compressedImage.lengthInBytes / 1024).toStringAsFixed(2)} KB");
      return compressedImage; // Return the compressed image bytes
    } catch (e) {
      print("Error during image compression: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Tool'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : widget.imageUrl != null
                          ? Image.network(widget.imageUrl!, fit: BoxFit.cover)
                          : Center(child: Text("Tap to select an image")),
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _toolNameController,
                label: 'Tool Name',
                icon: Icons.build,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _quantityController,
                label: 'Quantity',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: 'Price (₹ per day)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Location',
                icon: Icons.location_on,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _contactController,
                label: 'Contact Information',
                icon: Icons.phone,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 4,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                child: Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 16),
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
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
