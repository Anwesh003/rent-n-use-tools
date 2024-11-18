import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Text controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  bool isEditing = false;
  bool isProfileComplete = false;
  bool isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from Firebase Firestore
  void _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;

          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _houseController.text = data['house'] ?? '';
            _areaController.text = data['area'] ?? '';
            _landmarkController.text = data['landmark'] ?? '';
            _pincodeController.text = data['pincode'] ?? '';
            _cityController.text = data['city'] ?? '';
            _stateController.text = data['state'] ?? '';

            // Check if the profile is complete
            isProfileComplete = _nameController.text.isNotEmpty &&
                _phoneController.text.isNotEmpty &&
                _houseController.text.isNotEmpty &&
                _areaController.text.isNotEmpty &&
                _landmarkController.text.isNotEmpty &&
                _pincodeController.text.isNotEmpty &&
                _cityController.text.isNotEmpty &&
                _stateController.text.isNotEmpty;

            if (!isProfileComplete) {
              isEditing = true; // If profile is incomplete, enable edit mode
            }
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  // Save user data to Firebase Firestore
  Future<void> _saveUserData() async {
    setState(() {
      isLoading = true; // Start loading
    });

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'house': _houseController.text,
          'area': _areaController.text,
          'landmark': _landmarkController.text,
          'pincode': _pincodeController.text,
          'city': _cityController.text,
          'state': _stateController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully!')));

        // After saving data, check if the profile is complete and switch to non-edit mode
        setState(() {
          isEditing = false;
          isProfileComplete = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }

    setState(() {
      isLoading = false; // Stop loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true, // Title aligned to the center
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading spinner
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    // Profile Avatar
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(
                        _auth.currentUser?.photoURL ??
                            'https://www.example.com/default-profile-pic.png',
                      ),
                    ),
                    SizedBox(height: 16),

                    // If editing, show the form, else display the profile details
                    if (isEditing) ...[
                      _buildTextField(_nameController, 'Name'),
                      _buildTextField(_phoneController, 'Phone Number',
                          keyboardType: TextInputType.phone),
                      _buildTextField(_houseController, 'House'),
                      _buildTextField(_areaController, 'Area'),
                      _buildTextField(_landmarkController, 'Landmark'),
                      _buildTextField(_pincodeController, 'Pincode',
                          keyboardType: TextInputType.number),
                      _buildTextField(_cityController, 'City'),
                      _buildTextField(_stateController, 'State'),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveUserData,
                        child: Text('Save'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ] else ...[
                      // Display profile data if it's complete
                      if (isProfileComplete) ...[
                        _buildProfileInfo('Name', _nameController.text),
                        _buildProfileInfo('Phone', _phoneController.text),
                        _buildProfileInfo('House', _houseController.text),
                        _buildProfileInfo('Area', _areaController.text),
                        _buildProfileInfo('Landmark', _landmarkController.text),
                        _buildProfileInfo('Pincode', _pincodeController.text),
                        _buildProfileInfo('City', _cityController.text),
                        _buildProfileInfo('State', _stateController.text),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isEditing = true; // Enable edit mode
                            });
                          },
                          child: Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                      ] else ...[
                        // If profile is not complete, prompt the user to fill it out
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'Your profile is incomplete. Please fill in the details.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isEditing = true; // Enable edit mode
                            });
                          },
                          child: Text('Fill Profile'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // Helper widget for profile info display
  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for TextField inputs
  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
      ),
    );
  }
}
