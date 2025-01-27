import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final storageRef = FirebaseStorage.instance.ref().child(
          'tool_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = storageRef.putFile(image);

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Image upload error: $e");
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

    final toolData = {
      'toolName': _toolNameController.text,
      'quantity': _quantityController.text,
      'description': _descriptionController.text,
      'price': _priceController.text,
      'location': _locationController.text,
      'contact': _contactController.text,
      'userId': user.uid,
      'imageUrl': imageUrl, // Save the image URL
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
