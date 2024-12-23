import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yenposapp/Global/advance-dialog.dart';
import 'package:yenposapp/Global/custom_button_reuse.dart';
import 'package:yenposapp/Global/custom_colors.dart';
import 'package:yenposapp/Global/custom_sized_box.dart';
import 'package:yenposapp/Global/flutter-audio-player-alt.dart';
import 'package:yenposapp/Global/ordermodifydialog.dart';
// import 'package:yenposapp/Global/ordermodifydialog.dart';
import 'package:yenposapp/Global/photoScreen.dart';
import 'package:yenposapp/Global/qrcodeScreen.dart';

// import 'package:yenposapp/screens/regular_mode_page/widget/custom_reusable_widget/reusesable_variance_dialoge.dart';
// import 'package:yenposapp/screens/regular_mode_page/widget/custom_reusable_widget/reusesable_variance_dialoge.dart';
import 'package:yenposapp/screens/take_away_orders/screens/all_orders_page/services/get_sales_order_service.dart';
import 'package:yenposapp/screens/take_away_orders/screens/create_salesOrder.dart/create_sales_order.dart';
import 'package:yenposapp/screens/take_away_orders/screens/model/sales_order_model.dart';
import 'package:collection/collection.dart';

import '../../take_away_print/currentOrderPrint.dart';
import '../../take_away_providers/cartProvider.dart';

class AllOrdersPage extends StatefulWidget {
  const AllOrdersPage({Key? key}) : super(key: key);

  @override
  _AllOrdersPageState createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends State<AllOrdersPage> {
  int? _selectedTransactionIndex;
  TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isAddingOrder = false;
  final Map<String, dynamic> mixbox = {};
  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // void _onSearchChanged(String query, ApiServiceSalesOrderProvider apiService) {
  //   if (_debounce?.isActive ?? false) _debounce!.cancel();
  //   _debounce = Timer(const Duration(milliseconds: 300), () {
  //     apiService.searchAllOrders(query);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final apiService = context.watch<ApiServiceSalesOrderProvider>();
    final filteredSalesOrders = apiService.filteredAllSalesOrders;
    final cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildOrderList(
                filteredSalesOrders, apiService, _selectedTransactionIndex),
          ),
          const VerticalDivider(),
          Expanded(
            flex: 2,
            child: _buildOrderDetails(filteredSalesOrders,
                _selectedTransactionIndex, apiService, cartProvider),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start, // Align title to the left
        children: [
          Text(
            'All Orders',
            style: TextStyle(color: Colors.black), // Customize text style
          ),
        ],
      ),
      centerTitle: false, // Ensures the title stays on the left
      flexibleSpace: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(), // Adjust spacing
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the buttons
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/current-orders');
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0), // Small curve
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 2,
                ),
                child: Text('Current Order'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Handle "All Orders" action if needed
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0), // Small curve
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  elevation: 2,
                ),
                child: Text('All Orders'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SalesOrderScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0), // Small curve
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 2,
                ),
                child: Text('Create Order'),
              ),
            ],
          ),
        ),
      ),
      toolbarHeight: kToolbarHeight * 1, // Increase height for buttons layout
    );
  }

  Widget _buildOrderList(
    List<SalesOrder> filteredSalesOrders,
    ApiServiceSalesOrderProvider apiService,
    int? selectedIndex,
  ) {
    final String todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

    // Group orders by date
    final ordersByDate = groupBy(filteredSalesOrders, (SalesOrder order) {
      return order.deliveryDate;
    });

    final sortedDates = ordersByDate.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('dd-MM-yyyy').parse(a);
        final dateB = DateFormat('dd-MM-yyyy').parse(b);
        return dateA.compareTo(dateB);
      });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: apiService.searchAllOrders,
                decoration: InputDecoration(
                  hintText: 'Search orders',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScannerScreen(
                            onScanComplete: (scannedCode) {
                              debugPrint("Scanned code received: $scannedCode");
                              // Perform desired action with the scanned code
                              apiService.searchAllOrders(scannedCode);
                            },
                          ),
                        ),
                      );
                    },
                    tooltip: 'Scan QR/Barcode',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Date Range Picker
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          apiService.setStartDate(selectedDate);
                          //  apiService.fetchAllOrders();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8.0), // Small curve
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                      ),
                      child: Text(
                        apiService.startDate != null
                            ? DateFormat('dd-MM-yyyy')
                                .format(apiService.startDate!)
                            : 'Start Date',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          apiService.setEndDate(selectedDate);
                          apiService.fetchAllOrders();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8.0), // Small curve
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                      ),
                      child: Text(
                        apiService.endDate != null
                            ? DateFormat('dd-MM-yyyy')
                                .format(apiService.endDate!)
                            : 'End Date',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {},
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8.0), // Small curve
                        ),
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 2,
                      ),
                      child: Text('Canceled'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: apiService.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ordersByDate.isEmpty
                  ? const Center(child: Text("No orders available"))
                  : ListView.builder(
                      itemCount: sortedDates.length,
                      itemBuilder: (context, index) {
                        final date = sortedDates[index];
                        final orders = ordersByDate[date]!;
                        final displayDate = date == todayDate ? "Today" : date;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: Text(
                                displayDate,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...orders.map((order) => ListTile(
                                  title: Text(order.customerName),
                                  subtitle: Text(order.salesOrderId.length > 5
                                      ? order.salesOrderId.substring(
                                          order.salesOrderId.length - 5)
                                      : order.salesOrderId),
                                  trailing: Text(order.status),
                                  selected: selectedIndex == index,
                                  onTap: () => setState(() {
                                    _selectedTransactionIndex =
                                        filteredSalesOrders.indexOf(order);
                                  }),
                                )),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // Helper Functions

  Widget _buildOrderDetails(
      List<SalesOrder> filteredSalesOrders,
      int? selectedIndex,
      ApiServiceSalesOrderProvider apiService,
      CartProvider cartProvider) {
    if (selectedIndex == null || filteredSalesOrders.isEmpty) {
      return _buildEmptyOrderState();
    }

    final salesOrder = filteredSalesOrders[selectedIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(salesOrder),
          Divider(color: Colors.grey[400]),
          _buildOrderItemsList(salesOrder),
          _buildOrderSummary(salesOrder),
          _buildOrderActions(context, salesOrder, apiService, cartProvider),
        ],
      ),
    );
  }

  Widget _buildEmptyOrderState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 100, color: const Color.fromARGB(255, 97, 220, 236)),
          SizedBox(height: 20),
          Text("Select an order to view details",
              style: TextStyle(color: Colors.grey, fontSize: 18)),
        ],
      ),
    );
  }

  // Widget _buildOrderHeader(SalesOrder salesOrder) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text('Payment Type',
  //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //           Text(salesOrder.paymentType, style: TextStyle(fontSize: 16)),
  //         ],
  //       ),
  //       Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text('Order ID',
  //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //           Text(
  //             salesOrder.salesOrderId.length > 5
  //                 ? salesOrder.salesOrderId
  //                     .substring(salesOrder.salesOrderId.length - 5)
  //                 : salesOrder.salesOrderId,
  //             style: TextStyle(fontSize: 16),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _buildOrderHeader(SalesOrder salesOrder) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Column - Payment Type
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(salesOrder.paymentType, style: TextStyle(fontSize: 16)),
          ],
        ),
        Row(
          children: [
            // Cancel Elevated Button
            // ElevatedButton.icon(
            //   onPressed: () async {
            //     // Add your cancel order functionality here
            //     final result = await AdvanceAmountDialog.show(context);
            //     if (result != null) {
            //       print('Remarks: ${result['remarks']}');
            //       print('Amount: ${result['amount']}');
            //     }
            //     print('Cancel Order');
            //   },
            //   icon: Icon(Icons.cancel, color: Colors.white),
            //   label:
            //       Text('Cancel Order', style: TextStyle(color: Colors.white)),
            //   style: ElevatedButton.styleFrom(
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(8.0), // Small curve
            //     ),
            //     backgroundColor: Colors.red,
            //     foregroundColor: Colors.white,
            //     elevation: 2,
            //   ),
            // ),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await AdvanceAmountDialog.show(
                  context,
                  advanceAmount:
                      salesOrder.advanceAmount, // Pass the advance amount here
                );
                if (result != null) {
                  print('Remarks: ${result['remarks']}');
                  print('SalesPerson: ${result['salesPerson']}');
                }
              },
              icon: Icon(Icons.cancel, color: Colors.white),
              label:
                  Text('Cancel Order', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Small curve
                ),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 2,
              ),
            ),

            SizedBox(width: 10), // Add space between the buttons

            // Modify Elevated Button
            // ElevatedButton.icon(
            //   onPressed: () {
            //     // Add your modify order functionality here
            //     print('Modify Order');
            //   },
            //   icon: Icon(Icons.edit, color: Colors.white),
            //   label: Text('Add Orders', style: TextStyle(color: Colors.white)),
            //   style: ElevatedButton.styleFrom(
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(8.0), // Small curve
            //     ),
            //     backgroundColor: Colors.yellow,
            //     foregroundColor: Colors.white,
            //     elevation: 2,
            //   ),
            //   // child: Text('Current Order'),
            // ),
            ElevatedButton.icon(
              onPressed: () {
                // Toggle add order mode
                // setState(() {
                //   _isAddingOrder = true;
                // });
                List<Variance> itemVariances = salesOrder.items.map((item) {
                  return Variance(
                    varianceName: item.itemName,
                    varianceDefaultPrice: item.price,
                  );
                }).toList();

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return OrderModifyDialog(
                      itemName: 'Add Items', // Pass the item name
                      variances: itemVariances, // Pass the list of variances
                      // mixbox: mixbox,
                      onAdd: () {
                        // Handle the add action
                        print("Item added");
                      },
                      // mixbox: mixbox, // Pass the mixbox data
                    );
                  },
                );
              },
              icon: Icon(Icons.edit, color: Colors.white),
              label:
                  Text('Modify Orders', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Small curve
                ),
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.white,
                elevation: 2,
              ),
            ),
          ],
        ),
        // Middle Column - Order ID
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Order ID',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              salesOrder.salesOrderId.length > 5
                  ? salesOrder.salesOrderId
                      .substring(salesOrder.salesOrderId.length - 5)
                  : salesOrder.salesOrderId,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),

        // Right Column - Cancel and Modify Icons
      ],
    );
  }

  Widget _buildOrderItemsList(SalesOrder salesOrder) {
    return Expanded(
      child: ListView.separated(
        itemCount: salesOrder.itemName.length,
        itemBuilder: (context, index) {
          return _buildOrderItemTile(salesOrder, index);
        },
        separatorBuilder: (context, index) => SizedBox(height: 10),
      ),
    );
  }

  Widget _buildOrderItemTile(SalesOrder salesOrder, int index) {
    final isKg = salesOrder.uom[index].toLowerCase() == 'kg' ||
        salesOrder.uom[index].toLowerCase() == 'kgs';
    final quantity = isKg
        ? salesOrder.qty[index].toStringAsFixed(3)
        : salesOrder.qty[index].toStringAsFixed(0);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(salesOrder.itemName[index],
          style: TextStyle(fontSize: 16, color: Colors.grey)),
      subtitle: Text(
        salesOrder.uom[index] != 'Kgs'
            ? ' $quantity ${salesOrder.uom[index]} x ${salesOrder.price[index]} RS'
            : '${salesOrder.weight[index]} ${salesOrder.uom[index]}   x ${salesOrder.price[index]} RS',
      ),
      trailing: Text('₹${salesOrder.amount[index].toStringAsFixed(2)}',
          style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildOrderSummary(SalesOrder salesOrder) {
    return Align(
      alignment: Alignment.centerRight, // Align summary to the right
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end, // Align text to the right
        mainAxisSize: MainAxisSize.min, // Minimize height to fit content
        children: [
          // if (_isAddingOrder)
          //   ElevatedButton(
          //     onPressed: () {},
          //     style: ElevatedButton.styleFrom(
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8.0), // Small curve
          //       ),
          //       backgroundColor: Colors.blue,
          //       foregroundColor: Colors.white,
          //       elevation: 2,
          //     ),
          //     child: Text('Add Items'),
          //   ),
          if (salesOrder.discount > 0)
            Text(
              'Discount: ${salesOrder.discountAmount}%',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          if (salesOrder.customCharge > 0)
            Text(
              'Custom Charge: ₹${salesOrder.customCharge.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          Text(
            'Total Amount: ₹${salesOrder.totalAmount.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'Advance Amount: ₹${salesOrder.advanceAmount.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderActions(BuildContext context, SalesOrder salesOrder,
      ApiServiceSalesOrderProvider apiService, CartProvider cartProvider) {
    return Column(
      children: [
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: 300, maxHeight: 400),
                child: AudioPlayerWidget(customId: salesOrder.salesOrderId),
              ),
            ),
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: 250, maxHeight: 100),
                child: PhotosScreen(customId: salesOrder.salesOrderId),
              ),
            ),
            CustomButton(
              text: 'Pay ₹ ${salesOrder.balanceAmount.toStringAsFixed(2)}',
              onPressed: salesOrder.status != "SalesOrder Completed"
                  ? () => {_showPaymentDialog(context, salesOrder)}
                  : () {},
              backgroundColor: salesOrder.status != "SalesOrder Completed"
                  ? CustomColors.primaryColor
                  : Colors.grey,
              textColor: CustomColors.whiteColor,
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 22),
            ),
            // SizedBox(
            //   width: 10,
            // ),
            // CustomButton(
            //   text: 'Credit',
            //   onPressed: () => _showConfirmationDialog(context,
            //       title: "Confirm Credit",
            //       message: "Are you sure you want to proceed with credit?",
            //       // onConfirm: () => _showCreditDialog(context, salesOrder),
            //       onConfirm: () {
            //     apiService.showCreditDialog(salesOrder.salesOrderId, context);
            //     apiService.fetchAllOrders();
            //   }),
            //   backgroundColor: CustomColors.primaryColor,
            //   textColor: CustomColors.whiteColor,
            //   padding: EdgeInsets.symmetric(horizontal: 25, vertical: 11),
            // ),
          ],
        ),
      ],
    );
  }

  void _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, SalesOrder salesOrder) {
    double totalAmount = salesOrder.balanceAmount;
    if (totalAmount != 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: CustomSizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: OrderManagementPayandPrint(
                  totalAmount: totalAmount,
                  holdBillId: '',
                  orderId: salesOrder.salesOrderId,
                  employee: salesOrder.employeeName,
                  discount: salesOrder.discount,
                  customerNumber: salesOrder.customerNumber,
                  salesOrder: salesOrder),
            ),
          );
        },
      );
    }
  }
}
