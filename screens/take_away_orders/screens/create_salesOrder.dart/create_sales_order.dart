import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yenposapp/Global/custom_textWidgets.dart';
import 'package:yenposapp/screens/take_away_orders/screens/create_salesOrder.dart/numeric_Calculator.dart';
import '../../take_away_providers/cartProvider.dart';
import '../../take_away_providers/detailsProvider.dart';

import 'package:yenposapp/screens/take_away_orders/screens/create_salesOrder.dart/salesorder_Customerdetails.dart';

import '../../take_away_providers/salesOrder_provider.dart';

import '../../globals.dart' as globals;

class SalesOrderScreen extends StatefulWidget {
  @override
  _SalesOrderScreenState createState() => _SalesOrderScreenState();
}

class _SalesOrderScreenState extends State<SalesOrderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final detailsProvider =
          Provider.of<DetailsProvider>(context, listen: false);
      detailsProvider.fetchVariances();
      detailsProvider.fetchEmployeeNames();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final detailsProvider = Provider.of<DetailsProvider>(context);
    final salesOrderProvider = Provider.of<SaleOrderProvider>(context);
    List<bool> isSelected = [true, false];
    // bool isHeldOrderActive = false;
    // detailsProvider.fetchVariances();
    // detailsProvider.fetchEmployeeNames();

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed('/all-orders');
        return false; // Prevent the default back action
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment:
                MainAxisAlignment.start, // Align title to the left
            children: [
              Text(
                'Create Orders',
                style: TextStyle(color: Colors.black), // Customize text style
              ),
            ],
          ),
          centerTitle: false, // Ensures the title stays on the left
          flexibleSpace: Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the buttons
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Refresh action
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
                    // Refresh action
                    Navigator.of(context).pushNamed('/all-orders');
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0), // Small curve
                    ),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 2,
                  ),
                  child: Text('All Orders'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    // Refresh action
                    // Navigator.pushReplacement(
                    //   context,
                    //   MaterialPageRoute(
                    //       builder: (context) => SalesOrderScreen()),
                    // );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0), // Small curve
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    elevation: 2,
                  ),
                  child: Text('Create Order'),
                ),
                SizedBox(width: 10),
              ],
            ),
          ),
          toolbarHeight: kToolbarHeight, // Default height for proper layout
        ),
        body: Row(
          // Create a row to divide the screen
          children: [
            // Left side content
            Expanded(
              flex: 3, // Left side takes more space
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search field and item list
                    TextField(
                      controller: salesOrderProvider.searchController,
                      decoration: InputDecoration(
                        labelText: 'Search Item',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              salesOrderProvider.searchController.clear();
                              salesOrderProvider.filteredItems = [];
                            });
                          },
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty) {
                            salesOrderProvider.filteredItems = [];
                          } else {
                            salesOrderProvider.filteredItems =
                                detailsProvider.variances.where((item) {
                              return item['varianceName']
                                  .toLowerCase()
                                  .contains(value.toLowerCase());
                            }).toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    salesOrderProvider.filteredItems.isNotEmpty
                        ? Expanded(
                            child: ListView.builder(
                              itemCount:
                                  salesOrderProvider.filteredItems.length,
                              itemBuilder: (context, index) {
                                final selectedItem =
                                    salesOrderProvider.filteredItems[index];

                                return ListTile(
                                  title: Text(selectedItem['varianceName']),
                                  onTap: () {
                                    setState(() {
                                      if (selectedItem['varianceUom'] ==
                                          'Kgs') {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return NumericCalculator(
                                              onValueSelected: (weight) {
                                                cartProvider.addItemToCart(
                                                  CartItem(
                                                    name: selectedItem[
                                                            'varianceName'] ??
                                                        '',
                                                    pricePerKg: selectedItem[
                                                            'variancePrice'] ??
                                                        0,
                                                    uom: selectedItem[
                                                            'varianceUom'] ??
                                                        0,
                                                    weight: weight,
                                                    quantity: 1,
                                                    tax: selectedItem['tax'] ??
                                                        0,
                                                    itemCode: selectedItem[
                                                            'varianceitemCode'] ??
                                                        '',
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        );
                                      } else {
                                        cartProvider.addItemToCart(
                                          CartItem(
                                            name:
                                                selectedItem['varianceName'] ??
                                                    '',
                                            pricePerKg:
                                                selectedItem['variancePrice'] ??
                                                    0,
                                            uom: selectedItem['varianceUom'] ??
                                                '',
                                            quantity: 1,
                                            tax: selectedItem['varianceTax'] ??
                                                0,
                                            itemCode: selectedItem[
                                                    'varianceitemCode'] ??
                                                '',
                                            weight:
                                                0.0, // Default weight for non-Kg items
                                          ),
                                        );
                                      }
                                      salesOrderProvider.searchController
                                          .clear();
                                      salesOrderProvider.filteredItems = [];
                                    });
                                  },
                                );
                              },
                            ),
                          )
                        : Container(),
                    const Text(
                      'Cart Details',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Divider(),
                    Flexible(
                      child: ListView.builder(
                        itemCount: globals.cartItems.length,
                        itemBuilder: (context, index) {
                          final item = globals.cartItems[index];
                          return Dismissible(
                            key: Key(item.name),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              cartProvider.removeItemFromCart(index);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${item.name} removed from cart'),
                                ),
                              );
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 15.0,
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: item.uom == 'Kgs'
                                  ? Text(
                                      'Weight: ${item.weight.toStringAsFixed(1)} * Rs.${item.pricePerKg}/-',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    )
                                  : Text(
                                      '${item.uom} - ${item.quantity} * Rs.${item.pricePerKg}/-',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    width: 30,
                                    height: 30,
                                    child: IconButton(
                                      icon: const Icon(Icons.remove,
                                          color: Colors.white),
                                      iconSize: 18,
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        // if (item.quantity > 0) {
                                        //   if (item.quantity == 1) {
                                        //     cartProvider
                                        //         .removeItemFromCart(index);
                                        //   } else {
                                        //     cartProvider.updateQuantity(
                                        //         index, item.quantity - 1);
                                        //   }
                                        // }
                                        if (item.quantity > 0) {
                                          if (item.quantity == 1) {
                                            cartProvider
                                                .removeItemFromCart(index);
                                          } else {
                                            cartProvider.updateQuantity(
                                                index, item.quantity - 1);
                                          }
                                        }
                                        cartProvider.calculateSubtotal();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        cartProvider.showQuantityDialog(
                                          context,
                                          index,
                                          item.quantity,
                                          item.uom,
                                        );
                                      });
                                    },
                                    child: Text(
                                      item.uom == 'Kgs'
                                          ? '${item.quantity}'
                                          : '${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    width: 30,
                                    height: 30,
                                    child: IconButton(
                                      icon: const Icon(Icons.add,
                                          color: Colors.white),
                                      iconSize: 18,
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        cartProvider.updateQuantity(
                                            index, item.quantity + 1);
                                        cartProvider.calculateSubtotal();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.uom == 'Kgs'
                                        ? 'Rs.${(item.weight * item.quantity * item.pricePerKg).toStringAsFixed(2)}/-'
                                        : 'Rs.${(item.quantity * item.pricePerKg).toStringAsFixed(2)}/-',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: globals.cartItems.isNotEmpty
                              ? () {
                                  cartProvider.clearCart();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Cart cleared')),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: globals.cartItems.isNotEmpty
                                  ? Colors.red
                                  : Colors.grey),
                          child: const Text('Clear Cart',
                              style: TextStyle(color: Colors.white)),
                        ),

                        // ElevatedButton(
                        //   onPressed: globals.cartItems.isNotEmpty
                        //       ? () {
                        //           Navigator.push(
                        //             context,
                        //             MaterialPageRoute(
                        //                 builder: (context) =>
                        //                     CustomerDetails()),
                        //           );
                        //         }
                        //       : null,
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: globals.cartItems.isNotEmpty
                        //         ? Colors.green
                        //         : Colors.grey,
                        //   ),
                        //   child: const Text('Place Order',
                        //       style: TextStyle(color: Colors.white)),
                        // ),
                        CustomText(
                          // text:
                          //     ' TOTAL AMOUNT ₹${cartProvider.calculateSubtotal().toStringAsFixed(0)}',
                          text:
                              ' TOTAL AMOUNT ₹${cartProvider.getTotalAmount()}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Right side (Customer Details) separated by a Divider
            const VerticalDivider(
              thickness: 1,
              width: 1,
              color: Colors.black,
            ),
            Expanded(
              flex: 2, // Right side takes less space
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CustomerDetails(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
