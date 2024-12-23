import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:intl/intl.dart';

import 'credit_salesorder_pre_invoice.dart';

class CreditCustomerPage extends StatefulWidget {
  @override
  _CreditCustomerPageState createState() => _CreditCustomerPageState();
}

class _CreditCustomerPageState extends State<CreditCustomerPage> {
  List<Map<String, dynamic>> creditBills = [];
  List<Map<String, dynamic>> filteredBills = [];
  bool showPreInvoice = true; // Track which page to display
  Map<String, dynamic>? selectedBill; // Track the selected bill
  String searchQuery = ''; // Search query
  DateTime? startDate;
  DateTime? endDate;
  String selectedOption = 'Overall Credit Orders'; // Default selected option
  List<Map<String, dynamic>> selectedBills = [];
  Map<String, double> totalsByDate = {};
  Map<String, double> totalsByCustomer = {};
  Future<void> fetchCreditBills(
      {String? customerNumber, DateTime? startDate, DateTime? endDate}) async {
    var apiUrl =
        'http://192.168.1.119:8888/fastapi/salesorders/?filter-credit-customer=true';

    // Append customer number if it is not null
    if (customerNumber != null && customerNumber.isNotEmpty) {
      apiUrl += '&customerNumber=$customerNumber';
    }

    // Create a DateFormatter
    DateFormat dateFormat = DateFormat('dd-MM-yyyy');

    // Append start date in 'DD-MM-YYYY' format if it is not null
    if (startDate != null) {
      String formattedStartDate = dateFormat.format(startDate);
      apiUrl += '&deliveryStartDate=$formattedStartDate';
    }

    // Append end date in 'DD-MM-YYYY' format if it is not null
    if (endDate != null) {
      String formattedEndDate = dateFormat.format(endDate);
      apiUrl += '&deliveryEndDate=$formattedEndDate';
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          creditBills = List<Map<String, dynamic>>.from(data);
          filteredBills = creditBills;
        });
      } else {
        print('Failed to fetch credit bills: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching credit bills: $error');
    }
  }

  void applyFilters() {
    setState(() {
      filteredBills = creditBills.where((bill) {
        final matchesSearch = bill['customerName']
                ?.toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ??
            false;

        final matchesDate = () {
          if (startDate != null && endDate != null) {
            DateTime? deliveryDate = bill['deliveryDate'] != null
                ? DateTime.tryParse(bill['deliveryDate'])
                : null;
            if (deliveryDate != null) {
              return deliveryDate.isAfter(startDate!) &&
                  deliveryDate.isBefore(endDate!);
            }
            return false;
          }
          return true;
        }();

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  Future<void> selectStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
      });
      fetchCreditBills(
          customerNumber: searchQuery,
          startDate: startDate,
          endDate: endDate); // Update API call
    }
  }

  Future<void> selectEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
      });
      fetchCreditBills(
          customerNumber: searchQuery,
          startDate: startDate,
          endDate: endDate); // Update API call
    }
  }

  @override
  void initState() {
    fetchCreditBills();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove default back button
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAppBarButton(
                  title: 'Overall Credit Orders',
                  isSelected: selectedOption == 'Overall Credit Orders',
                  onPressed: () {
                    setState(() {
                      selectedOption = 'Overall Credit Orders';
                    });
                  },
                ),
                _buildAppBarButton(
                  title: 'Credit Sales Orders',
                  isSelected: selectedOption == 'Credit Sales Orders',
                  onPressed: () {
                    setState(() {
                      selectedOption = 'Credit Sales Orders';
                    });
                  },
                ),
                _buildAppBarButton(
                  title: 'Credit Invoice',
                  isSelected: selectedOption == 'Credit Invoice',
                  onPressed: () {
                    setState(() {
                      selectedOption = 'Credit Invoice';
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        toolbarHeight: 100, // Set height to accommodate the buttons
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top row for toggling between "Pre-Invoice" and "Invoice"
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      showPreInvoice = true; // Show Credit Bill Pre-Invoice
                      selectedBill = null; // Reset selected bill
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: showPreInvoice
                        ? Colors.blueAccent
                            .withOpacity(0.2) // Highlighted color
                        : Colors.grey[200], // Default color
                    foregroundColor: showPreInvoice
                        ? Colors.blue // Highlighted text color
                        : Colors.black, // Default text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Credit Bill Pre-Invoice'),
                ),
              ),
              SizedBox(
                width: 40,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    showPreInvoice = false; // Show Credit Invoice
                    selectedBill = null; // Reset selected bill
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: !showPreInvoice
                      ? Colors.blueAccent.withOpacity(0.2) // Highlighted color
                      : Colors.grey[200], // Default color
                  foregroundColor: !showPreInvoice
                      ? Colors.blue // Highlighted text color
                      : Colors.black, // Default text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Credit Invoice'),
              ),
            ],
          ),
          SizedBox(height: 10),
          // Search bar and date filters
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Search bar
                Row(
                  children: [
                    Container(
                      width: 350,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          fetchCreditBills(
                              customerNumber: value
                                  .trim()); // Fetch bills based on the input
                        },
                        decoration: InputDecoration(
                          labelText: 'Search by Customer Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // Date range filters
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: selectStartDate,
                      child: Text(
                          'Start Date: ${startDate != null ? DateFormat('dd-MM-yyyy').format(startDate!.toLocal()) : 'Select'}'),
                    ),
                    SizedBox(
                      width: 2,
                    ),
                    ElevatedButton(
                      onPressed: selectEndDate,
                      child: Text(
                          'End Date: ${endDate != null ? DateFormat('dd-MM-yyyy').format(endDate!.toLocal()) : 'Select'}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          // Main content
          Expanded(
            child: Row(
              children: [
                // Left panel: List of credit bills
                Expanded(
                  flex: 1,
                  child: showPreInvoice
                      ? _buildCreditBillListView() // Show list view
                      : Center(
                          child: Text(
                            'Credit Invoice Page', // Placeholder for Credit Invoice
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                ),
                VerticalDivider(width: 1, color: Colors.grey),
                // Right panel: Details of selected credit bill
                Expanded(
                  flex: 2,
                  child: selectedBills.isNotEmpty
                      ? _buildTotalsDisplay() // Show totals if multiple bills are selected
                      : (selectedBill != null
                          ? _buildCreditBillDetailView() // Show details if a single bill is selected
                          : Center(
                              child: Text(
                                'Select a bill to view details', // Placeholder text
                                style:
                                    TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// List View: Displays all filtered credit bills
  Widget _buildCreditBillListView() {
    if (filteredBills.isEmpty) {
      return Center(child: Text('No Credit Bills Found'));
    }

    return ListView.builder(
      itemCount: filteredBills.length,
      itemBuilder: (context, index) {
        final bill = filteredBills[index];
        return Card(
          color: selectedBills.contains(bill) ? Colors.blue[100] : Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
                backgroundColor: Colors.blue[50], child: Text("SO")),
            title: Text(bill['customerName'] ?? 'Unknown Customer'),
            subtitle: Text('Date: ${bill['deliveryDate'] ?? 'N/A'}'),
            trailing: Text(
              '${bill['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              setState(() {
                selectedBill =
                    bill; // Set this bill as the selectedBill to view details
              });
            },
            onLongPress: () {
              setState(() {
                if (selectedBills.contains(bill)) {
                  selectedBills.remove(bill);
                } else {
                  selectedBills.add(bill);
                }
                calculateAndLogTotals(); // Recalculate and log the totals
              });
            },
            selected: selectedBills.contains(bill),
            selectedTileColor: Colors.blue[200],
          ),
        );
      },
    );
  }

  Widget _buildCreditBillDetailView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            GridView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 items per row

                childAspectRatio: 5, // Adjust height-to-width ratio
              ),
              children: [
                _buildDetailTile('Customer Name',
                    selectedBill!['customerName'] ?? 'Unknown'),
                _buildDetailTile(
                    'Delivery Date', selectedBill!['deliveryDate'] ?? 'N/A'),
                _buildDetailTile(
                    'Delivery Time', selectedBill!['deliveryTime'] ?? 'N/A'),
                _buildDetailTile('Total Amount',
                    '₹${selectedBill!['totalAmount']?.toStringAsFixed(2) ?? '0.00'}'),
                _buildDetailTile('Discount',
                    '₹${selectedBill!['discountAmount']?.toStringAsFixed(2) ?? '0.00'}'),
                _buildDetailTile('Custom Charge',
                    '₹${selectedBill!['customCharge'] ?? '0.00'}'),
                _buildDetailTile(
                    'Payment Type', selectedBill!['paymentType'] ?? 'Unknown'),
                _buildDetailTile('Delivery Type',
                    selectedBill!['deliveryType'] ?? 'Unknown'),
                _buildDetailTile('Employee Name',
                    selectedBill!['employeeName'] ?? 'Not Assigned'),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Items:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ..._buildItemList(selectedBill!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                handleInvoicePrinting();

                print('Make Pre Invoice');
              },
              child: Text('Make Pre Invoice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildAppBarButton({
    required String title,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isSelected
            ? Colors.blueAccent.withOpacity(0.2) // Highlighted background
            : Colors.transparent, // Default background
        foregroundColor: isSelected ? Colors.blue : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(title, style: TextStyle(fontSize: 14)),
    );
  }

  /// Helper function to build item list
  List<Widget> _buildItemList(Map<String, dynamic> bill) {
    List<Widget> items = [];

    // Ensure all required keys exist and have valid data
    if (bill['itemName'] != null &&
        bill['qty'] != null &&
        bill['price'] != null &&
        bill['weight'] != null &&
        bill['amount'] != null &&
        bill['tax'] != null &&
        bill['uom'] != null) {
      for (int i = 0; i < bill['itemName'].length; i++) {
        items.add(
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${bill['itemName'][i]}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Qty: ${bill['qty'][i]} ${bill['uom'][i]}'),
                      Text('Price: ₹${bill['price'][i]}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Weight: ${bill['weight'][i]} kg'),
                      Text('Amount: ₹${bill['amount'][i]?.toStringAsFixed(2)}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tax: ${bill['tax'][i]}%'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      items.add(
          Text('No items available', style: TextStyle(color: Colors.grey)));
    }

    return items;
  }

  void calculateAndLogTotals() {
    double overallTotal = 0.0;
    Map<String, double> newTotalsByDate = {};
    Map<String, double> newTotalsByCustomer = {};

    for (var bill in selectedBills) {
      double amount =
          double.tryParse(bill['totalAmount']?.toString() ?? '0') ?? 0.0;
      overallTotal += amount;

      String date = bill['deliveryDate'] ?? 'Unknown Date';
      newTotalsByDate.update(date, (existingTotal) => existingTotal + amount,
          ifAbsent: () => amount);

      String customerNumber = bill['customerNumber'] ?? 'Unknown Customer';
      newTotalsByCustomer.update(
          customerNumber, (existingTotal) => existingTotal + amount,
          ifAbsent: () => amount);
    }

    // Update state with new totals
    setState(() {
      totalsByDate = newTotalsByDate;
      totalsByCustomer = newTotalsByCustomer;
      print(
          "Overall Total Amount for selected bills: ${overallTotal.toStringAsFixed(2)}");
    });
  }

  Widget _buildTotalsDisplay() {
    double overallTotal = 0; // Variable to hold the overall total

    // Create a list of rows for the table
    List<TableRow> tableRows = [];

    // Add a header row
    tableRows.add(
      TableRow(
        children: [
          _buildTableHeader('Date'),
          _buildTableHeader('Customer Number'),
          _buildTableHeader('Amount'),
        ],
      ),
    );

    // Generate rows only for selected bills
    for (var bill in selectedBills) {
      String customerNumber = bill['customerNumber'] ?? 'Unknown';
      String deliveryDate = bill['deliveryDate'] ?? 'N/A';
      String totalAmount = bill['totalAmount'] != null
          ? '${double.parse(bill['totalAmount'].toString()).toStringAsFixed(0)}'
          : '₹0.00';

      tableRows.add(
        TableRow(
          children: [
            _buildTableCell(deliveryDate),
            _buildTableCell(customerNumber),
            _buildTableCell(totalAmount),
          ],
        ),
      );

      overallTotal += double.tryParse(
              (double.tryParse(bill['totalAmount']?.toString() ?? '0') ?? 0)
                  .toStringAsFixed(0)) ??
          0;
    }

    return Column(
      children: [
        // Display the table only if there are selected bills
        if (selectedBills.isNotEmpty)
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(color: Colors.grey),
                columnWidths: const {
                  0: FlexColumnWidth(2), // Customer Name column
                  1: FlexColumnWidth(2), // Date column
                  2: FlexColumnWidth(1), // Amount column
                },
                children: tableRows,
              ),
            ),
          )
        else
          Center(
            child: Text(
              'No bills selected.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        // Add the overall total at the bottom
        if (selectedBills.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text('Overall Total: ₹${overallTotal.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
          ),
        // Add the "Make Invoice" button at the bottom
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
          child: TextButton(
            onPressed: () {
              // Call the method to handle invoice printing
              handleInvoicePrinting();
            },
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              foregroundColor: Colors.blueAccent,
            ),
            child: Text(
              selectedBills.isNotEmpty
                  ? 'Make Pre Invoice for Selected Bills'
                  : 'No Bills Selected',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        value,
        textAlign: TextAlign.center,
      ),
    );
  }

  // void handleInvoicePrinting() {
  //   if (selectedBills.isNotEmpty) {
  //     for (var bill in selectedBills) {
  //       CreditSOPreInvoicePrinter.printReceipt(
  //         ipAddress: "192.168.1.88", // Printer IP
  //         invoiceData: bill,
  //         receiptType: "Pre-Invoice",
  //       );
  //     }
  //   } else {
  //     print("No bills selected for invoice generation.");
  //   }
  // }
  void handleInvoicePrinting() async {
    if (selectedBills.isNotEmpty) {
      print("Processing and Consolidating Invoice for Selected Bills:");

      Map<String, dynamic> consolidatedInvoiceData = {
        "itemName": [],
        "varianceName": [],
        "price": [],
        "weight": [],
        "qty": [],
        "amount": [],
        "tax": [],
        "uom": [],
        "totalAmount": 0.0,
        "status": "active",
        "salesType": null,
        "customerPhoneNumber": "No Number",
        "employeeName": "",
        "branchId": "",
        "branchName": "Unknown Branch",
        "paymentType": "Unknown Payment",
        "cash": 0.0,
        "card": 0.0,
        "upi": 0.0,
        "others": 0.0,
        "invoiceDate": "Unknown Date",
        "invoiceTime": "Unknown Time",
        "shiftNumber": null,
        "shiftId": null,
        "invoiceNo": null,
        "deviceNumber": null,
        "customCharge": 0.0,
        "discountAmount": 0.0,
        "discountPercentage": null,
        "user": null,
        "deviceCode": "UnknownDevice",
        "kotaddOns": [],
      };

      // Collect all selected salesOrder IDs
      List<String> salesOrderIds = selectedBills
          .map((bill) => bill['salesOrderId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (salesOrderIds.isEmpty) {
        print("No valid salesOrder IDs found in selected bills.");
        return;
      }

      for (var bill in selectedBills) {
        consolidatedInvoiceData["itemName"].addAll(bill['itemName'] ?? []);
        consolidatedInvoiceData["varianceName"]
            .addAll(bill['varianceName'] ?? []);
        consolidatedInvoiceData["price"].addAll(bill['price'] ?? []);
        consolidatedInvoiceData["weight"].addAll(bill['weight'] ?? []);
        consolidatedInvoiceData["qty"].addAll(bill['qty'] ?? []);
        consolidatedInvoiceData["amount"].addAll(bill['amount'] ?? []);
        consolidatedInvoiceData["tax"].addAll(bill['tax'] ?? []);
        consolidatedInvoiceData["uom"].addAll(bill['uom'] ?? []);
        consolidatedInvoiceData["totalAmount"] += bill['totalAmount'] ?? 0.0;

        consolidatedInvoiceData["employeeName"] = bill['employeeName'];
        consolidatedInvoiceData["branchId"] = bill['branchId'];
        consolidatedInvoiceData["branchName"] =
            bill['branchName'] ?? consolidatedInvoiceData["branchName"];
        consolidatedInvoiceData["paymentType"] =
            bill['paymentType'] ?? consolidatedInvoiceData["paymentType"];
        consolidatedInvoiceData["cash"] += bill['cash'] ?? 0.0;
        consolidatedInvoiceData["card"] += bill['card'] ?? 0.0;
        consolidatedInvoiceData["upi"] += bill['upi'] ?? 0.0;
        consolidatedInvoiceData["others"] += bill['others'] ?? 0.0;
        consolidatedInvoiceData["customCharge"] += bill['customCharge'] ?? 0.0;
        consolidatedInvoiceData["discountAmount"] +=
            bill['discountAmount'] ?? 0.0;
        consolidatedInvoiceData["kotaddOns"].addAll(bill['kotaddOns'] ?? []);
      }

      try {
        // Make the PATCH request to update multiple sales orders
        final patchResponse = await http.patch(
          Uri.parse(
              'http://192.168.1.119:8888/fastapi/salesorders/crsopreinvoice/'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(salesOrderIds), // Send raw list of IDs
        );

        if (patchResponse.statusCode == 200) {
          print("Sales orders updated successfully!");

          // Call the print function after successful patch
          await CreditSOPreInvoicePrinter.printReceipt(
            ipAddress: "192.168.1.88", // Replace with the actual printer IP
            invoiceData: consolidatedInvoiceData,
            receiptType: "Consolidated Pre-Invoice",
          );
        } else {
          print(
              "Failed to update sales orders: ${patchResponse.statusCode} - ${patchResponse.body}");
        }
      } catch (error) {
        print("Error updating sales orders: $error");
      }
    } else {
      print("No bills selected for invoice generation.");
    }
  }
}
