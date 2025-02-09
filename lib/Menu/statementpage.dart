import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class StatementPage extends StatefulWidget {
  @override
  _StatementPageState createState() => _StatementPageState();
}

class _StatementPageState extends State<StatementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedStatementType = 0; // 0: Your Tools, 1: Tools You Have Rented

  Future<void> _selectStartDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      setState(() {
        _endDate = pickedDate;
      });
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>>
      _fetchYourToolsStatement() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a valid date range.')),
      );
      return {};
    }

    final toolsSnapshot = await _firestore
        .collection('tools')
        .where('userId', isEqualTo: _currentUser!.uid)
        .get();

    final Map<String, List<Map<String, dynamic>>> renterStatements = {};

    for (final toolDoc in toolsSnapshot.docs) {
      final toolData = toolDoc.data();
      final bookings =
          List<Map<String, dynamic>>.from(toolData['bookings'] ?? []);

      for (final booking in bookings) {
        final bookingStartDate = DateTime.tryParse(booking['startDate']);
        final bookingEndDate = DateTime.tryParse(booking['endDate']);

        if (bookingStartDate != null &&
            bookingEndDate != null &&
            bookingStartDate.isBefore(_endDate!) &&
            bookingEndDate.isAfter(_startDate!) &&
            booking['isAccepted'] == true) {
          final renterSnapshot =
              await _firestore.collection('users').doc(booking['userId']).get();
          final renterData = renterSnapshot.data();

          final daysRented =
              bookingEndDate.difference(bookingStartDate).inDays + 1;
          final totalPrice =
              daysRented * booking['quantityBooked'] * (toolData['price'] ?? 0);

          final statement = {
            'toolName': toolData['toolName'],
            'startDate': booking['startDate'],
            'endDate': booking['endDate'],
            'pricePerDay': toolData['price'],
            'quantityBooked': booking['quantityBooked'],
            'isGiven': booking['isGiven'] ?? false,
            'isReturned': booking['isReturned'] ?? false,
            'totalPrice': totalPrice,
          };

          final renterName = renterData?['name'] ?? 'Unknown Renter';
          if (renterStatements.containsKey(renterName)) {
            renterStatements[renterName]!.add(statement);
          } else {
            renterStatements[renterName] = [statement];
          }
        }
      }
    }

    return renterStatements;
  }

  Future<Map<String, List<Map<String, dynamic>>>>
      _fetchToolsYouHaveRentedStatement() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a valid date range.')),
      );
      return {};
    }

    final toolsSnapshot = await _firestore.collection('tools').get();
    final Map<String, List<Map<String, dynamic>>> providerStatements = {};

    for (final toolDoc in toolsSnapshot.docs) {
      final toolData = toolDoc.data();
      final bookings =
          List<Map<String, dynamic>>.from(toolData['bookings'] ?? []);

      for (final booking in bookings) {
        if (booking['userId'] == _currentUser!.uid) {
          final bookingStartDate = DateTime.tryParse(booking['startDate']);
          final bookingEndDate = DateTime.tryParse(booking['endDate']);

          if (bookingStartDate != null &&
              bookingEndDate != null &&
              bookingStartDate.isBefore(_endDate!) &&
              bookingEndDate.isAfter(_startDate!) &&
              booking['isAccepted'] == true) {
            final ownerSnapshot = await _firestore
                .collection('users')
                .doc(toolData['userId'])
                .get();
            final ownerData = ownerSnapshot.data();

            final daysRented =
                bookingEndDate.difference(bookingStartDate).inDays + 1;
            final totalPrice = daysRented *
                booking['quantityBooked'] *
                (toolData['price'] ?? 0);

            final statement = {
              'toolName': toolData['toolName'],
              'startDate': booking['startDate'],
              'endDate': booking['endDate'],
              'pricePerDay': toolData['price'],
              'quantityBooked': booking['quantityBooked'],
              'isGiven': booking['isGiven'] ?? false,
              'isReturned': booking['isReturned'] ?? false,
              'totalPrice': totalPrice,
            };

            final ownerName = ownerData?['name'] ?? 'Unknown Owner';
            if (providerStatements.containsKey(ownerName)) {
              providerStatements[ownerName]!.add(statement);
            } else {
              providerStatements[ownerName] = [statement];
            }
          }
        }
      }
    }

    return providerStatements;
  }

  Future<void> _generatePdf(
      String title,
      String name,
      String address,
      String phone,
      List<Map<String, dynamic>> statements,
      double totalPrice) async {
    final pdf = pw.Document();
    final headers = [
      'Tool Name',
      'From Date',
      'To Date',
      'Price/Day',
      'Quantity',
      'Status',
      'Total Price'
    ];

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Text(title,
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Name: $name', style: pw.TextStyle(fontSize: 16)),
            pw.Text('Address: $address', style: pw.TextStyle(fontSize: 14)),
            pw.Text('Phone: $phone', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: headers,
              data: statements.map((statement) {
                final status = statement['isReturned']
                    ? 'Returned'
                    : statement['isGiven']
                        ? 'Taken'
                        : 'Not Taken';
                return [
                  statement['toolName'],
                  DateFormat('d MMM yyyy')
                      .format(DateTime.parse(statement['startDate'])),
                  DateFormat('d MMM yyyy')
                      .format(DateTime.parse(statement['endDate'])),
                  '₹${statement['pricePerDay']}',
                  '${statement['quantityBooked']}',
                  status,
                  '₹${statement['totalPrice']}',
                ];
              }).toList(),
              border: pw.TableBorder.all(width: 1, color: PdfColors.grey),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 10),
            pw.Text('Total Price: ₹$totalPrice',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

    final outputDir = await getApplicationDocumentsDirectory();
    final filePath = '${outputDir.path}/Statement.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Statement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Radio<int>(
                  value: 0,
                  groupValue: _selectedStatementType,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatementType = value!;
                    });
                  },
                ),
                Text('Your Tools Statement'),
                Radio<int>(
                  value: 1,
                  groupValue: _selectedStatementType,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatementType = value!;
                    });
                  },
                ),
                Text('Tools You Have Rented Statement'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await _selectStartDate(context);
                  },
                  icon: Icon(Icons.calendar_today),
                  label: Text('From Date'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _selectEndDate(context);
                  },
                  icon: Icon(Icons.calendar_today),
                  label: Text('To Date'),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_startDate != null && _endDate != null)
              Text(
                'Selected Date Range: ${DateFormat('d MMM yyyy').format(_startDate!)} - ${DateFormat('d MMM yyyy').format(_endDate!)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder(
                future: _selectedStatementType == 0
                    ? _fetchYourToolsStatement()
                    : _fetchToolsYouHaveRentedStatement(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                        child: Text(
                            'No data available for the selected date range.'));
                  }

                  final statements = snapshot.data!;
                  return ListView.builder(
                    itemCount: statements.length,
                    itemBuilder: (context, index) {
                      final key = statements.keys.elementAt(index);
                      final items = statements[key]!;
                      final total = items.fold<double>(
                          0, (sum, item) => sum + item['totalPrice']);
                      final userData = _selectedStatementType == 0
                          ? {
                              'name': key,
                              'address': 'Address',
                              'phone': 'Phone'
                            }
                          : {
                              'name': key,
                              'address': 'Provider Address',
                              'phone': 'Provider Phone'
                            };

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedStatementType == 0
                                    ? 'Renter Name: $key'
                                    : 'Provider Name: $key',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text('Address: ${userData['address']}',
                                  style: TextStyle(fontSize: 14)),
                              Text('Phone: ${userData['phone']}',
                                  style: TextStyle(fontSize: 14)),
                              SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: [
                                    DataColumn(label: Text('Tool Name')),
                                    DataColumn(label: Text('From Date')),
                                    DataColumn(label: Text('To Date')),
                                    DataColumn(label: Text('Price/Day')),
                                    DataColumn(label: Text('Quantity')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Total Price')),
                                  ],
                                  rows: items.map((item) {
                                    final status = item['isReturned']
                                        ? 'Returned'
                                        : item['isGiven']
                                            ? 'Taken'
                                            : 'Not Taken';
                                    return DataRow(cells: [
                                      DataCell(Text(item['toolName'])),
                                      DataCell(Text(DateFormat('d MMM yyyy')
                                          .format(DateTime.parse(
                                              item['startDate'])))),
                                      DataCell(Text(DateFormat('d MMM yyyy')
                                          .format(DateTime.parse(
                                              item['endDate'])))),
                                      DataCell(Text('₹${item['pricePerDay']}')),
                                      DataCell(
                                          Text('${item['quantityBooked']}')),
                                      DataCell(Text(status)),
                                      DataCell(Text('₹${item['totalPrice']}')),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Price: ₹$total',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await _generatePdf(
                                        _selectedStatementType == 0
                                            ? 'Your Tools Statement'
                                            : 'Tools You Have Rented Statement',
                                        userData['name']!,
                                        userData['address']!,
                                        userData['phone']!,
                                        items,
                                        total,
                                      );
                                    },
                                    icon: Icon(Icons.download),
                                    label: Text('Download PDF'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
  