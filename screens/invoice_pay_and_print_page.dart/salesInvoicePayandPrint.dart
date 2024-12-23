import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../Global/custom_sized_box.dart';
import '../../Global/custom_textWidgets.dart';
import '../kot_screen/global/globals.dart';
import '../regular_mode_page/provider/cart_page_provider.dart';
import '../regular_mode_page/widget/custom_reusable_widget/letter_keyborard.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import 'widgets/invoice_Print_Receipt.dart';
import 'services/invoice_service.dart';

class SalesInvoicePayAndPrint extends StatefulWidget {
  final double totalAmount;
  final String holdBillId; // Added holdBillId to identify the bill

  const SalesInvoicePayAndPrint({
    super.key,
    required this.totalAmount,
    required this.holdBillId, // Receive the holdBillId
  });

  @override
  State<SalesInvoicePayAndPrint> createState() =>
      _SalesInvoicePayAndPrintState();
}

class _SalesInvoicePayAndPrintState extends State<SalesInvoicePayAndPrint> {
  final InvoiceService _invoiceService = InvoiceService();
  final List<String> cashOptions = [];
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _employeeNumberController =
      TextEditingController();
  List<Map<String, dynamic>> _employeeSuggestions =
      []; // Store employee suggestions
  bool _showEmployeeSuggestions = false; // Show or hide suggestions dropdown
  final TextEditingController _customerNumberController =
      TextEditingController();
  String _selectedPaymentOption = '';
  String _selectedPaymentOptionVaule = '';
  final TextEditingController _discountController =
      TextEditingController(); // New controller for discount
  final TextEditingController _customChargeController =
      TextEditingController(); // New controller for discount
  double _balanceAmount = 0.0; // New variable for balance
  int _cashAmount = 0;
  int _cardAmount = 0;
  int _upiAmount = 0;
  String? _selectedEmployeeFirstName;

  bool _isPrintButtonEnabled = false; // New variable to track button state

  @override
  void initState() {
    super.initState();
    _channel = WebSocketChannel.connect(
      Uri.parse(
          'ws://$serverip:$port'), // Replace `port` with your WebSocket server's port
    );

    // Add a listener for WebSocket messages if needed
    _channel.stream.listen((data) {
      print('Received data: $data');
    }, onError: (error) {
      print('WebSocket error: $error');
    });
    cashOptions.addAll(_generateCashOptions(widget.totalAmount));
    _balanceAmount =
        widget.totalAmount; // Initially, balance equals the total amount
    _employeeNumberController.addListener(_validateForm);
    _customerNumberController.addListener(_validateForm);
    _customAmountController.addListener(_validateForm);
    _employeeNumberController.addListener(_onEmployeeInputChanged);
  }

  final Set<String> _loggedInvoices = {}; // Track unique invoices

  late WebSocketChannel _channel;
  Future<void> sendInvoiceDataToServer(Map<String, dynamic> invoiceData) async {
    try {
      final jsonData = jsonEncode(invoiceData);
      _channel.sink.add(jsonData);
      print('Invoice data sent to server: $jsonData');
    } catch (e) {
      print('Error sending invoice data to server: $e');
    }
  }

  // Method to validate if all fields are filled
  void _validateForm() {
    setState(() {
      bool isEmployeeNumberFilled = _employeeNumberController.text.isNotEmpty;
      bool isCustomerNumberFilled = _customerNumberController.text.isNotEmpty;
      bool isPaymentOptionSelected = _selectedPaymentOption.isNotEmpty;

      // Enable the print button only if all conditions are met
      _isPrintButtonEnabled = isEmployeeNumberFilled &&
          isCustomerNumberFilled &&
          isPaymentOptionSelected;
    });
  }

  // Listener for employee input changes
  Future<void> _onEmployeeInputChanged() async {
    String query = _employeeNumberController.text;
    if (query.isNotEmpty) {
      final suggestions = await _fetchEmployeeSuggestions(query);
      print('Filtered Suggestions: $suggestions'); // Debug suggestions
      setState(() {
        _employeeSuggestions = suggestions;
        _showEmployeeSuggestions = suggestions.isNotEmpty;
      });
    } else {
      setState(() {
        _showEmployeeSuggestions = false;
        _employeeSuggestions = [];
      });
    }
  }

  void _selectEmployee(Map<String, dynamic> employee) {
    _employeeNumberController.text =
        '${employee['employeeNumber']} - ${employee['firstName']}';

    // Save the first name in a separate String
    _selectedEmployeeFirstName = employee['firstName'];

    setState(() {
      _showEmployeeSuggestions = false; // Hide dropdown after selection
    });
  }

// Method to get employee suggestions from Hive based on the query
  Future<List<Map<String, dynamic>>> _fetchEmployeeSuggestions(
      String query) async {
    var box = await Hive.openBox('employeeBox');
    final List<Map<String, dynamic>> employees =
        List<Map<String, dynamic>>.from(box.get('employees', defaultValue: []));

    print(
        'All Employees in Hive: $employees'); // Debug the data fetched from Hive
    print('Search Query: $query'); // Debug the input query

    // Filter employee data based on the query
    return employees.where((employee) {
      final employeeNumber = employee['employeeNumber']?.toString() ?? '';
      final firstName = employee['firstName']?.toString().toLowerCase() ?? '';
      return employeeNumber.contains(query) ||
          firstName.contains(query.toLowerCase());
    }).toList();
  }

  /// Save the invoice data to Hive and console log it
  // Future<void> saveInvoiceToHiveAndPrint() async {
  //   final box = await Hive.openBox('invoiceBox');

  //   // Step 1: Generate a unique HiveInvoiceId
  //   String hiveInvoiceId = _invoiceService.generateShortHiveInvoiceId();

  //   // Step 2: Prepare the invoice data

  //   var cartProvider = Provider.of<CurrentSaleProvider>(context, listen: false);
  //   var cartItems = cartProvider.currentSaleItems ?? [];
  //   // Step 3: Extract item data into separate lists
  //   List<String> itemNames = [];
  //   List<String> varianceNames = [];
  //   List<double> prices = [];
  //   List<double> weights = [];
  //   List<double> quantities = [];
  //   List<double> amounts = [];
  //   List<double> taxes = [];
  //   List<String> uoms = [];

  //   for (var item in cartItems) {
  //     itemNames.add(item['itemData']['itemName'] ?? 'N/A');
  //     varianceNames.add(item['varianceData']['varianceName'] ?? 'N/A');
  //     prices.add(
  //         item['varianceData']['variance_Defaultprice']?.toDouble() ?? 0.0);
  //     weights.add((item['weight'] ?? 0.0).toDouble());
  //     quantities.add((item['quantity'] as num).toDouble() ?? 0.0);
  //     amounts.add(cartProvider.calculateItemTotal(item).toDouble());
  //     taxes.add((item['itemData']['tax'] as num).toDouble());
  //     uoms.add(item['varianceData']['variance_Uom'] ?? 'N/A');
  //   }

  //   // Step 4: Prepare the complete invoice data
  //   DateTime billDate = DateTime.now();
  //   String formattedDate = DateFormat('dd-MM-yy').format(billDate);
  //   String formattedTime = DateFormat('hh:mm a').format(billDate);

  //   Map<String, dynamic> invoiceData = {
  //     'HiveInvoiceId': hiveInvoiceId,
  //     'itemName': itemNames,
  //     'varianceName': varianceNames,
  //     'price': prices,
  //     'weight': weights,
  //     'qty': quantities,
  //     'amount': amounts,
  //     'tax': taxes,
  //     'uom': uoms,
  //     'employeeName': _employeeNumberController.text,
  //     'customerPhoneNumber': _customerNumberController.text,
  //     'discountPercentage': _discountController.text.isNotEmpty
  //         ? int.tryParse(_discountController.text) ?? 0
  //         : 0,
  //     'customCharge': _customChargeController.text.isNotEmpty
  //         ? int.tryParse(_customChargeController.text) ?? 0
  //         : 0,
  //     'totalAmount': widget.totalAmount.toStringAsFixed(0),
  //     'totalAmount2': widget.totalAmount.toStringAsFixed(0),
  //     'invoiceDate': formattedDate,
  //     'branchId': "099089",
  //     'salesType': "TakeAway",
  //     'branchName': "Aranmanai",
  //     'paymentType': _selectedPaymentOptionVaule,
  //     'cash': _cashAmount > 0
  //         ? _cashAmount
  //         : null, // Include cash only if cash is selected
  //     'card': _cardAmount > 0
  //         ? _cardAmount
  //         : null, // Include card only if card is selected
  //     'upi': _upiAmount > 0 ? _upiAmount : null,
  //     'others': null,
  //     'invoiceTime': formattedTime,
  //     'shiftNumber': "1",
  //     'shiftId': "1",
  //     'invoiceNo': "BM2402",
  //     'deviceNumber': "1",
  //     "sync": "no",
  //     "status": "active"
  //     // 'user': ["ASD"],`
  //   };

  //   // Print the full invoice data before saving to Hive

  //   // Step 5: Save the invoice data to Hive
  //   // Generate a unique identifier based on crucial invoice details
  //   var uniqueIdentifier =
  //       '$formattedDate-${widget.totalAmount}-${_customerNumberController.text}';
  //   var exists = false;

  //   for (var i = 0; i < box.length; i++) {
  //     var existingInvoice = box.getAt(i);
  //     if (existingInvoice['uniqueIdentifier'] == uniqueIdentifier) {
  //       exists = true;
  //       break;
  //     }
  //   }

  //   if (!exists) {
  //     invoiceData['uniqueIdentifier'] = uniqueIdentifier;

  //     await box.add(invoiceData);

  //     developer.log('Invoice saved to Hive:', name: 'InvoiceLog');
  //     developer.log('Invoice ID: ${box.keyAt(box.length - 1)}');

  //     // Print the invoice
  //     // Include your printing logic here
  //   }

  //   // box.clear();
  //   // Log the saved invoice data to the console
  //   developer.log('Invoice saved to Hive:', name: 'InvoiceLog');
  //   developer.log('HiveInvoiceId: $hiveInvoiceId');
  //   developer.log('Employee Number: ${invoiceData['employeeNumber']}');
  //   developer.log('Customer Number: ${invoiceData['customerNumber']}');
  //   developer.log('Discount: ${invoiceData['discount']}');
  //   developer.log('Custom Charge: ${invoiceData['customCharge']}');
  //   developer.log('Total Amount: ${invoiceData['totalAmount']}');

  //   // Step 7: Print the invoice (using your existing printing logic)
  //   // Your printing logic here

  //   // Step 8: Try to post the invoice to FastAPI
  //   // Step 5: Save the invoice data to Hive
  //   await _invoiceService.saveInvoiceToHive(invoiceData);

  //   // Step 8: Try to post the invoice to FastAPI
  //   try {
  //     developer.log('Calling postInvoiceToFastAPI...', name: 'InvoiceLog');
  //     var response = await _invoiceService.postInvoiceToFastAPI(invoiceData);

  //     // Log after receiving the response
  //     if (response.statusCode == 200) {
  //       developer.log('Invoice successfully posted to FastAPI',
  //           name: 'InvoiceLog');
  //     } else {
  //       developer.log(
  //           'Failed to post invoice: ${response.statusCode} - ${response.body}',
  //           name: 'InvoiceLog');
  //     }
  //   } catch (e) {
  //     developer.log('Error posting invoice: $e', name: 'InvoiceLog');
  //   }

  //   // Optionally, show a message in the UI
  //   // ScaffoldMessenger.of(context).showSnackBar(
  //   //   SnackBar(content: Text('Invoice $hiveInvoiceId saved successfully')),
  //   // );
  // }

  /// Save the invoice data and print to console
  /// nal InvoiceService _invoiceService = InvoiceService();
  // final Set<String> _loggedInvoices = {}; // Track unique invoices
  // Future<void> saveInvoiceToHiveAndPrint() async {
  //   // Step 1: Generate a unique HiveInvoiceId
  //   String hiveInvoiceId = _invoiceService.generateShortHiveInvoiceId();

  //   // Step 2: Prepare the invoice data
  //   var cartProvider = Provider.of<CurrentSaleProvider>(context, listen: false);
  //   var cartItems = cartProvider.currentSaleItems ?? [];

  //   // Step 3: Extract item data into separate lists
  //   List<String> itemNames = [];
  //   List<String> varianceNames = [];
  //   List<double> prices = [];
  //   List<double> weights = [];
  //   List<double> quantities = [];
  //   List<double> amounts = [];
  //   List<double> taxes = [];
  //   List<String> uoms = [];

  //   for (var item in cartItems) {
  //     itemNames.add(item['itemData']['itemName'] ?? 'N/A');
  //     varianceNames.add(item['varianceData']['varianceName'] ?? 'N/A');
  //     prices.add(
  //         item['varianceData']['variance_Defaultprice']?.toDouble() ?? 0.0);
  //     weights.add((item['weight'] ?? 0.0).toDouble());
  //     quantities.add((item['quantity'] as num).toDouble() ?? 0.0);
  //     amounts.add(cartProvider.calculateItemTotal(item).toDouble());
  //     taxes.add((item['itemData']['tax'] as num).toDouble());
  //     uoms.add(item['varianceData']['variance_Uom'] ?? 'N/A');
  //   }

  //   // Step 4: Prepare the complete invoice data
  //   DateTime billDate = DateTime.now();
  //   String formattedDate = DateFormat('dd-MM-yy').format(billDate);
  //   String formattedTime = DateFormat('hh:mm a').format(billDate);

  //   String uniqueIdentifier =
  //       '$formattedDate-${widget.totalAmount}-${_customerNumberController.text}';

  //   Map<String, dynamic> invoiceData = {
  //     'HiveInvoiceId': hiveInvoiceId,
  //     'itemName': itemNames,
  //     'varianceName': varianceNames,
  //     'price': prices,
  //     'weight': weights,
  //     'qty': quantities,
  //     'amount': amounts,
  //     'tax': taxes,
  //     'uom': uoms,
  //     'employeeName': _employeeNumberController.text,
  //     'customerPhoneNumber': _customerNumberController.text,
  //     'discountPercentage': _discountController.text.isNotEmpty
  //         ? int.tryParse(_discountController.text) ?? 0
  //         : 0,
  //     'customCharge': _customChargeController.text.isNotEmpty
  //         ? int.tryParse(_customChargeController.text) ?? 0
  //         : 0,
  //     'totalAmount': widget.totalAmount.toStringAsFixed(0),
  //     'totalAmount2': widget.totalAmount.toStringAsFixed(0),
  //     'invoiceDate': formattedDate,
  //     'branchId': "099089",
  //     'salesType': "TakeAway",
  //     'branchName': "Aranmanai",
  //     'paymentType': _selectedPaymentOptionVaule,
  //     'cash': _cashAmount > 0 ? _cashAmount : null,
  //     'card': _cardAmount > 0 ? _cardAmount : null,
  //     'upi': _upiAmount > 0 ? _upiAmount : null,
  //     'others': null,
  //     'invoiceTime': formattedTime,
  //     'shiftNumber': "1",
  //     'shiftId': "1",
  //     'invoiceNo': "BM2402",
  //     'deviceNumber': "1",
  //     "sync": "no",
  //     "status": "active",
  //     "uniqueIdentifier": uniqueIdentifier,
  //   };

  //   // Log the invoice data only if it hasn't been logged before
  //   if (!_loggedInvoices.contains(uniqueIdentifier)) {
  //     _loggedInvoices.add(uniqueIdentifier);
  //     developer.log('Invoice Data:', name: 'InvoiceLog');
  //     developer.log(invoiceData.toString(), name: 'InvoiceLog');
  //   }
  // }

  /// Save the invoice data to Hive and console log it
  Future<void> saveInvoiceToHiveAndPrint() async {
    // Step 1: Generate a unique HiveInvoiceId
    String hiveInvoiceId = _invoiceService.generateShortHiveInvoiceId();

    // Step 2: Prepare the invoice data
    var cartProvider = Provider.of<CurrentSaleProvider>(context, listen: false);
    var cartItems = cartProvider.currentSaleItems ?? [];

    // Extract item data into separate lists
    List<String> itemNames = [];
    List<String> varianceNames = [];
    List<double> prices = [];
    List<double> weights = [];
    List<double> quantities = [];
    List<double> amounts = [];
    List<double> taxes = [];
    List<String> uoms = [];

    for (var item in cartItems) {
      itemNames.add(item['itemData']['itemName'] ?? 'N/A');
      varianceNames.add(item['varianceData']['varianceName'] ?? 'N/A');
      prices.add(
          item['varianceData']['variance_Defaultprice']?.toDouble() ?? 0.0);
      weights.add((item['weight'] ?? 0.0).toDouble());
      quantities.add((item['quantity'] as num).toDouble() ?? 0.0);
      amounts.add(cartProvider.calculateItemTotal(item).toDouble());
      taxes.add((item['itemData']['tax'] as num).toDouble());
      uoms.add(item['varianceData']['variance_Uom'] ?? 'N/A');
    }

    // Step 3: Prepare the complete invoice data
    DateTime billDate = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy').format(billDate);
    String formattedTime = DateFormat('hh:mm a').format(billDate);

    String uniqueIdentifier =
        '$formattedDate-${widget.totalAmount}-${_customerNumberController.text}';

    Map<String, dynamic> invoiceData = {
      'HiveInvoiceId': hiveInvoiceId,
      'itemName': itemNames,
      'varianceName': varianceNames,
      'price': prices,
      'weight': weights,
      'qty': quantities,
      'amount': amounts,
      'tax': taxes,
      'uom': uoms,
      'employeeName': _employeeNumberController.text,
      'customerPhoneNumber': _customerNumberController.text,
      'discountPercentage': _discountController.text.isNotEmpty
          ? int.tryParse(_discountController.text) ?? 0
          : 0,
      'customCharge': _customChargeController.text.isNotEmpty
          ? int.tryParse(_customChargeController.text) ?? 0
          : 0,
      'totalAmount': widget.totalAmount.toStringAsFixed(0),
      'totalAmount2': widget.totalAmount.toStringAsFixed(0),
      'invoiceDate': formattedDate,
      'branchId': "099089",
      'salesType': "TakeAway",
      'branchName': "Aranmanai",
      'paymentType': _selectedPaymentOptionVaule,
      'cash': _cashAmount > 0 ? _cashAmount : null,
      'card': _cardAmount > 0 ? _cardAmount : null,
      'upi': _upiAmount > 0 ? _upiAmount : null,
      'others': null,
      'invoiceTime': formattedTime,
      'shiftNumber': "1",
      'shiftId': "1",
      'invoiceNo': "BM2402",
      'deviceNumber': "1",
      "sync": "no",
      "status": "active",
      "uniqueIdentifier": uniqueIdentifier,
    };

    // Step 4: Log the invoice data only if it hasn't been logged before
    if (!_loggedInvoices.contains(uniqueIdentifier)) {
      _loggedInvoices.add(uniqueIdentifier);
      developer.log('Invoice Data:', name: 'InvoiceLog');
      developer.log(invoiceData.toString(), name: 'InvoiceLog');
    }
    print("web123");
    await sendInvoiceDataToServer(invoiceData);
    print("web done");

    // Step 5: Save the invoice to Hive only if it doesn't already exist
    var box = await Hive.openBox('invoiceBox');
    bool exists = box.values.any((invoice) =>
        invoice is Map<String, dynamic> &&
        invoice['uniqueIdentifier'] == uniqueIdentifier);

    if (!exists) {
      await box.add(invoiceData);
      developer.log('Invoice saved to Hive:', name: 'InvoiceLog');
    }
    // try {
    //   var response = await _invoiceService.postInvoiceToFastAPI(invoiceData);
    //   if (response.statusCode == 201) {
    //     // Send SMS
    //     String customerNumber = _customerNumberController.text;
    //     String totalAmount = widget.totalAmount.toStringAsFixed(0);
    //     String billNumber = invoiceData['invoiceNo'];

    //     String smsApiUrl =
    //         'https://mailcon.in/vb/apikey.php?apikey=w31prN4CCtJg7XvK&senderid=BMUMMY&templateid=1707167058380400950&number=$customerNumber&message=WELCOME TO BESTMUMMY BILL NO:$billNumber BILL AMOUNT: $totalAmount VISIT OUR 45 THANK YOU FOR VISITING AGAIN';

    //     var smsResponse = await http.get(Uri.parse(smsApiUrl));
    //     if (smsResponse.statusCode == 201) {
    //       print('SMS sent successfully to $customerNumber');
    //     } else {
    //       print('Failed to send SMS: ${smsResponse.body}');
    //     }
    //   } else {
    //     print('Failed to post invoice: ${response.statusCode}');
    //   }
    // } catch (e) {
    //   print('Error posting invoice or sending SMS: $e');
    // }
    // try {
    //   var response = await _invoiceService.postInvoiceToFastAPI(invoiceData);
    //   if (response.statusCode == 201) {
    //     // Send SMS
    //     String customerNumber = _customerNumberController.text;
    //     String totalAmount = widget.totalAmount.toStringAsFixed(0);
    //     String billNumber = invoiceData['invoiceNo'];

    //     String smsApiUrl =
    //         'https://mailcon.in/vb/apikey.php?apikey=w31prN4CCtJg7XvK&senderid=BMUMMY&templateid=1707167058380400950&number=$customerNumber&message=WELCOME TO BESTMUMMY BILL NO:$billNumber BILL AMOUNT: $totalAmount VISIT OUR 45 THANK YOU FOR VISITING AGAIN';

    //     var smsResponse = await http.get(Uri.parse(smsApiUrl));
    //     if (smsResponse.statusCode == 200) {
    //       print('SMS sent successfully to $customerNumber');
    //     } else {
    //       print('Failed to send SMS: ${smsResponse.body}');
    //     }
    //     Future<void> sendWhatsAppMessage(String customerNumber,
    //         String billNumber, String totalAmount) async {
    //       try {
    //         String whatsappApiUrl =
    //             'https://backend.askeva.io/v1/message/send-message?token=226b3bc6338f9de4107cc93016924fb2868113776165b8d4b9a76914930e2fa2e47ff2906d87e0281121e425dccf62d84a6a82303c99beb2c24d0f9da7a46c1e32af25b2e74b7e42a7d17ce834c474aeb9b4abecdf454ade5fcd7519b8dd2e3893e0ac008bf50aa0d2ddc59737e381d4166d7d1e45af5cb285d388959efdc897c43af27799a56ea571830eca7cb8d5f08cf4284b28dff365fb85a2ad9d645ee0aaf8a86e8d6103150f29361e0f4556ba02cbf0149bacd06ad35fbe51d0ba630533cf73a51476c02eccc3845d13506638';

    //         Map<String, dynamic> whatsappMessage = {
    //           "to": customerNumber,
    //           "type": "image",
    //           "template": {
    //             "language": {"policy": "deterministic", "code": "en"},
    //             "name": "whatsapp_test",
    //             "components": [
    //               {
    //                 "type": "header",
    //                 "parameters": [
    //                   {
    //                     "type": "image",
    //                     "image": {"link": "https://yenerp.com/share/logo.jpg"}
    //                   }
    //                 ]
    //               },
    //               {
    //                 "type": "body",
    //                 "parameters": [
    //                   {"type": "text", "text": "Team"},
    //                   {"type": "text", "text": "Bill No: $billNumber"},
    //                   {"type": "text", "text": "Amount: ₹$totalAmount"}
    //                 ]
    //               }
    //             ]
    //           }
    //         };

    //         var whatsappResponse = await http.post(
    //           Uri.parse(whatsappApiUrl),
    //           headers: {
    //             "Content-Type": "application/json",
    //           },
    //           body: json.encode(whatsappMessage),
    //         );

    //         if (whatsappResponse.statusCode == 200) {
    //           print('WhatsApp message sent successfully to $customerNumber');
    //         } else {
    //           print(
    //               'Failed to send WhatsApp message. Status Code: ${whatsappResponse.statusCode}');
    //           print('Response Body: ${whatsappResponse.body}');
    //         }
    //       } catch (e) {
    //         print('Error sending WhatsApp message: $e');
    //       }
    //     }

    //     // Send WhatsApp message
    //     String whatsappApiUrl =
    //         'https://backend.askeva.io/v1/message/send-message?token=226b3bc6338f9de4107cc93016924fb2868113776165b8d4b9a76914930e2fa2e47ff2906d87e0281121e425dccf62d84a6a82303c99beb2c24d0f9da7a46c1e32af25b2e74b7e42a7d17ce834c474aeb9b4abecdf454ade5fcd7519b8dd2e3893e0ac008bf50aa0d2ddc59737e381d4166d7d1e45af5cb285d388959efdc897c43af27799a56ea571830eca7cb8d5f08cf4284b28dff365fb85a2ad9d645ee0aaf8a86e8d6103150f29361e0f4556ba02cbf0149bacd06ad35fbe51d0ba630533cf73a51476c02eccc3845d13506638';
    //     Map<String, dynamic> whatsappMessage = {
    //       "to": "91$customerNumber",
    //       "type": "template",
    //       "template": {
    //         "language": {"policy": "deterministic", "code": "en"},
    //         "name": "whatsapp_test",
    //         "components": [
    //           {
    //             "type": "header",
    //             "parameters": [
    //               {
    //                 "type": "image",
    //                 "image": {"link": "https://yenerp.com/share/offer.jpg"}
    //               }
    //             ]
    //           },
    //           {
    //             "type": "body",
    //             "parameters": [
    //               {"type": "text", "text": "Customer"},
    //               {"type": "text", "text": "Bill No: $billNumber"},
    //               {"type": "text", "text": "Amount: $totalAmount"}
    //             ]
    //           }
    //         ]
    //       }
    //     };

    //     var whatsappResponse = await http.post(
    //       Uri.parse(whatsappApiUrl),
    //       headers: {
    //         "Content-Type": "application/json",
    //       },
    //       body: json.encode(whatsappMessage),
    //     );

    //     if (whatsappResponse.statusCode == 201) {
    //       print('WhatsApp message sent successfully to $customerNumber');
    //     } else {
    //       print('Failed to send WhatsApp message: ${whatsappResponse.body}');
    //     }
    //   } else {
    //     print('Failed to post invoice: ${response.statusCode}');
    //   }
    // } catch (e) {
    //   print('Error posting invoice or sending message: $e');
    // }

    // Step 6: Optionally, post the invoice to FastAPI
    try {
      developer.log('Calling postInvoiceToFastAPI...', name: 'InvoiceLog');
      var response = await _invoiceService.postInvoiceToFastAPI(invoiceData);

      if (response.statusCode == 201) {
        developer.log('Invoice successfully posted to FastAPI',
            name: 'InvoiceLog');
      } else {
        developer.log(
            'Failed to post invoice: ${response.statusCode} - ${response.body}',
            name: 'InvoiceLog');
      }
    } catch (e) {
      developer.log('Error posting invoice: $e', name: 'InvoiceLog');
    }
  }

  Future<void> printInvoiceData() async {
    var box = await Hive.openBox('invoiceBox');

    // Check if the box is not empty
    if (box.isNotEmpty) {
      // Iterate through all invoices stored in the box
      for (var i = 0; i < box.length; i++) {}
    } else {}

    await box.close();
  }

  Future<void> updateInvoice(
      String invoiceId, Map<String, dynamic> updatedFields) async {
    var box = await Hive.openBox('invoiceBox');
    if (box.containsKey(invoiceId)) {
      Map<String, dynamic> currentInvoice =
          box.get(invoiceId).cast<String, dynamic>();
      // Update fields
      currentInvoice.addAll(updatedFields);
      // Save the updated invoice
      await box.put(invoiceId, currentInvoice);
    } else {}
  }

  void _applyDiscount(String discount) {
    final saleProvider =
        Provider.of<CurrentSaleProvider>(context, listen: false);
    setState(() {
      double discountValue = double.tryParse(discount) ?? 0.0;
      saleProvider.discountPercentage = discountValue;
      saleProvider
          .calculateTotal(); // Recalculate the total when discount is applied
    });
  }

  // Method to calculate balance based on selected payment
  void _updateBalance(double selectedAmount) {
    final saleProvider =
        Provider.of<CurrentSaleProvider>(context, listen: false);
    setState(() {
      // Subtract the selected amount from the total to get the balance
      _balanceAmount = saleProvider.calculateTotal() - selectedAmount;
    });
  }

  List<String> _generateCashOptions(double amount) {
    List<String> options = [];
    int exactAmount =
        amount.ceil(); // Ensure it covers the total even if it's a fraction
    options.add(exactAmount.toString()); // Add exact amount

    // Determine the next immediate round figure close to the exact amount
    int nextImmediateRound = (exactAmount % 50 == 0)
        ? exactAmount + 50
        : ((exactAmount / 50).ceil() * 50);
    options.add(nextImmediateRound.toString());

    // Determine a higher typical round figure
    int higherRoundFigure;
    if (nextImmediateRound % 100 == 0) {
      higherRoundFigure = nextImmediateRound + 100;
    } else {
      higherRoundFigure = ((nextImmediateRound / 100).ceil() * 100);
    }
    options.add(higherRoundFigure.toString());

    // Ensure we have exactly three distinct options (this is to handle edge cases where amounts could overlap)
    return options.toSet().toList();
  }

  void _showCustomKeyboard(TextEditingController controller) {
    showModalBottomSheet(
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        return CustomKeyboard(
          onTextInput: (value) {
            setState(() {
              controller.text += value;
            });
          },
          onBackspace: () {
            setState(() {
              if (controller.text.isNotEmpty) {
                controller.text =
                    controller.text.substring(0, controller.text.length - 1);
              }
            });
          },
          onClose: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _selectPaymentOption(String method, String amount) {
    int selectedAmount;

    // Determine selected amount based on the custom input or predefined option
    if (amount == 'Custom' && _customAmountController.text.isNotEmpty) {
      selectedAmount = int.tryParse(_customAmountController.text) ?? 0;
    } else {
      selectedAmount = int.tryParse(amount.replaceAll('', '')) ?? 0;
    }

    setState(() {
      _selectedPaymentOption = '$method: $amount';
      _selectedPaymentOptionVaule = method;

      if (method == "Cash") {
        _cashAmount = selectedAmount;
        _cardAmount = 0;
        _upiAmount = 0;
      } else if (method == "Card") {
        _cardAmount = selectedAmount;
        _cashAmount = 0;
        _upiAmount = 0;
      } else if (method == "Upi") {
        _upiAmount = selectedAmount;
        _cashAmount = 0;
        _cardAmount = 0;
      }

      _updateBalance(selectedAmount.toDouble());
    });

    _validateForm(); // Revalidate form after selecting a payment option
  }

  Widget _buildPaymentOption(String amount, String method) {
    bool isSelected = _selectedPaymentOption == '$method: $amount';
    // Error handling for custom amount
    bool isError = false;
    if (amount == 'Custom' && _customAmountController.text.isNotEmpty) {
      double customAmount =
          double.tryParse(_customAmountController.text) ?? 0.0;
      isError = customAmount < widget.totalAmount;
    }

    if (amount == 'Custom') {
      return CustomSizedBox(
        width: 100,
        child: TextField(
          controller: _customAmountController,
          keyboardType: TextInputType.number, // Set system numeric keyboard
          readOnly: false, // Allow the system keyboard to open
          onChanged: (value) {
            _selectPaymentOption(method, amount);
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Custom',
            errorText: isError ? 'Amount exceeds total' : null,
            filled: isSelected,
            fillColor: isSelected ? Colors.white : Colors.white,
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () {
            _selectPaymentOption(method, amount);
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (states) => isSelected ? Colors.blue : Colors.white),
            foregroundColor: WidgetStateProperty.resolveWith<Color>(
                (states) => isSelected ? Colors.white : Colors.blue),
          ),
          child: CustomText(
            text: amount,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }
  }

  Widget _buildPaymentSection(String method) {
    final saleProvider = Provider.of<CurrentSaleProvider>(context);
    List<String> options = cashOptions;
    if (method != 'Cash') {
      // Use the calculated total amount for UPI and Card
      options = [(saleProvider.calculateTotal().toStringAsFixed(0))];
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CustomText(
          text: method,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const CustomSizedBox(width: 10),
        for (var option in options) _buildPaymentOption(option, method),
        if (method == 'Cash')
          _buildPaymentOption('Custom', method), // Only for 'Cash'
        const Divider(),
      ],
    );
  }

  List<String> splitText(String text, int maxLineWidth) {
    List<String> lines = [];
    String remainingText = text ?? '';

    while (remainingText.length > maxLineWidth) {
      int lastIndex = remainingText.lastIndexOf(' ', maxLineWidth);
      if (lastIndex == -1) {
        // If no space is found, break at maxLineWidth
        lastIndex = maxLineWidth;
      }
      lines.add(remainingText.substring(0, lastIndex).trimRight());
      remainingText = remainingText.substring(lastIndex).trimLeft();
    }

    lines.add(remainingText);

    return lines;
  }

  bool _isSubmitting = false; // Track submission state
  void _printReceiptDetails() async {
    if (_isSubmitting) return; // Prevent double submission
    setState(() {
      _isSubmitting = true; // Lock the button to prevent multiple clicks
    });

    try {
      ReceiptPrinter printer = ReceiptPrinter(
        employeeNumberController: _selectedEmployeeFirstName.toString(),
        customerNumberController: _customerNumberController,
        discountController: _discountController,
        customChargeController: _customChargeController,
        selectedPaymentOptionValue: _selectedPaymentOptionVaule,
        totalAmount: widget.totalAmount,
        context: context,
        customAmountController: _customAmountController,
        selectedPaymentOption: _selectedPaymentOption,
        saveInvoiceToHiveAndPrint: saveInvoiceToHiveAndPrint,
      );

      await printer.printReceiptDetails();
      setState(() {
        _isSubmitting = true; // Disable button after success
      });
      print("Receipt printed successfully!");
    } catch (e) {
      print("Error printing receipt: $e");
      setState(() {
        _isSubmitting = false; // Unlock the button if printing fails
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final saleProvider = Provider.of<CurrentSaleProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // IconButton(
          //   icon: const Icon(
          //     Icons.sync,
          //     color: Colors.black,
          //     size: 32,
          //   ),
          //   onPressed: () async {
          //     // Get an instance of ItemProvider
          //     final itemProvider =
          //         Provider.of<ItemProvider>(context, listen: false);

          //     // Get the lazy box
          //     var lazyBox = await Hive.openLazyBox('items');

          //     // Call the fetchAndSaveBillReceiptSettings method to sync the settings
          //     // await itemProvider.fetchAndSaveBillReceiptSettings(lazyBox);

          //     // Optional: Show a snackbar or some feedback to the user
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text('Settings synchronized')),
          //     );
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(
          //     Icons.close,
          //     color: Colors.black,
          //     size: 32,
          //   ),
          //   onPressed: () {
          //     Navigator.of(context).pop();
          //   },
          // ),
        ],
      ),
      body: RepaintBoundary(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: '₹${saleProvider.calculateTotal().toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const CustomSizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _employeeNumberController,
                            decoration: InputDecoration(
                              labelText: "Employee Number",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.blue, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 10,
                              ),
                            ),
                            onChanged: (value) {
                              // Trigger suggestions when text is entered
                              setState(() {
                                _showEmployeeSuggestions = value.isNotEmpty;
                              });
                            },
                          ),
                          if (_showEmployeeSuggestions) // Show dropdown if suggestions are available
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _employeeSuggestions.length,
                                itemBuilder: (context, index) {
                                  // Extract the 'name' field from the map
                                  final employee = _employeeSuggestions[index];

                                  return ListTile(
                                    title: Text(
                                        '${employee['employeeNumber']} - ${employee['firstName']}'),
                                    onTap: () => _selectEmployee(employee),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    Flexible(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        controller: _customerNumberController,
                        inputFormatters: [
                          CustomNumberInputFormatter(), // Custom input formatter
                        ],
                        decoration: InputDecoration(
                          labelText: "Customer Number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 10,
                          ),
                        ),
                        onChanged: (value) {
                          print("Entered: $value");
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        controller: _discountController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(
                              r'^\d{0,2}$')), // Allows only up to 2 digits
                        ],
                        decoration: InputDecoration(
                          labelText: "Discount",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 10,
                          ),
                        ),
                        onChanged: (value) {
                          _applyDiscount(
                              value); // Apply discount and update total
                        },
                      ),
                    ),
                    const SizedBox(width: 40),
                    Flexible(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        controller: _customChargeController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(
                              r'^\d{0,4}$')), // Allows only up to 4 digits
                        ],
                        decoration: InputDecoration(
                          labelText: "Custom Charge",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.blue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 10,
                          ),
                        ),
                        onChanged: (value) {
                          double charge = double.tryParse(value) ?? 0.0;
                          Provider.of<CurrentSaleProvider>(context,
                                  listen: false)
                              .customCharge = charge;
                        },
                      ),
                    )
                  ],
                ),
                const CustomSizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 110),
                  child: _buildPaymentSection('Cash'),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 110),
                  child: _buildPaymentSection('Upi'),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 110),
                  child: _buildPaymentSection('Card'),
                ),
                const CustomSizedBox(height: 10),
                const CustomText(text: "Balance Amount"),
                CustomText(
                  text: _balanceAmount.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const CustomSizedBox(height: 10),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                        _isPrintButtonEnabled
                            ? Colors.blue
                            : Colors
                                .grey), // Disable color when button is disabled/ Background color
                    foregroundColor: WidgetStateProperty.all<Color>(
                        Colors.white), // Text color
                    padding: WidgetStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(
                          horizontal: 30.0, vertical: 18.0), // Padding
                    ),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8.0), // Rounded corners
                      ),
                    ),
                    elevation:
                        WidgetStateProperty.all<double>(5.0), // Elevation
                  ),
                  onPressed: _isPrintButtonEnabled
                      ? _printReceiptDetails
                      : null, // Disable button if form is incomplete
                  child: const CustomText(
                    text: "Print Receipt",
                    style: TextStyle(
                      fontSize: 16, // Font size
                      fontWeight: FontWeight.bold, // Font weight
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

// Widget for displaying employee suggestions dropdown
  Widget _buildEmployeeSuggestionsDropdown() {
    return Container(
      height: 200, // Set a fixed height for the dropdown
      color: Colors.white,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _employeeSuggestions.length,
        itemBuilder: (context, index) {
          final employee = _employeeSuggestions[index];
          return ListTile(
            title: Text(
                '${employee['employeeNumber']} - ${employee['firstName']}'),
            onTap: () => _selectEmployee(employee),
          );
        },
      ),
    );
  }
}

class CustomNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final regExp =
        RegExp(r'^[6-9][0-9]{0,9}$'); // Starts with 6-9, up to 10 digits

    // Check if the new value is empty to allow clearing the input
    if (newValue.text.isEmpty) {
      return newValue;
    }

    if (regExp.hasMatch(newValue.text)) {
      // Valid input
      return newValue;
    } else if (newValue.text.length > 10) {
      // If the input exceeds 10 digits, return old value
      return oldValue;
    }

    // Revert to the old value if invalid input
    return oldValue;
  }
}
