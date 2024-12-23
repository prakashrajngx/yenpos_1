import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../global/globals.dart';
import 'printer_provider.dart';

class OrderProvider with ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  Box? canceledOrdersBox;
  Box? preInvoicesBox;
  late Box _orderBox;
  List<Map<String, dynamic>> _preInvoices = [];
  List<Map<String, dynamic>> get preInvoices => _preInvoices;

  String orderSource = const Uuid().v4();

  List<Map<String, dynamic>> get orders => _orders;
  late WebSocketChannel channel;

  Future<void> initializeWebSocket(String serverAddress) async {
    try {
      channel = IOWebSocketChannel.connect('ws://$serverAddress');
      listenForServerUpdates();
    } catch (e) {
      print('Failed to initialize WebSocket: $e');
    }
  }

  Future<void> initializeHive() async {
    try {
      _orderBox = await Hive.openBox('orders');
      canceledOrdersBox = await Hive.openBox('canceledOrdersBox');
      preInvoicesBox = await Hive.openBox('preInvoicesBox');
      _loadOrdersFromHive(); // Load orders from Hive
      _loadPreInvoicesFromHive(); // Load pre-invoices from Hive
      await initializeWebSocket('$serverip:$port'); //
    } catch (e) {
      print("Error opening Hive boxes: $e");
    }
  }

  addCanceledOrder(Map<String, dynamic>? order) {
    if (order != null) {
      canceledOrdersBox?.add(order);
      notifyListeners();
    } else {
      print("Attempted to add a null order.");
    }
  }

  List<dynamic> getCanceledOrders() {
    final orders = canceledOrdersBox?.values.toList() ?? [];
    print("Retrieved canceled orders: $orders");
    return orders;
  }

  // Future<void> addPreInvoice(Map<String, dynamic> preInvoiceData) async {
  //   final preInvoiceId = preInvoiceData['preInvoiceId'];
  //   if (preInvoicesBox != null &&
  //       !preInvoicesBox!.values
  //           .any((invoice) => invoice['preInvoiceId'] == preInvoiceId)) {
  //     await preInvoicesBox?.add(preInvoiceData);
  //     _preInvoices.add(preInvoiceData);
  //     notifyListeners();
  //   } else {
  //     print("PreInvoice with ID $preInvoiceId already exists in Hive.");
  //   }
  // }

  Future<void> addPreInvoice(Map<String, dynamic> preInvoiceData) async {
    final preInvoiceId = preInvoiceData['preInvoiceId'];
    if (preInvoicesBox != null &&
        !preInvoicesBox!.values
            .any((invoice) => invoice['preInvoiceId'] == preInvoiceId)) {
      await preInvoicesBox?.add(preInvoiceData);
      _preInvoices.add(preInvoiceData);
      notifyListeners();
    } else {
      print("PreInvoice with ID $preInvoiceId already exists in Hive.");
    }
  }

  void _loadPreInvoicesFromHive() {
    try {
      final List<Map<String, dynamic>> invoices = preInvoicesBox?.values
              .where((invoice) => invoice['status'] != 'cleared')
              .map((dynamic invoice) =>
                  Map<String, dynamic>.from(invoice as Map))
              .toList() ??
          [];
      print('Loaded pre-invoices from Hive: $invoices');
      _preInvoices = invoices;
      notifyListeners();
    } catch (e) {
      print("Error loading pre-invoices from Hive: $e");
    }
  }

  List<dynamic> getPreInvoices() {
    return preInvoicesBox?.values.toList() ?? [];
  }

  void _loadOrdersFromHive() {
    try {
      final dynamic data = _orderBox.get('data');
      print("loadOrdersFromHive");

      if (data != null && data is List<dynamic>) {
        print("orders load1");
        _orders = data.map((dynamicMap) {
          print("orders load2");

          if (dynamicMap is Map<dynamic, dynamic>) {
            print("orders load3");

            return dynamicMap.cast<String, dynamic>();
          } else {
            throw Exception("Invalid data format");
          }
        }).toList();
        notifyListeners();
        print("orders load4");
      }
    } catch (e) {
      print("Error loading orders from Hive: $e");
    }
  }

  void addOrder(Map<String, dynamic> order) {
    order['orderSource'] = orderSource; // Add the order source
    _orders.add(order);
    _saveOrdersToHive();
    notifyListeners();
  }

  // void processIncomingOrder(Map<String, dynamic> orderData) {
  //   if (_orders.any((order) => order['orderId'] == orderData['orderId'])) {
  //     print("Order ${orderData['orderId']} already exists, skipping.");
  //     return;
  //   }
  //   _orders.add(orderData);
  //   _saveOrdersToHive();
  //   notifyListeners();
  // }

  void processIncomingOrder(Map<String, dynamic> orderData) {
    if (orderData['orderId'] == null) {
      orderData['orderId'] =
          const Uuid().v4(); // Or any other unique ID generation logic
    }

    if (_orders.any((order) => order['orderId'] == orderData['orderId'])) {
      print("Order ${orderData['orderId']} already exists, skipping.");
      return;
    }
    _orders.add(orderData);
    _saveOrdersToHive();
    notifyListeners();
  }

  void _saveOrdersToHive() async {
    try {
      await _orderBox.put('data', _orders);
      notifyListeners();
    } catch (e) {
      print("Error saving orders to Hive: $e");
    }
  }

  List<Map<String, dynamic>> getOrdersForseat(int tableNumber, String seat) {
    return _orders
        .where(
            (order) => order['table'] == tableNumber && order['seat'] == seat)
        .toList();
  }

  void convertToInvoice(int tableNumber, String seat) {
    _orders.removeWhere(
        (order) => order['table'] == tableNumber && order['seat'] == seat);
  }

  List<Map<String, dynamic>> getOrdersForTable(int tableNumber) {
    return _orders.where((order) => order['table'] == tableNumber).toList();
  }

  double getTableTotalPrice(int tableNumber) {
    final tableOrders = getOrdersForTable(tableNumber);
    double total = 0.0;
    for (var order in tableOrders) {
      for (var item in order['items']) {
        total += item['price'] * item['quantity'];
      }
    }
    return total;
  }

  double getseatTotalPrice(int tableNumber, String seat) {
    final seatOrders = getOrdersForseat(tableNumber, seat);
    double total = 0.0;
    for (var order in seatOrders) {
      for (var item in order['items']) {
        total += item['price'] * item['quantity'];
      }
    }
    return total;
  }

  bool isseatOccupied(int tableNumber, String seat) {
    final seatOrders = getOrdersForseat(tableNumber, seat);
    return seatOrders.isNotEmpty;
  }

  List<Map<String, dynamic>> getOrdersForseatByName(String seat) {
    return _orders.where((order) => order['seat'] == seat).toList();
  }

  double calculateTotalForseat(String seat) {
    final seatOrders = getOrdersForseatByName(seat);
    double total = 0.0;
    for (var order in seatOrders) {
      for (var item in order['items']) {
        total += item['price'];
      }
    }
    return total;
  }

  List<Map<String, dynamic>> getOrdersForDate(DateTime date) {
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);
    return _orders.where((order) => order['date'] == formattedDate).toList();
  }

  // void clearOrdersForseatAtTable(int tableNumber, String seat) {
  //   _orders.removeWhere(
  //       (order) => order['table'] == tableNumber && order['seat'] == seat);
  //   _saveOrdersToHive();
  //   notifyListeners();
  // }

  void clearOrdersForseatAtTable(int tableNumber, String seat) {
    // Remove orders from local state
    _orders.removeWhere(
        (order) => order['table'] == tableNumber && order['seat'] == seat);

    // Find and delete pre-invoices from Hive
    final keysToDelete = preInvoicesBox?.keys.where((key) {
      final preInvoice = preInvoicesBox?.get(key);
      return preInvoice['tableNumber'] == tableNumber &&
          preInvoice['seat'] == seat;
    }).toList();

    // Delete matching entries from Hive
    if (keysToDelete != null) {
      for (var key in keysToDelete) {
        preInvoicesBox?.delete(key);
      }
    }

    // Save updates to Hive and notify listeners
    _saveOrdersToHive();
    notifyListeners();
  }

  void clearInvoiceLocally(String preInvoiceId) {
    // Clear the invoice and pre-invoice in local state
    _orders.removeWhere((order) => order['preInvoiceId'] == preInvoiceId);
    _preInvoices.removeWhere(
        (preInvoice) => preInvoice['preInvoiceId'] == preInvoiceId);

    // Find and delete the pre-invoice from Hive
    final keyToDelete = preInvoicesBox?.keys.firstWhere((key) {
      final preInvoice = preInvoicesBox?.get(key);
      return preInvoice['preInvoiceId'] == preInvoiceId;
    }, orElse: () => null);

    if (keyToDelete != null) {
      preInvoicesBox?.delete(keyToDelete);
    }

    _saveOrdersToHive(); // Save the updated orders list to Hive
    notifyListeners();
  }

  void loadPreInvoices() {
    final storedPreInvoices = preInvoicesBox?.values.toList();
    _preInvoices = storedPreInvoices!.cast<Map<String, dynamic>>();
    notifyListeners();
  }

  void transferseatWithSeat(
      int fromTable, int toTable, String oldseat, String newSeat) {
    _orders
        .where(
            (order) => order['table'] == fromTable && order['seat'] == oldseat)
        .forEach((order) {
      order['table'] = toTable;
      order['seat'] = newSeat;
    });
    notifyListeners();
  }

  List<String> getAvailableSeats(int tableNumber) {
    final occupiedSeats = _orders
        .where((order) => order['table'] == tableNumber)
        .map((order) => order['seat'])
        .toSet();
    final allSeats =
        List.generate(4, (index) => String.fromCharCode(65 + index));
    return allSeats.where((seat) => !occupiedSeats.contains(seat)).toList();
  }

  List getOccupiedSeats(int tableNumber) {
    return _orders
        .where((order) => order['table'] == tableNumber)
        .map((order) => order['seat'])
        .toList();
  }

  void updateTableTotalPrice(int tableNumber, double totalPrice) {
    final tableOrders =
        _orders.where((order) => order['table'] == tableNumber).toList();
    for (var order in tableOrders) {
      double orderTotal = 0.0;
      for (var item in order['items']) {
        orderTotal += item['price'] * item['quantity'];
      }
      if (order['table'] == tableNumber) {
        order['totalPrice'] = orderTotal;
      }
    }
  }

  void sendUpdateToServer(
      String tokenNo, String action, Map<String, dynamic>? item) {
    final updateData = {
      'action': action,
      'tokenNo': tokenNo,
      if (item != null) 'item': item,
    };
    channel.sink.add(jsonEncode(updateData));
    print("updateData...33");
    print(updateData);
  }

  void listenForServerUpdates() {
    // Listen to the incoming messages from the WebSocket
    channel.stream.listen((message) {
      // Print the raw message received from the server for debugging purposes
      print('Received message from server: $message');

      try {
        // Decode the JSON message
        final updateData = jsonDecode(message);
        print('Decoded update data: $updateData');

        // Extract the action from the decoded data
        final action = updateData['action'];
        print('Action received: $action');

        // Perform actions based on the specified action type
        switch (action) {
          case 'clearOrder':
            _removeOrderById(updateData['orderId']);
            break;

          case 'edit':
          case 'cancelItem':
            _updateOrderItem(updateData['tokenNo'], updateData['item']);
            break;

          case 'orderCanceled':
            _removeOrderById(updateData['orderId']);
            break;

          case 'orderPatched':
            _applyPatchedOrder(
                updateData['orderId'], updateData['updatedData']);
            break;

          case 'clearInvoice':
            _removeInvoiceByPreInvoiceId(updateData['preInvoiceId']);
            break;

          case 'printerDetails':
            _updatePrinterDetails(updateData);
            break;

          case 'preInvoiceGenerated':
            if (updateData.containsKey('preInvoice')) {
              _handlePreInvoiceGeneration(updateData['preInvoice']);
            } else {
              print(
                  'Received preInvoiceGenerated action without preInvoice data.');
            }
            break;

          case 'invoiceGenerated':
            final invoiceData = updateData['invoice'];
            addInvoice(invoiceData);
            clearOrdersForseatAtTable(
                invoiceData['tableNumber'], invoiceData['seat']);
            break;

          case 'clearInvoice':
            final preInvoiceId = updateData['preInvoiceId'];
            clearInvoiceLocally(preInvoiceId);
            break;

          default:
            print('Unknown action received: $action');
        }

        // Notify listeners after handling the action
        notifyListeners();
      } catch (e) {
        // Print any error that occurs during message processing
        print('Error processing message from server: $e');
      }
    }, onError: (error) {
      // Print any errors encountered with the WebSocket connection
      print('Error in WebSocket connection: $error');
    }, onDone: () {
      // Notify when the WebSocket connection is closed
      print('WebSocket connection closed.');
    });
  }

  void addInvoice(Map<String, dynamic> invoice) async {
    var invoiceBox = await Hive.openBox('invoices');
    invoiceBox.add(invoice);
    notifyListeners();
  }

  void removeInvoiceByPreInvoiceId(String preInvoiceId) {
    _orders.removeWhere((order) => order['preInvoiceId'] == preInvoiceId);
    _preInvoices.removeWhere(
        (preInvoice) => preInvoice['preInvoiceId'] == preInvoiceId);
    _saveOrdersToHive(); // Save the updated orders list to Hive
    notifyListeners();
  }

  late KotPrinterProvider printerProvider;

  void _updatePrinterDetails(Map<String, dynamic> printerData) {
    try {
      print("printerDetails13");

      if (printerData['action'] == 'removePrinter') {
        final printerName = printerData['printerName'];
        printerProvider.removePrinterByName(printerName);
      } else {
        print("printerDetails14");

        final printer = Printer(
          name: printerData['printerName'] ?? printerData['name'] ?? 'Unknown',
          ipAddress: printerData['ipAddress'] ?? 'Unknown',
          type: printerData['type'] ?? 'Unknown',
          items: List<String>.from(
              printerData['items'] ?? printerData['assignedItems'] ?? []),
        );

        final existingPrinterIndex =
            printerProvider.printers.indexWhere((p) => p.name == printer.name);

        if (existingPrinterIndex != -1) {
          printerProvider.updatePrinter(printer);
        } else {
          print("printerDetails15");

          printerProvider.addPrinter(printer);
        }
      }

      printerProvider.notifyListeners();
    } catch (e) {
      print('Error updating printer details: $e');
    }
  }

  void _removeOrderById(String? orderId) {
    if (orderId != null) {
      _orders.removeWhere((order) => order['orderId'] == orderId);
      print('Order with orderId $orderId has been removed.');
    }
  }

  void _removeInvoiceByPreInvoiceId(String preInvoiceId) {
    _orders.removeWhere((order) => order['preInvoiceId'] == preInvoiceId);
    _preInvoices.removeWhere(
        (preInvoice) => preInvoice['preInvoiceId'] == preInvoiceId);
    _saveOrdersToHive(); // Save the updated orders list to Hive
    notifyListeners();
  }

  void _updateOrderItem(String tokenNo, Map<String, dynamic> updatedItem) {
    for (var order in _orders.where((order) => order['tokenNo'] == tokenNo)) {
      final itemIndex =
          order['items'].indexWhere((i) => i['id'] == updatedItem['id']);
      if (itemIndex != -1) {
        order['items']
            [itemIndex] = {...order['items'][itemIndex], ...updatedItem};
      }
    }
  }

  void _handlePreInvoiceGeneration(Map<String, dynamic> preInvoiceData) {
    print("preInvoice received from server..");

    if (preInvoiceData.containsKey('preInvoiceId')) {
      final preInvoiceId = preInvoiceData['preInvoiceId'];
      print("preInvoiceId: $preInvoiceId");

      if (preInvoicesBox != null &&
          !preInvoicesBox!.values
              .any((invoice) => invoice['preInvoiceId'] == preInvoiceId)) {
        preInvoicesBox?.add(preInvoiceData);
        _preInvoices.add(preInvoiceData);
        notifyListeners();
      } else {
        print("PreInvoice with ID $preInvoiceId already exists in Hive.");
      }
    } else {
      print("Invalid preInvoice data received, skipping...");
    }
  }

  void cancelOrderByOrderId(String orderId) {
    print("Canceling order with ID: $orderId");

    for (var order in _orders) {
      if (order.containsKey('orderId') && order['orderId'] == orderId) {
        // Check if order is not null and contains the key 'orderId'
        order['isCanceled'] = true;

        // Notify server to cancel the order
        sendUpdateToServer(
          order['tokenNo']?.toString() ?? '', // Ensure tokenNo is not null
          'cancelOrder',
          {'orderId': orderId},
        );

        _saveOrdersToHive();
        notifyListeners();
        break;
      } else {
        print("Error: Order is null or does not contain orderId");
      }
    }
  }

  void patchOrder(
      String tokenNo, String orderId, Map<String, dynamic> updatedData) {
    final patchData = {
      'action': 'patchOrder',
      'tokenNo': tokenNo,
      'orderId': orderId,
      'updatedData': updatedData,
    };
    print("patchData....33");
    print(patchData);

    sendUpdateToServer(tokenNo, 'patchOrder', patchData);
  }

  void _applyPatchedOrder(String orderId, Map<String, dynamic> updatedData) {
    for (var order in _orders) {
      if (order['orderId'] == orderId) {
        updatedData.forEach((key, value) {
          order[key] = value; // Update the local order with the patched data
        });
        _saveOrdersToHive();
        notifyListeners();
        break;
      }
    }
  }
}
