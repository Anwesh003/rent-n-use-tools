import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookingPage extends StatefulWidget {
  final String toolId;
  final String toolName;
  final double price;
  final int totalQuantity;

  BookingPage({
    required this.toolId,
    required this.toolName,
    required this.price,
    required this.totalQuantity,
  });

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? _startDate;
  DateTime? _endDate;
  int _quantityToBook = 1;
  bool _isOwner = false; // Track if the current user is the tool owner

  @override
  void initState() {
    super.initState();
    _checkIfUserIsOwner();
  }

  Future<void> _checkIfUserIsOwner() async {
    final toolDoc =
        await _firestore.collection('tools').doc(widget.toolId).get();
    final toolData = toolDoc.data();
    if (toolData == null) {
      print('Tool document not found for ID: ${widget.toolId}');
      return;
    }
    final toolOwnerId = toolData['userId'] as String?;
    // Fetch the current user's ID from Firebase Authentication
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;
    setState(() {
      _isOwner = toolOwnerId == currentUserId;
    });
  }

  Future<int> getAvailableQuantity(
      String toolId, DateTime startDate, DateTime endDate) async {
    final toolDoc = await _firestore.collection('tools').doc(toolId).get();
    final toolData = toolDoc.data();
    if (toolData == null) {
      throw Exception('Tool document not found for ID: $toolId');
    }
    final totalQuantity = toolData['quantity'] as int? ?? 0;
    final bookings =
        List<Map<String, dynamic>>.from(toolData['bookings'] ?? []);
    int bookedQuantity = 0;
    for (final booking in bookings) {
      final bookingStartDate = DateTime.parse(booking['startDate']);
      final bookingEndDate = DateTime.parse(booking['endDate']);
      // Check for overlapping bookings
      if (startDate.isBefore(bookingEndDate.add(Duration(days: 1))) &&
          endDate.isAfter(bookingStartDate.subtract(Duration(days: 1)))) {
        bookedQuantity += (booking['quantityBooked'] ?? 0) as int;
      }
    }
    return totalQuantity - bookedQuantity;
  }

  Future<void> _bookTool() async {
    if (_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot book your own tool.')),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select start and end dates.')),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('End date must be after or equal to start date.')),
      );
      return;
    }
    if (_quantityToBook <= 0 || _quantityToBook > widget.totalQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid quantity selected.')),
      );
      return;
    }
    try {
      final availableQuantity =
          await getAvailableQuantity(widget.toolId, _startDate!, _endDate!);
      if (availableQuantity < _quantityToBook) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Not enough quantity available for the selected dates.')),
        );
        return;
      }
      final toolRef = _firestore.collection('tools').doc(widget.toolId);
      final bookingData = {
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'quantityBooked': _quantityToBook,
        'isAccepted': false, // Add the isAccepted field, default to false
      };
      await _firestore.runTransaction((transaction) async {
        final toolDoc = await transaction.get(toolRef);
        final toolData = toolDoc.data();
        if (toolData == null) {
          throw Exception('Tool document not found for ID: ${widget.toolId}');
        }
        final totalQuantity = toolData['quantity'] as int? ?? 0;
        final bookings =
            List<Map<String, dynamic>>.from(toolData['bookings'] ?? []);
        int bookedQuantity = 0;
        for (final booking in bookings) {
          final bookingStartDate = DateTime.parse(booking['startDate']);
          final bookingEndDate = DateTime.parse(booking['endDate']);
          // Check for overlapping bookings
          if (_startDate!.isBefore(bookingEndDate.add(Duration(days: 1))) &&
              _endDate!.isAfter(bookingStartDate.subtract(Duration(days: 1)))) {
            bookedQuantity += (booking['quantityBooked'] ?? 0) as int;
          }
        }
        if ((totalQuantity - bookedQuantity) < _quantityToBook) {
          throw Exception("The tool is not available for the requested dates.");
        }
        transaction.update(toolRef, {
          'bookings': FieldValue.arrayUnion([bookingData]),
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking request sent! Awaiting approval.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${widget.toolName}'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isOwner)
              Center(
                child: Text(
                  'You cannot book your own tool.',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),
            SizedBox(height: 16),
            Text(
              'Select Start Date:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 7)),
                );
                if (selectedDate != null) {
                  setState(() {
                    _startDate = selectedDate;
                    // Reset end date if it's before the new start date
                    if (_endDate != null && _endDate!.isBefore(selectedDate)) {
                      _endDate = null;
                    }
                  });
                }
              },
              child: Text(_startDate == null
                  ? 'Select Start Date'
                  : 'Start Date: ${_startDate!.toString().split(' ')[0]}'),
            ),
            SizedBox(height: 16),
            Text(
              'Select End Date:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: _startDate == null
                  ? null // Disable end date selection until start date is selected
                  : () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: _startDate!,
                        firstDate: _startDate!,
                        lastDate: DateTime.now().add(Duration(days: 100)),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          _endDate = selectedDate;
                        });
                      }
                    },
              child: Text(_endDate == null
                  ? 'Select End Date'
                  : 'End Date: ${_endDate!.toString().split(' ')[0]}'),
            ),
            SizedBox(height: 16),
            Text(
              'Select Quantity to Book:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<int>(
              value: _quantityToBook,
              onChanged: (value) {
                setState(() {
                  _quantityToBook = value!;
                });
              },
              items: List.generate(widget.totalQuantity, (index) => index + 1)
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value'),
                      ))
                  .toList(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isOwner
                  ? null
                  : _bookTool, // Disable button if user is the owner
              child: Text('Confirm Booking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
