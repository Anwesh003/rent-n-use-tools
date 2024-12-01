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

  // Submit form with all data
  Future<void> _submitForm() async {
    if (_toolNameController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _contactController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please fill in all fields")));
      return;
    }

    // Collect all form data
    final toolName = _toolNameController.text;
    final quantity = _quantityController.text;
    final description = _descriptionController.text;
    final price = _priceController.text;
    final location = _locationController.text;
    final contact = _contactController.text;

    // Now you can save this data to Firebase or any database
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tool successfully put to rent!")));

    // Clear the form
    _toolNameController.clear();
    _quantityController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _locationController.clear();
    _contactController.clear();
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
                  icon: Icons.build),
              SizedBox(height: 16),
              _buildTextField(
                  controller: _quantityController,
                  label: 'Quantity',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number),
              SizedBox(height: 16),
              _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  icon: Icons.description,
                  maxLines: 4),
              SizedBox(height: 16),
              _buildTextField(
                  controller: _priceController,
                  label: 'Rental Price (per day)',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number),
              SizedBox(height: 16),
              _buildTextField(
                  controller: _locationController,
                  label: 'Location (Place Name)',
                  icon: Icons.location_on),
              SizedBox(height: 16),
              _buildTextField(
                  controller: _contactController,
                  label: 'Contact Information',
                  icon: Icons.phone),
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

  // A reusable widget for text input fields
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
