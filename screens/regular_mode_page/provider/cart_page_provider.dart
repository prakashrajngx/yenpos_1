import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'isolation/sales_caculate.dart';

class CurrentSaleProvider with ChangeNotifier {
  late SaleCalculator _saleCalculator =
      SaleCalculator([]); // Initialize with an empty list

  List<Map<String, dynamic>> _currentSaleItems = [];
  final double _discountPercentage = 0.0; // Initial discount percentage
  final double _customCharge = 0.0; // New property for custom charge
  double get discountPercentage => _discountPercentage;
  double sgst = 0.0; // SGST amount
  double cgst = 0.0; // CGST amount

  double get sgstAmount => sgst; // Add getter for SGST
  double get cgstAmount => cgst; // Add getter for CGST
  List<Map<String, dynamic>> get currentSaleItems => _currentSaleItems;
  double get customCharge => _customCharge; // Getter for custom charge

  double sgstRate = 0.0; // Rate in percentage
  double cgstRate = 0.0; // Rate in percentage

  // Add getters for SGST and CGST rates
  double get sgstRatePercentage => sgstRate;
  double get cgstRatePercentage => cgstRate;

  String _selectedOption = 'TakeAway'; // Set default to "Take Away"

  String get selectedOption => _selectedOption;
  String _status = ''; // Track the current sale status
  String get saleStatus => _status;

  String? _holdBillId; // Store the selected hold bill ID

  String? get holdBillId => _holdBillId;
  String? _currentHoldId; // Store the currently loaded hold bill ID
  String? get currentHoldId => _currentHoldId;

  void setCurrentHoldId(String? id) {
    _currentHoldId = id;
    notifyListeners();
  }

  void setHoldBillId(String id) {
    _holdBillId = id;
    notifyListeners();
  }

  void selectOption(String option) {
    _selectedOption = option;
    _status = ''; // Reset the sale status
    notifyListeners(); // Notify the UI of changes
  }

  CurrentSaleProvider() {
    loadCartItems();
  }

  set discountPercentage(double value) {
    _saleCalculator.discountPercentage = value;
    notifyListeners(); // Notify listeners to update UI
  }

  set customCharge(double value) {
    _saleCalculator.customCharge = value;
    notifyListeners();
  }

  void addItemToCart(Map<String, dynamic> newItem) async {
    bool exists = _currentSaleItems.any((item) =>
        item['itemData']['itemId'] == newItem['itemData']['itemId'] &&
        item['varianceData']['varianceName'] ==
            newItem['varianceData']['varianceName']);

    if (exists) {
      // Update quantity for existing item
      _currentSaleItems = _currentSaleItems.map((item) {
        if (item['itemData']['itemId'] == newItem['itemData']['itemId'] &&
            item['varianceData']['varianceName'] ==
                newItem['varianceData']['varianceName']) {
          item['quantity'] += newItem['quantity'];
          print("Updated quantity for existing item: $item");
        }
        return item;
      }).toList();
    } else {
      // Insert new item at the beginning of the list
      _currentSaleItems.insert(0, newItem);
      print("Added new item at the beginning: $newItem");
    }

    _saleCalculator = SaleCalculator(_currentSaleItems); // Recalculate totals

    // Save updated cart to Hive
    var box = await Hive.openBox('cartBox');
    await box.put('cartItems', _currentSaleItems); // Save updated list
    print("Cart items saved to Hive: $_currentSaleItems");

    notifyListeners(); // Notify UI to rebuild
  }

  Future<void> loadCartItems() async {
    var box = await Hive.openBox('cartBox');
    List<dynamic> rawItems = box.get('cartItems', defaultValue: []);
    _currentSaleItems = rawItems
        .map((item) => Map<String, dynamic>.from(item))
        .toList(); // Load all items, including new additions
    _saleCalculator = SaleCalculator(_currentSaleItems);
    print("Loaded cart items from Hive: $_currentSaleItems");

    notifyListeners(); // Notify UI to rebuild
  }

  void loadItemsFromBill(List<Map<String, dynamic>> items,
      {bool merge = false, String? holdId}) {
    if (!merge) {
      // Clear current items if not merging
      _currentSaleItems.clear();
      print("Cleared existing items in the current sale.");
    }
    // Add or merge items from the hold bill
    for (var newItem in items) {
      bool exists = _currentSaleItems.any((item) =>
          item['itemData']['itemId'] == newItem['itemData']['itemId'] &&
          item['varianceData']['varianceName'] ==
              newItem['varianceData']['varianceName']);
      if (!exists) {
        _currentSaleItems.add(newItem);
        print("Added new item to the current sale from hold: $newItem");
      } else {
        print("Item already exists in the current sale, skipping: $newItem");
      }
    }
    _currentHoldId = holdId; // Set the hold ID
    _saleCalculator = SaleCalculator(_currentSaleItems); // Recalculate totals
    notifyListeners();
  }

  void clearItems() async {
    _currentSaleItems.clear();
    var box = await Hive.openBox('cartBox');
    await box.put('cartItems', []);
    _saleCalculator = SaleCalculator(_currentSaleItems); // Reset SaleCalculator
    notifyListeners(); // Notify listeners after clearing the items
  }

  void removeItem(int index) async {
    _currentSaleItems.removeAt(index);
    var box = await Hive.openBox('cartBox');
    await box.put('cartItems', _currentSaleItems);
    notifyListeners(); // Notify listeners after removing the item
  }

  double calculateTotal() {
    return _saleCalculator.calculateTotal();
  }

  double calculateDiscountAmount() {
    return _saleCalculator.calculateDiscountAmount();
  }

  String buildQuantityPriceDisplay(Map<String, dynamic> item) {
    return _saleCalculator.buildQuantityPriceDisplay(item);
  }

  // String buildQuantityPriceDisplay(Map<String, dynamic> item) {
  //   final String uom = item['varianceData']['variance_Uom'].toLowerCase();
  //   final double price = item['varianceData']['variance_Defaultprice']
  //       .toDouble(); // Ensure price is a double
  //   final double quantity =
  //       (item['quantity'] ?? 1).toDouble(); // Ensure quantity is a double

  //   String quantityDisplay = '';
  //   String weightQuantityDidpay = '';
  //   // Check if the unit of measure is in kilograms or grams
  //   if (uom == 'kg' || uom == 'kgs') {
  //     if (quantity >= 1) {
  //       quantityDisplay = '${quantity.toStringAsFixed(1)} kg'; // Display in kg
  //     } else {
  //       // If quantity is less than 1 kg, convert to grams
  //       double grams = quantity * 1000;
  //       quantityDisplay = '${grams.toStringAsFixed(1)} g'; // Display in grams
  //     }
  //   } else {
  //     // For other units, assume the quantity is in pieces or count
  //     quantityDisplay = '${quantity.toInt()} $uom';
  //   }

  //   // Print the result in the console
  //   print(s
  //       'Quantity: $quantityDisplay x ₹ ${price.toStringAsFixed(2)} per $uom');
  //   print('Quantity: $quantityDisplay');

  //   // Return the formatted string for UI or other purposes
  //   return '$quantityDisplay';
  // }

  double calculateItemTotal(Map<String, dynamic> item) {
    return _saleCalculator.calculateItemTotal(item);
  }

  void updateItemQuantity(int index, double newQuantity) async {
    _currentSaleItems[index]['quantity'] = newQuantity;
    _saleCalculator = SaleCalculator(
        _currentSaleItems); // Update SaleCalculator with the new items
    var box = await Hive.openBox('cartBox');
    await box.put('cartItems', _currentSaleItems);
    notifyListeners(); // Notify listeners after updating the item quantity
  }

  Future<void> saveBill(BuildContext context) async {
    if (_currentSaleItems.isEmpty) {
      _showSnackBar(context, 'No items to save!', Colors.red);
      return;
    }

    var box = await Hive.openBox('cartBox');
    List<Map<String, dynamic>> itemsWithStatus =
        _currentSaleItems.map((item) => {...item, 'status': 'hold'}).toList();

    var randomId = generatetheholdrandomId();
    Map<String, dynamic> billData = {
      'holdId': randomId,
      'date': DateTime.now().toIso8601String(),
      'items': itemsWithStatus,
      'total': calculateTotal(),
      'status': 'hold',
    };
    Map<String, dynamic> billDataforhive = {
      'holdId': randomId,
      'date': DateTime.now().toIso8601String(),
      'items': itemsWithStatus,
      'total': calculateTotal(),
      'status': 'hold',
    };

    // Print the data to console
    print("Bill Data for Hive: $billDataforhive");
    print("Items with Status: $itemsWithStatus");

    // Transform `itemsWithStatus` into API-compatible format
    Map<String, dynamic> hivedatpostsapledata = {
      "holdId": randomId.toString(),
      "itemId": itemsWithStatus
          .map((item) => item['itemData']['itemId'] ?? "None")
          .toList(),
      "itemCode": itemsWithStatus
          .map((item) => item['varianceData']['varianceitemCode'] ?? "None")
          .toList(),
      "itemName": itemsWithStatus
          .map((item) => item['itemData']['itemName'] ?? "None")
          .toList(),
      "weight": itemsWithStatus
          .map((item) => item['varianceData']['variance_Uom'] ?? "None")
          .toList(),
      "price": itemsWithStatus
          .map((item) =>
              item['varianceData']['variance_Defaultprice'].toString() ??
              "None")
          .toList(),
      "category": itemsWithStatus
          .map((item) => item['itemData']['category'] ?? "None")
          .toList(),
      "qty": itemsWithStatus
          .map((item) => item['quantity'].toString() ?? "None")
          .toList(),
      "amount": itemsWithStatus
          .map((item) => calculateItemTotal(item).toString())
          .toList(),
      "tax": itemsWithStatus
          .map((item) => item['itemData']['tax'].toString() ?? "None")
          .toList(),
      "uom": itemsWithStatus
          .map((item) => item['itemData']['item_Uom'] ?? "None")
          .toList(),
      "totalAmount": calculateTotal().toString(),
      "totalAmount2": "0", // Placeholder
      "totalAmount3": "0", // Placeholder
      "status": "hold",
      "branchId": "0", // Placeholder
      "branch": "string", // Placeholder
      "discountPercentage": "0",
      "discountAmount": "0",
      "employeeName": "", // Placeholder
      "phoneNumber": "0", // Placeholder
      "phoneNumber2": "", // Placeholder
      "customCharge": "0",
      "netPrice": calculateTotal().toString(),
      "invoiceNo": "0", // Placeholder
      "date": DateTime.now().toIso8601String(),
      "time": DateTime.now().toIso8601String(),
      "paymentType": "", // Placeholder
      "salesType": "", // Placeholder
      "salesReturn": "", // Placeholder
      "salesReturnNumber": "0", // Placeholder
      "type": "", // Placeholder
      "salesOrderNumber": "", // Placeholder
      "customerName": "", // Placeholder
      "deliveryDate": "", // Placeholder
      "deliveryTime": "", // Placeholder
      "event": "", // Placeholder
      "advance": "", // Placeholder
      "orderPreference": "", // Placeholder
      "deliveryPreference": "", // Placeholder
      "orderDate": "", // Placeholder
      "orderTime": "", // Placeholder
      "remark": "", // Placeholder
      "orderInvoiceNo": "", // Placeholder
      "invoiceDate": "", // Placeholder
      "cash": "", // Placeholder
      "upi": "", // Placeholder
      "card": "", // Placeholder
      "deliveryPartner": "", // Placeholder
      "otherPayment": "", // Placeholder
      "deliveryPartnerName": "", // Placeholder
      "shiftNumber": "", // Placeholder
      "shiftId": "", // Placeholder
      "deliveryLocation": "", // Placeholder
      "preinvoiceId": "" // Placeholder
    };

    // Post the bill data to the FastAPI endpoint
    try {
      final url = Uri.parse('http://192.168.1.119:8888/fastapi/holds/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(hivedatpostsapledata),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bill saved as hold (Hold ID: $randomId)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 20, bottom: 20, right: 680),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        // Handle server errors
        print('Failed to post data to server: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to post data to server: ${response.statusCode}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      // Handle network errors
      print('Network error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Network error: $error',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }

    await box.add(billData);
    _showSnackBar(
        context, 'Bill saved as hold (Hold ID: $randomId)', Colors.green);
    clearItems();
  }

  Future<void> removeHold(int index) async {
    var box = await Hive.openBox('cartBox');
    await box.deleteAt(index);
    notifyListeners();
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Future<void> saveBill(BuildContext context) async {
  //   if (_currentSaleItems.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: const Text(
  //           'No items to save!',
  //           style: TextStyle(fontWeight: FontWeight.bold),
  //         ),
  //         backgroundColor: Colors.red,
  //         duration: const Duration(seconds: 2),
  //         behavior: SnackBarBehavior.floating,
  //         margin: const EdgeInsets.only(left: 20, bottom: 20, right: 680),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(10),
  //         ),
  //       ),
  //     );
  //     return;
  //   }

  //   // Open the Hive box for invoices
  //   var holdinvoiceBox = await Hive.openBox('cartBox');

  //   // Set the status for each item to 'hold'
  //   List<Map<String, dynamic>> itemsWithStatus =
  //       _currentSaleItems.map((item) => {...item, 'status': 'hold'}).toList();
  //   print("HO${itemsWithStatus}");
  //   // Generate a unique hold bill ID
  //   var randomId = generatetheholdrandomId();

  //   // Prepare the bill data for Hive and API
  //   Map<String, dynamic> billDataforhive = {
  //     'holdId': randomId,
  //     'date': DateTime.now().toIso8601String(),
  //     'items': itemsWithStatus,
  //     'total': calculateTotal(),
  //     'status': 'hold',
  //   };
  //   Map<String, dynamic> hivedatpostsapledata = {
  //     "itemId": ["string"],
  //     "itemName": ["string"],
  //     "itemCode": ["string"],
  //     "weight": ["string"],
  //     "price": ["string"],
  //     "category": ["string"],
  //     "qty": ["string"],
  //     "amount": ["string"],
  //     "tax": ["string"],
  //     "uom": ["string"],
  //     "totalAmount": 0,
  //     "totalAmount2": 0,
  //     "totalAmount3": 0,
  //     "status": "string",
  //     "branchId": 0,
  //     "branch": "string",
  //     "discountPercentage": 0,
  //     "discountAmount": 0,
  //     "employeeName": "string",
  //     "phoneNumber": 0,
  //     "customCharge": 0,
  //     "netPrice": 0,
  //     "invoiceNo": 0,
  //     "date": DateTime.now().toIso8601String(),
  //     "time": DateTime.now().toIso8601String(),
  //     "paymentType": "string",
  //     "salesType": "string",
  //     "salesReturn": "string",
  //     "salesReturnNumber": 0,
  //     "type": "string",
  //     "salesOrderNumber": "string",
  //     "customerName": "string",
  //     "deliveryDate": "string",
  //     "deliveryTime": "string",
  //     "event": "string",
  //     "advance": "string",
  //     "orderPreference": "string",
  //     "deliveryPreference": "string",
  //     "orderDate": "string",
  //     "orderTime": "string",
  //     "remark": "string",
  //     "orderInvoiceNo": "string",
  //     "invoiceDate": "string",
  //     "cash": "string",
  //     "upi": "string",
  //     "card": "string",
  //     "deliveryPartner": "string",
  //     "otherPayment": "string",
  //     "deliveryPartnerName": "string",
  //     "shiftNumber": "string",
  //     "shiftId": "string",
  //     "deliveryLocation": "string",
  //     "phoneNumber2": "string",
  //     "preinvoiceId": "string"
  //   };
  //   // Save the bill to Hive
  //   await holdinvoiceBox.add(billDataforhive);

  //   // Post the bill data to the FastAPI endpoint
  //   try {
  //     final url = Uri.parse('http://192.168.1.119:8888/fastapi/holds/');
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(hivedatpostsapledata),
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       // Show success message
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //             'Bill saved as hold (Hold ID: $randomId)',
  //             style: TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //           backgroundColor: Colors.green,
  //           duration: const Duration(seconds: 2),
  //           behavior: SnackBarBehavior.floating,
  //           margin: const EdgeInsets.only(left: 20, bottom: 20, right: 680),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //         ),
  //       );
  //     } else {
  //       // Handle server errors
  //       print('Failed to post data to server: ${response.statusCode}');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //             'Failed to post data to server: ${response.statusCode}',
  //             style: TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //           backgroundColor: Colors.red,
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     }
  //   } catch (error) {
  //     // Handle network errors
  //     print('Network error: $error');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           'Network error: $error',
  //           style: TextStyle(fontWeight: FontWeight.bold),
  //         ),
  //         backgroundColor: Colors.red,
  //         duration: Duration(seconds: 2),
  //       ),
  //     );
  //   }
  //   clearItems();
  // }

  int generatetheholdrandomId() {
    return 10 + (Random().nextInt(90)); // 90 ensures the range is 10 to 99
  }
}
    // Clear items after saving
    // clearItems();