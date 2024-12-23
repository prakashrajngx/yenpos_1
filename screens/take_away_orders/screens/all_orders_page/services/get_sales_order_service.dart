import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:yenposapp/screens/take_away_orders/screens/create_salesOrder.dart/models/held_order_model.dart';

import '../../model/sales_order_model.dart';
// import '../../model/sales_order_model.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ApiServiceSalesOrderProvider extends ChangeNotifier {
  ApiServiceSalesOrderProvider() {
    fetchOrders();
    fetchAllOrders();
    fetchCreditBills();
  }
  List<SalesOrder> _salesOrders = [];
  List<CreditOrder> _creditOrders = [];
  List<SalesOrder> _filteredSalesOrders = [];
  List<SalesOrder> _filteredAllSalesOrders = [];
  List<SalesOrder> _allSalesOrders = [];
  bool _isLoading = false;
  Timer? _debounce;

  List<SalesOrder> get salesOrders => _salesOrders;
  List<CreditOrder> get creditOrders => _creditOrders;
  List<SalesOrder> get filteredSalesOrders => _filteredSalesOrders;
  List<SalesOrder> get filteredAllSalesOrders => _filteredAllSalesOrders;
  List<SalesOrder> get allSalesOrders => _allSalesOrders;
  bool get isLoading => _isLoading;
  String? _searchQuery;

  DateTime fetchDate = DateTime.now();
  DateTime get date => fetchDate;

  void scanQRCode(String qrCode) {
    _searchQuery = qrCode;
    notifyListeners();
    searchOrders(qrCode); // Update filtered orders based on QR code
  }

  void showCreditDialog(String salesOrderId, BuildContext context) async {
    final updateStatusUrl =
        Uri.parse('http://192.168.1.117:8888/CurrentOrder/$salesOrderId');
    final creditBillUrl = Uri.parse(
        'http://192.168.1.117:8888/creditbills/?salesorderid=$salesOrderId');

    try {
      // First API Call: Update the status to 'Credit Pending'
      final updateResponse = await http.patch(
        updateStatusUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'Credit Pending'}),
      );

      if (updateResponse.statusCode == 200) {
        // If the first call succeeds, make the second API Call
        final creditResponse = await http.post(
          creditBillUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'salesorderid': salesOrderId}),
        );

        if (creditResponse.statusCode == 201) {
          print('Credit bill created successfully: ${creditResponse.body}');
          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Credit bill created successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          print('Failed to create credit bill: ${creditResponse.statusCode}');
          // Show failure snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create credit bill. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        print('Failed to update order status: ${updateResponse.statusCode}');
        // Show failure snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('An error occurred: $e');
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again later.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<Uint8List> fetchAudioDataByOrderId(String orderId) async {
    try {
      // Make a GET request to your FastAPI endpoint
      print(orderId);
      var response = await http.get(Uri.parse(
          'http://192.168.1.117:8888/voiceOrder/voiceOrder/media/${orderId}'));

      // Check if the response is successful (HTTP 200)
      if (response.statusCode == 200) {
        // Return the response body as Uint8List (binary audio data)
        return response
            .bodyBytes; // This will return the audio data in byte format
      } else {
        // If the response is not successful, throw an error
        throw Exception('Failed to load audio: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors (e.g., network issues)
      print('Error fetching audio data: $e');
      rethrow;
    }
  }

  final String baseUrl = "http://192.168.1.117:8888/CurrentOrder";
  //final String baseUrl = "http://192.168.1.119:8888/fastapi/salesorders/";
  Future<void> fetchOrders({DateTime? deliveryDate}) async {
    _isLoading = true;
    notifyListeners(); // Notify listeners that the loading state has changed

    try {
      // If no deliveryDate is provided, use today's date
      fetchDate = deliveryDate ?? DateTime.now();

      // Format the date in the required format (e.g., yyyy-MM-dd)
      String formattedDate = DateFormat('dd-MM-yyyy').format(fetchDate);
      print('Formatted Date: $formattedDate');

      // Construct the URL with the deliveryDate query parameter
      String url = '$baseUrl?deliveryDate=$formattedDate';
      _salesOrders = [];
      _filteredSalesOrders = [];
      notifyListeners();

      final response = await http.get(Uri.parse(url));

      // Check if the response was successful
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        // Filter orders for the provided deliveryDate (only "Confirm Order" status)
        _salesOrders = data
            .map((json) => SalesOrder.fromMap(json))
            .where((order) {
              try {
                // Parse the deliveryDate string into a DateTime object
                DateTime orderDeliveryDate =
                    DateFormat('dd-MM-yyyy').parse(order.deliveryDate);

                // Compare the year, month, and day
                return orderDeliveryDate.year == fetchDate.year &&
                    orderDeliveryDate.month == fetchDate.month &&
                    orderDeliveryDate.day == fetchDate.day &&
                    order.status ==
                        "Confirm Order"; // Only "Confirm Order" status
              } catch (e) {
                // Handle parsing error (e.g., invalid date format)
                return false;
              }
            })
            .toList()
            .reversed
            .toList(); // Reverse the filtered list

        // Set the filtered sales orders
        _filteredSalesOrders = List.from(_salesOrders);
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      print('Error: $e');
      _salesOrders = [];
      _filteredSalesOrders = [];
      throw Exception('Failed to load orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners that the loading is complete
    }
  }

  Future<void> fetchAllOrders() async {
    _isLoading = true;
    notifyListeners(); // Notify listeners that the loading state has changed

    try {
      // Base URL for fetching orders
      String url = baseUrl;

      // If start and end dates are provided, filter by them
      if (_startDate != null && _endDate != null) {
        final formattedStartDate = DateFormat('dd-MM-yyyy').format(_startDate!);
        final formattedEndDate = DateFormat('dd-MM-yyyy').format(_endDate!);
        print('formattedStart');
        print(formattedStartDate);
        print('formattedEnd');
        print(formattedEndDate);
        url =
            '$url?deliveryStartDate=$formattedStartDate&deliveryEndDate=$formattedEndDate';
      }

      // Otherwise, fetch all orders without date filters
      else {
        url = '$url'; // Default URL without date filters
      }
      print(url);

      // Log the URL before making the request
      print('Fetching data from URL: $url');

      final response = await http.get(Uri.parse(url));

      // Log the status code and response body for debugging
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Check if the response was successful
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        // Store all orders in _allSalesOrders
        _allSalesOrders = data.map((json) => SalesOrder.fromMap(json)).toList();
        print('Above the _filterALLSalesorder$_allSalesOrders');
        // Filter only "Open Order" status and reverse the list
        _filteredAllSalesOrders = _allSalesOrders
            .where((order) => order.status == "Confirm Order")
            .toList()
            .reversed
            .toList();
        _allSalesOrders = _filteredAllSalesOrders;
        print('_allsalesdorss$_allSalesOrders');
      } else {
        throw Exception(
            'Failed to load orders. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to load orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners that the loading is complete
    }
  }

  Future<void> fetchOrderById(String orderId) async {
    _isLoading = true;
    notifyListeners(); // Notify listeners that the loading state has changed

    try {
      // Construct the URL for fetching the specific order by ID
      final url = '$baseUrl/$orderId';
      print('Fetching order by ID from URL: $url');

      final response = await http.get(Uri.parse(url));

      // Log the status code and response body for debugging
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Check if the response was successful
      if (response.statusCode == 200) {
        // Decode the response body and map it to the order model
        final data = jsonDecode(response.body);
        final order = SalesOrder.fromMap(data);

        // Log the fetched order for debugging
        print('Fetched order: $order');

        // Update the state with the fetched order
        _filteredAllSalesOrders = [order];
      } else {
        throw Exception(
            'Failed to load order by ID. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to fetch order by ID: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners that the loading is complete
    }
  }

  void searchOrders(String query) async {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel(); // Cancel the previous debounce if it's still active
    }
    // Start a new debounce timer
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      _isLoading = true;
      String formattedDate = DateFormat('dd-MM-yyyy').format(fetchDate);

      if (query.isEmpty) {
        // If query is empty, show all sales orders with status "Open Order"
        //  _filteredSalesOrders = _salesOrders
        //     .where((order) => order.status == 'Open Order')
        //   .toList();
        _filteredSalesOrders = salesOrders;
      } else {
        // Determine the appropriate API endpoint based on query type
        final bool isPhoneNumber =
            RegExp(r'^\d+$').hasMatch(query); // Check if query is numeric
        final uri = Uri.parse(isPhoneNumber
            ? 'http://192.168.1.119:8888/fastapi/salesorders/?customerNumber=${Uri.encodeComponent(query)}&deliveryDate=$formattedDate'
            // : 'http://192.168.1.119:8888/fastapi/salesorders/?salesOrderLast5Digits=${Uri.encodeComponent(query)}&deliveryDate=$formattedDate');
            : 'http://192.168.1.119:8888/fastapi/salesorders/?salesOrderLast5Digits${Uri.encodeComponent(query)}');
        try {
          final response = await http.get(uri);

          if (response.statusCode == 200) {
            List<dynamic> data = jsonDecode(response.body);

            // Map the dynamic response to SalesOrder objects and filter by status
            _filteredSalesOrders = data
                .map((json) => SalesOrder.fromMap(json))
                .where((order) =>
                    order.status == 'Confirm Order') // Filter by status
                .toList();
          } else {
            _filteredSalesOrders = []; // If the request failed, reset the list
          }
        } catch (e) {
          _filteredSalesOrders =
              []; // Handle network error by resetting the list
        }
      }

      // Notify listeners (for UI update)
      notifyListeners();

      _isLoading = false;
    });
  }

  // void searchAllOrders(String query) {
  //   if (_debounce?.isActive ?? false) _debounce!.cancel();
  //   _debounce = Timer(const Duration(milliseconds: 300), () {
  //     _allSalesOrders = _salesOrders.where((order) {
  //       return order.salesOrderId.toLowerCase().contains(query.toLowerCase()) ||
  //           order.customerName.toLowerCase().contains(query.toLowerCase()) ||
  //           order.customerNo.contains(query);
  //     }).toList();
  //     notifyListeners();
  //   });
  // }
  void searchAllOrders(String query) async {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel(); // Cancel the previous debounce if it's still active
    }

    // Start a new debounce timer
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      _isLoading = true;

      if (query.isEmpty) {
        _filteredAllSalesOrders = _allSalesOrders;
      } else {
        // Determine the appropriate API endpoint based on query type
        final bool isPhoneNumber =
            RegExp(r'^\d+$').hasMatch(query); // Check if query is numeric
        final uri = Uri.parse(isPhoneNumber
            ? 'http://192.168.1.117:8888/CurrentOrder/?customerNumber=${Uri.encodeComponent(query)}'
            : 'http://192.168.1.117:8888/CurrentOrder/?salesOrderLast5Digits=${Uri.encodeComponent(query)}');

        try {
          final response = await http.get(uri);

          if (response.statusCode == 200) {
            List<dynamic> data = jsonDecode(response.body);

            // Map the dynamic response to SalesOrder objects
            // _allSalesOrders =
            //     data.map((item) => SalesOrder.fromMap(item)).toList();
            _filteredAllSalesOrders = data
                .where((item) =>
                    item['status'] == 'Open Order') // Filter by 'open order'
                .map((item) => SalesOrder.fromMap(item))
                .toList();
          } else {
            _filteredAllSalesOrders =
                []; // If the request failed, reset the list
          }
        } catch (e) {
          _filteredAllSalesOrders =
              []; // Handle network error by resetting the list
        }
      }

      // Notify listeners (for UI update)
      notifyListeners();

      _isLoading = false;
    });
  }

  // Method to fetch all orders
  // Future<void> fetchAllOrders() async {
  //   try {
  //     final response = await http.get(Uri.parse(baseUrl));
  //     if (response.statusCode == 200) {
  //       List<dynamic> data = jsonDecode(response.body);
  //       _allSalesOrders = data.map((json) => SalesOrder.fromMap(json)).toList();
  //       notifyListeners();
  //     } else {
  //       throw Exception('Failed to load all orders');
  //     }
  //   } catch (e) {
  //     print('Error: $e');
  //     throw Exception('Failed to load all orders: $e');
  //   }
  // }

  // Future<List<SalesOrder>> fetchOrders() async {
  //   try {
  //     final response = await http.get(Uri.parse(baseUrl));
  //     if (response.statusCode == 200) {
  //       List<dynamic> data = jsonDecode(response.body);
  //       return data.map((json) => SalesOrder.fromMap(json)).toList();
  //     } else {
  //       throw Exception('Failed to load orders');
  //     }
  //   } catch (e) {
  //     throw Exception('Failed to load orders: $e');
  //   }
  // }
// Future<bool> postSalesInvoice(){

// }
  Future<bool> updateOrderStatus(String salesOrderId, String status) async {
    try {
      final url = Uri.parse(
          '$baseUrl/create_invoice/$salesOrderId'); // Append ID to URL
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"status": status}), // Only update the status field
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true; // Update successful
      } else {
        throw Exception(
            'Failed to update status. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update status: $e  ');
    }
  }

  final String baseCreditUrl = "http://192.168.1.119:8888/fastapi/creditbills/";

  Future<void> fetchCreditBills() async {
    _isLoading = true;
    notifyListeners(); // Notify listeners that the loading state has changed

    try {
      String url = '$baseCreditUrl';
      _creditOrders = [];
      notifyListeners();

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        print('response body');
        print(response.body);

        // Parse all orders without filtering for "Open Order"
        _creditOrders = data
            .map((json) => CreditOrder.fromJson(json))
            .toList()
            .reversed
            .toList(); // Reverse the list if needed
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to load orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners that the loading is complete
    }
  }

  // bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;

//  bool get isLoading => _isLoading;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  void setStartDate(DateTime date) {
    _startDate = date;
    notifyListeners(); // Notify listeners about the change
  }

  void setEndDate(DateTime date) {
    _endDate = date;
    notifyListeners(); // Notify listeners about the change
  }

  Future<void> fetchFilteredOrders() async {
    //   _isLoading = true;
    notifyListeners();

    try {
      String url = baseUrl;

      // Add date parameters if both start and end dates are selected
      if (_startDate != null && _endDate != null) {
        final startDateStr = DateFormat('dd-MM-yyyy').format(_startDate!);
        final endDateStr = DateFormat('dd-MM-yyyy').format(_endDate!);
        url =
            '$url/?deliveryStartDate=$startDateStr&deliveryEndDate=$endDateStr';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Handle the response as needed
        print('Fetched orders successfully!');
      } else {
        throw Exception('Failed to fetch orders');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      // _isLoading = false;
      notifyListeners();
    }
  }
}
