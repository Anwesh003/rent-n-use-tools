import 'dart:convert';
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

  File? _selectedImage; // Stores the newly picked image
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
        _selectedImage = File(pickedFile.path); // Update the selected image
      });
    }
  }

  Future<void> _saveChanges() async {
    final newImageUrl = _selectedImage != null
        ? await _uploadImage(_selectedImage!)
        : widget.imageUrl; // Use existing image URL if no new image is selected

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
      final String authUrl = 'http://authenticate.blomp.com/v3/auth/tokens';
      final String username =
          'anweshkrishnab6324@gmail.com'; // Replace with secure credentials
      final String password =
          '5cmYC5!QzP!NsKG'; // Replace with secure credentials
      final String bucketName =
          'anweshkrishnab6324@gmail.com'; // Replace with your bucket name

      final Map authPayload = {
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

      final Map authData = jsonDecode(authResponse.body);
      final List? catalog = authData['token']?['catalog'];
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

      // Step 3: Upload the compressed image to Blomp
      final fileName =
          'tool_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final uploadUrl = '$storageUrl/$bucketName/$fileName';

      final http.Response uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'X-Auth-Token': authToken,
          'Content-Type': 'image/jpeg',
        },
        body: compressedImage,
      );

      if (uploadResponse.statusCode != 201) {
        print("Image upload failed: ${uploadResponse.body}");
        return null;
      }

      // Step 4: Generate the public URL for the uploaded image
      final imageUrl = 'http://$bucketName.blomp.com/$fileName';
      return imageUrl;
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  Future<Uint8List?> _compressAndResizeImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        print("Error: Failed to decode the image.");
        return null;
      }

      final resizedImage =
          img.copyResize(decodedImage, width: 800, height: 600);

      int quality = 70;
      Uint8List? compressedImage;
      do {
        compressedImage =
            Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
        quality -= 5;
      } while (compressedImage.lengthInBytes > 150 * 1024 && quality > 10);

      if (quality <= 10) {
        print("Warning: Image could not be compressed below 150KB.");
      }

      return compressedImage;
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
                      ? Image.file(_selectedImage!,
                          fit: BoxFit.cover) // Display newly picked image
                      : widget.imageUrl != null
                          ? FutureBuilder<Uint8List?>(
                              future: _fetchPrivateImage(
                                  widget.imageUrl!.split('/').last),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError ||
                                    snapshot.data == null) {
                                  return Center(
                                    child: Text(
                                      'Failed to load image.',
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 16),
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
                                  "Tap to select an image")), // No image available
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

      final Map authPayload = {
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

      final Map authData = jsonDecode(authResponse.body);
      final List? catalog = authData['token']?['catalog'];
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
