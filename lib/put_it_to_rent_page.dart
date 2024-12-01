import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  Timer? _debounce;

  // Debounced validation logic
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
              double.parse(_priceController.text) <= 0
          ? "Price must be a valid number and greater than zero."
          : null;
      _locationError =
          _locationController.text.isEmpty ? "Location is required." : null;
      _contactError = _contactController.text.isEmpty ||
              !_isValidPhoneNumber(_contactController.text)
          ? "Please provide a valid contact number."
          : null;
    });
  }

  // Start debounce timer
  void _startDebounce() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(Duration(seconds: 1), _validateField);
  }

  // Submit form with all data
  Future<void> _submitForm() async {
    // Validation checks
    if (_toolNameError != null ||
        _quantityError != null ||
        _descriptionError != null ||
        _priceError != null ||
        _locationError != null ||
        _contactError != null) {
      return;
    }

    // Get current user ID (UID)
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _toolNameError = "You need to be logged in to submit a tool.";
      });
      return;
    }

    // Collect all form data
    final toolName = _toolNameController.text;
    final quantity = _quantityController.text;
    final description = _descriptionController.text;
    final price = _priceController.text;
    final location = _locationController.text;
    final contact = _contactController.text;
    final userId = user.uid;

    // Save tool data to Firestore
    try {
      await FirebaseFirestore.instance.collection('tools').add({
        'toolName': toolName,
        'quantity': quantity,
        'description': description,
        'price': price,
        'location': location,
        'contact': contact,
        'userId': userId, // Associate tool with the logged-in user's UID
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tool successfully put to rent!")));

      // Clear the form
      _clearForm();
    } catch (e) {
      setState(() {
        _toolNameError = "Error adding tool. Please try again.";
      });
    }
  }

  // Helper function to clear form
  void _clearForm() {
    _toolNameController.clear();
    _quantityController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _locationController.clear();
    _contactController.clear();

    setState(() {
      _toolNameError = null;
      _quantityError = null;
      _descriptionError = null;
      _priceError = null;
      _locationError = null;
      _contactError = null;
    });
  }

  // Helper function to validate phone number format
  bool _isValidPhoneNumber(String phone) {
    final phoneRegExp = RegExp(r'^[0-9]{10}$');
    return phoneRegExp.hasMatch(phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Put It to Rent'),
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
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
                  label: 'Rental Price in Rupees(per day)',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  errorMessage: _priceError),
              SizedBox(height: 16),
              _buildTextField(
                  controller: _locationController,
                  label: 'Location (Place Name)',
                  icon: Icons.location_on,
                  errorMessage: _locationError),
              SizedBox(height: 16),
              _buildTextField(
                  controller: _contactController,
                  label: 'Contact Information',
                  icon: Icons.phone,
                  errorMessage: _contactError),
              SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Submit Tool'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // A reusable widget for text input fields with error messages
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
          onChanged: (_) => _startDebounce(), // Start debounce on field change
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
