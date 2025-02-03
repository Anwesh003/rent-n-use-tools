import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class PutItToRentPage extends StatefulWidget {
  @override
  _PutItToRentPageState createState() => _PutItToRentPageState();
}

class _PutItToRentPageState extends State<PutItToRentPage> {
  final TextEditingController _toolNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  String? _toolNameError;
  String? _quantityError;
  String? _descriptionError;
  String? _priceError;
  String? _locationError;
  String? _contactError;

  File? _selectedImage;
  bool _isUploading = false;
  bool _isAvailable = true; // New field for availability

  final ImagePicker _imagePicker = ImagePicker();
  Timer? _debounce;

  void _validateField() {
    setState(() {
      _toolNameError =
          _toolNameController.text.isEmpty ? "Tool name is required." : null;
      _quantityError = _quantityController.text.isEmpty ||
              int.tryParse(_quantityController.text) == null ||
              int.parse(_quantityController.text) <= 0
          ? "Quantity must be a positive number."
          : null;
      _descriptionError = _descriptionController.text.isEmpty ||
              _descriptionController.text.length < 10
          ? "Description should be at least 10 characters."
          : null;
      _priceError = _priceController.text.isEmpty ||
              double.tryParse(_priceController.text) == null ||
              double.parse(_priceController.text) <= 0 ||
              _priceController.text.length > 5
          ? "Price must be a valid number, greater than zero, and less than 5 digits."
          : null;
      _locationError = _locationController.text.isEmpty ||
              _locationController.text.length <= 25
          ? "Location must be more than 25 characters."
          : null;
      _contactError = _contactController.text.isEmpty ||
              !_isValidPhoneNumber(_contactController.text)
          ? "Please provide a valid contact number."
          : null;
    });
  }

  void _startDebounce() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(Duration(seconds: 1), _validateField);
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

  Future<void> _submitForm() async {
    _validateField();
    if (_toolNameError != null ||
        _quantityError != null ||
        _descriptionError != null ||
        _priceError != null ||
        _locationError != null ||
        _contactError != null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _toolNameError = "You need to be logged in to submit a tool.";
      });
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
    }

    // Parse quantity and price as numbers
    final int quantity = int.parse(_quantityController.text);
    final double price = double.parse(_priceController.text);

    final toolData = {
      'toolName': _toolNameController.text,
      'quantity': quantity, // Store as int
      'description': _descriptionController.text,
      'price': price, // Store as double
      'location': _locationController.text,
      'contact': _contactController.text,
      'userId': user.uid,
      'imageUrl': imageUrl, // Save the Blomp image URL
      'isAvailable': _isAvailable, // Add availability field
    };

    try {
      await FirebaseFirestore.instance.collection('tools').add(toolData);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tool successfully put to rent!")));
      _clearForm();
    } catch (e) {
      print("Error saving tool: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _clearForm() {
    _toolNameController.clear();
    _quantityController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _locationController.clear();
    _contactController.clear();
    setState(() {
      _selectedImage = null;
      _toolNameError = null;
      _quantityError = null;
      _descriptionError = null;
      _priceError = null;
      _locationError = null;
      _contactError = null;
      _isAvailable = true; // Reset availability to true
    });
  }

  bool _isValidPhoneNumber(String phone) {
    final phoneRegExp = RegExp(r'^[0-9]{10}$');
    return phoneRegExp.hasMatch(phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Put It to Rent'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tool Information',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              _buildTextField(
                  controller: _toolNameController,
                  label: 'Tool Name',
                  icon: Icons.build,
                  errorMessage: _toolNameError),
              SizedBox(height: 16),
              _buildTextField(
                  controller: _quantityController,
                  label: 'Quantity',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  errorMessage: _quantityError),
              SizedBox(height: 16),
              _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  icon: Icons.description,
                  maxLines: 4,
                  errorMessage: _descriptionError),
              SizedBox(height: 16),
              _buildTextField(
                  controller: _priceController,
                  label: 'Rental Price in ₹ (per day)',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  errorMessage: _priceError),
              SizedBox(height: 16),
              _buildTextField(
                  controller: _locationController,
                  label: 'Full Location',
                  icon: Icons.location_on,
                  errorMessage: _locationError),
              SizedBox(height: 16),
              _buildTextField(
                  controller: _contactController,
                  label: 'Contact Information',
                  icon: Icons.phone,
                  errorMessage: _contactError),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Availability:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value;
                      });
                    },
                    activeColor: Colors.teal,
                  ),
                ],
              ),
              SizedBox(height: 20),
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
                      : Center(child: Text("Tap to select an image")),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUploading ? null : _submitForm,
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Submit Tool'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
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
    String? errorMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (_) => _startDebounce(),
        ),
        if (errorMessage != null && errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
