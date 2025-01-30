import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
  bool _isUploading = false;
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

  @override
  void dispose() {
    _toolNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
      final storageRef = FirebaseStorage.instance.ref().child(
          'tool_images/${widget.toolId}_${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  Future<void> _updateTool() async {
    setState(() {
      _isUploading = true;
    });

    String? imageUrl = widget.imageUrl; // Default to existing image URL
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!); // Upload new image
    }

    final updatedData = {
      'toolName': _toolNameController.text,
      'quantity': int.tryParse(_quantityController.text) ?? 0,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'location': _locationController.text,
      'contact': _contactController.text,
      'description': _descriptionController.text,
      'imageUrl': imageUrl, // Update image URL
    };

    try {
      await FirebaseFirestore.instance
          .collection('tools')
          .doc(widget.toolId)
          .update(updatedData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tool updated successfully!')),
      );
      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      print('Error updating tool: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update tool.')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Tool'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
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
            SizedBox(height: 16),
            TextField(
              controller: _toolNameController,
              decoration: InputDecoration(labelText: 'Tool Name'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Quantity'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Price (₹)'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'Location'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contactController,
              decoration: InputDecoration(labelText: 'Contact Information'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isUploading ? null : _updateTool,
              child: _isUploading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
