// import 'dart:math';
// import 'dart:typed_data';
// import 'package:esc_pos_printer/esc_pos_printer.dart';
// import 'package:esc_pos_utils/esc_pos_utils.dart'; // Import this for PaperSize, PosStyles, etc.
// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'dart:developer' as developer;
// import '../../../data/global_data_manager.dart';

// // import '../../regular_mode_page/provider/cart_page_provider.dart';
// import '../providers/cartProvider.dart';
// import 'customposcolumn.dart';

// class ReceiptPrinter {
//   final TextEditingController employeeNumberController;
//   final TextEditingController customerNumberController;
//   final TextEditingController discountController;
//   final TextEditingController customChargeController;
//   final String selectedPaymentOptionValue;
//   final double totalAmount;
//   final BuildContext context;
//   final TextEditingController customAmountController;
//   final String selectedPaymentOption;
//   final Function saveInvoiceToHiveAndPrint;
//   ReceiptPrinter({
//     required this.employeeNumberController,
//     required this.customerNumberController,
//     required this.discountController,
//     required this.customChargeController,
//     required this.selectedPaymentOptionValue,
//     required this.totalAmount,
//     required this.context,
//     required this.customAmountController,
//     required this.selectedPaymentOption,
//     required this.saveInvoiceToHiveAndPrint,
//   });

//   Future<void> printReceiptDetails() async {
//     String employeeNumber = employeeNumberController.text ?? '';
//     String customerNumber = customerNumberController.text ?? '';
//     String paymentAmount;
//     DateTime now = DateTime.now();
//     String formattedDate = DateFormat('dd-MM-yyyy').format(now);
//     String formattedTime =
//         DateFormat('hh:mm a').format(now); // 12-hour format with AM/PM

//     if (selectedPaymentOption == 'Cash: Custom' &&
//         customAmountController.text.isNotEmpty) {
//       paymentAmount =
//           'Rs ${customAmountController.text}'; // Ensuring single currency symbol
//     } else if (selectedPaymentOption.contains('')) {
//       paymentAmount =
//           'Rs ${selectedPaymentOption.split(': ').last.replaceAll('', '').trim()}';
//     } else {
//       paymentAmount = 'Rs ${totalAmount.toStringAsFixed(0) ?? '0'}';
//     }

//     var cartProvider = Provider.of<CartProvider>(context, listen: false);
//     var cartItems = cartProvider.currentSaleItems ?? [];
//     double discountPercentage = cartProvider.discountPercentage;
//     double customCharge = cartProvider.customCharge;
//     double discountAmount =
//         cartProvider.calculateTotal() * discountPercentage / 100;
//     // Fetch the settings
//     final settings = GlobalDataManager().billReceiptSettings;
//     final printerProvider =
//         Provider.of<PrinterProvider>(context, listen: false);

//     String printerIp = printerProvider.getOverallPrinterIp().toString();
//     ;
//     print(printerIp);
//     final profile = await CapabilityProfile.load();
//     final printer = NetworkPrinter(PaperSize.mm80, profile);

//     final PosPrintResult res = await printer.connect(printerIp, port: 9100);
//     // Check if there are any hold bills in the cart
//     bool hasHoldBills =
//         cartProvider.currentSaleItems.any((item) => item['status'] == 'hold');

//     if (hasHoldBills) {
//       developer.log('Yes, there are hold bills in the cart.',
//           name: 'PrintReceiptLog');
//     } else {
//       developer.log('No hold bills found in the cart.',
//           name: 'PrintReceiptLog');
//     }
//     if (res == PosPrintResult.success) {
//       List<int> bytes = [];
//       final generator = Generator(PaperSize.mm80, profile);

//       bytes += generator.row([
//         createPosColumn(
//             width: 12,
//             text: '',
//             styles: createPosStyles(
//               align: PosAlign.center,
//               height: PosTextSize.size6,
//               width: PosTextSize.size6,
//               codeTable: 'CP1252',
//             )),
//       ]);
//       bytes += generator.row([
//         createPosColumn(
//             width: 12,
//             text: 'BestMummy',
//             styles: createPosStyles(
//               align: PosAlign.center,
//               height: PosTextSize.size1,
//               width: PosTextSize.size1,
//               codeTable: 'CP1252',
//             )),
//       ]);
//       bytes += generator.row([
//         createPosColumn(
//             width: 12,
//             text: 'Sweets & Cakes',
//             styles: createPosStyles(
//               align: PosAlign.center,
//               height: PosTextSize.size1,
//               width: PosTextSize.size1,
//               codeTable: 'CP1252',
//             )),
//       ]);
//       bytes += generator.feed(1);

//       //cartProvider.calculateTotal().toStringAsFixed(2)}
//       // Sales Invoice details
//       // bytes += generator.row([
//       //   createPosColumn(
//       //       width: 12,
//       //       text: 'Rs ${cartProvider.calculateTotal().toStringAsFixed(0)}',
//       //       styles: createPosStyles(
//       //         align: PosAlign.center,
//       //         codeTable: 'CP1252',
//       //         height: PosTextSize.size3,
//       //         width: PosTextSize.size3,
//       //       )),
//       // ]);
//       bytes += generator.feed(1);
//       bytes += generator.row([
//         createPosColumn(
//             width: 12,
//             text: 'Sales Invoice',
//             styles: createPosStyles(
//               align: PosAlign.center,
//               codeTable: 'CP1252',
//               height: PosTextSize.size1,
//               width: PosTextSize.size1,
//             )),
//       ]);
//       bytes += generator.feed(1);

//       // Add formatted date and time
//       bytes += generator.row([
//         createPosColumn(
//             width: 6,
//             text: 'Date: $formattedDate',
//             styles: createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
//         createPosColumn(
//             width: 6,
//             text: 'Time: $formattedTime',
//             styles:
//                 createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
//       ]);

//       bytes += generator.feed(1);

//       bytes += generator.row([
//         createPosColumn(
//             width: 6,
//             text: 'Branch : Aranmanai',
//             styles: createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
//         createPosColumn(
//             width: 6,
//             text: 'Bill No : 102',
//             styles:
//                 createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
//       ]);

//       bytes += generator.feed(1);

// // Print Sales Person and Customer Number on the same line
//       bytes += generator.row([
//         createPosColumn(
//             width: 6,
//             text: 'Sales Person : test',
//             styles: createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
//         createPosColumn(
//             width: 6,
//             text: 'Customer No: $customerNumber',
//             styles:
//                 createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
//       ]);

//       bytes += generator.feed(1);

//       // Add headers for S.No, Item, Price, Qty, and Amount
//       bytes += generator.row([
//         createPosColumn(
//             width: 1,
//             text: 'S.No',
//             styles: createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
//         createPosColumn(
//             width: 5,
//             text: 'Item',
//             styles: createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
//         createPosColumn(
//             width: 2,
//             text: '',
//             styles:
//                 createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
//         createPosColumn(
//             width: 1,
//             text: '',
//             styles:
//                 createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
//         createPosColumn(
//             width: 3,
//             text: 'Amount',
//             styles:
//                 createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
//       ]);

//       bytes += generator.feed(1);
//       double totalSGST = 0.0;
//       double totalCGST = 0.0;
//       double taxVaule = 0.0;
//       Map<double, double> sgstMap = {};
//       Map<double, double> cgstMap = {};

//       // Process each item
//       for (var item in cartItems) {
//         // Assuming tax is fetched as dynamic or int, ensure it's treated as double
//         double taxRate = (item['itemData']['tax'] as num)
//             .toDouble(); // num can be both int and double
//         double itemTotal = cartProvider
//             .calculateItemTotal(item)
//             .toDouble(); // Ensure itemTotal is a double

//         double itemTax = itemTotal * (taxRate / 100);
//         double itemSGST = itemTax / 2;
//         double itemCGST = itemSGST;

//         // Update the maps with doubles
//         sgstMap[taxRate / 2] = (sgstMap[taxRate / 2] ?? 0.0) + itemSGST;
//         cgstMap[taxRate / 2] = (cgstMap[taxRate / 2] ?? 0.0) + itemCGST;
//       }

//       // Adding cart items with item name, quantity, and price in the desired format
//       for (int i = 0; i < cartItems.length; i++) {
//         final item = cartItems[i];

//         final String itemName = item['itemData']['itemName'] ?? 'N/A';
//         final String varianceName =
//             item['varianceData']['varianceName'] ?? 'N/A';
//         final double price =
//             item['varianceData']['variance_Defaultprice']?.toDouble() ?? 0.0;
//         final double weight = (item['weight'] ?? 0.0).toDouble();
//         final double qty = (item['quantity'] as num).toDouble() ?? 0.0;
//         final double amount = cartProvider.calculateItemTotal(item);
//         final double tax = (item['itemData']['tax'] as num).toDouble();
//         final String uom = item['varianceData']['variance_Uom'] ?? 'N/A';
//         String quantityDisplay = cartProvider.buildQuantityPriceDisplay(item);
//         // Get the tax percentage for the item
//         final double itemTotal = cartProvider.calculateItemTotal(item);
//         double taxPercentage = (item['itemData']['tax'] as num).toDouble();
//         // Calculate SGST and CGST
//         double itemTax = itemTotal * (taxPercentage / 100);
//         double itemSGST = itemTax / 2;
//         double itemCGST = itemTax / 2;

//         totalSGST = itemSGST;
//         totalCGST = itemCGST;
//         taxVaule = taxPercentage; // Sum up item total + taxes

//         // Log the quantityDisplay to the console
//         developer.log('Printing Receipt...');
//         developer.log('HiveInvoiceId:');
//         developer.log('Item: $itemName');
//         developer.log('Variance: $varianceName');
//         developer.log('Price: Rs ${price.toStringAsFixed(0)}');
//         developer.log('Weight: $weight');
//         developer.log('Quantity: $quantityDisplay');
//         developer.log('Qty: $qty');
//         developer.log('Amount: Rs ${amount.toStringAsFixed(0)}');
//         developer.log('Tax: $tax%');
//         developer.log('UOM: $uom');
//         developer.log('users: ');
//         developer.log('totalAmount: ');
//         developer.log('totalAmount2: ');
//         developer.log('totalAmount3: ');
//         developer.log('status: Active ');
//         developer.log('branchid:');
//         developer.log('branchName:');
//         developer.log('cash: ');
//         developer.log('upi:');
//         developer.log('card:');
//         developer.log('others:');
//         developer.log('invoiceDate:');
//         developer.log('invoiceTime:');
//         developer.log('invoiceNumber:');
//         developer.log('branchid:');
//         developer.log('branchName:');
//         developer.log('shiftId:');
//         developer.log('shiftNumber:');
//         developer.log('deviceNumber:');
//         developer.log('Employee Number: $employeeNumber');
//         developer.log('Customer Number: $customerNumber');
//         developer.log('Discount: ${discountController.text}%');
//         developer.log('Custom Charge: Rs ${customChargeController.text}');
//         developer.log('Selected Payment: $selectedPaymentOption');
//         developer.log('Payment Amount: $paymentAmount');

//         // Save the data to Hive

//         // Open the Hive box
//         var box = await Hive.openBox('invoiceBox');

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Invoice  saved successfully')),
//         );
//         saveInvoiceToHiveAndPrint();

//         List<String> itemNameLines =
//             splitText(item['varianceData']['varianceName'] ?? '', 15);

//         // Main item name
//         bytes += generator.row([
//           createPosColumn(
//               width: 1,
//               text: (i + 1).toString(), // S.No
//               styles:
//                   createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
//           createPosColumn(
//               width: 8,
//               text: itemNameLines[0], // First line of item name
//               styles:
//                   createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
//           createPosColumn(
//               width: 3,
//               text:
//                   "Rs ${cartProvider.calculateItemTotal(item).toStringAsFixed(0)}", // Price
//               styles:
//                   createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
//         ]);

//         // If there are additional lines for the item name, print them below
//         if (itemNameLines.length > 1) {
//           for (int j = 1; j < itemNameLines.length; j++) {
//             bytes += generator.row([
//               createPosColumn(
//                   width: 1,
//                   text: '',
//                   styles: createPosStyles(align: PosAlign.left)),
//               createPosColumn(
//                   width: 8,
//                   text: itemNameLines[j], // Additional line of item name
//                   styles: createPosStyles(
//                       align: PosAlign.left, codeTable: 'CP1252')),
//               createPosColumn(
//                   width: 3,
//                   text: '',
//                   styles: createPosStyles(align: PosAlign.right)),
//             ]);
//           }
//         }

//         // Quantity and unit price (for kg, pcs, etc.)
//         bytes += generator.row([
//           createPosColumn(
//               width: 1,
//               text: '',
//               styles: createPosStyles(align: PosAlign.left)),
//           createPosColumn(
//               width: 8,
//               text:
//                   "(${item['quantity']} ${item['varianceData']['variance_Uom']} x ${item['varianceData']['variance_Defaultprice']} ${item['itemData']['tax']}%)", // Quantity and unit price
//               styles:
//                   createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
//           createPosColumn(
//               width: 3,
//               text: "", // Total amount
//               styles:
//                   createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
//         ]);

//         // Add an empty row for spacing between items
//         bytes += generator.row([
//           createPosColumn(
//               width: 12,
//               text: '',
//               styles: createPosStyles(align: PosAlign.center)),
//         ]);
//       }

//       // Adding totals and other details
//       bytes += generator.row([
//         createPosColumn(
//             width: 12,
//             text: '----------------------------------------------',
//             styles:
//                 createPosStyles(align: PosAlign.center, codeTable: 'CP1252')),
//       ]);
//       // Display the discount amount and percentage
//       if (discountController.text == 0) {
//         bytes += generator.row([
//           createPosColumn(
//               width: 12,
//               text:
//                   "Discount: $discountPercentage% (-Rs ${discountAmount.toStringAsFixed(0)})",
//               styles:
//                   createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
//         ]);
//       }
//       // Print Custom Charge
//       if (customChargeController.text == 0) {
//         bytes += generator.row([
//           createPosColumn(
//               width: 12,
//               text: "Custom Charge: Rs ${customCharge.toStringAsFixed(0)}",
//               styles:
//                   createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
//         ]);
//       }

//       // Find the section where the payment details are printed and adjust it:
//       bytes += generator.row([
//         createPosColumn(
//             width: 12,
//             text:
//                 "$selectedPaymentOptionValue: ${totalAmount.toStringAsFixed(0)}",
//             styles:
//                 createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
//       ]);

//       bytes += generator.row([
//         createPosColumn(
//             width: 12,
//             text:
//                 "Total : Rs ${cartProvider.calculateTotal().toStringAsFixed(0)}",
//             styles:
//                 createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
//       ]);
//       // Print SGST and CGST details
//       // Right-aligning SGST and CGST using generator.row()
//       sgstMap.forEach((rate, amount) {
//         bytes += generator.row([
//           createPosColumn(
//               text:
//                   "SGST (${rate.toStringAsFixed(1)}%): Rs ${amount.toStringAsFixed(2)}",
//               width: 12, // Assuming a width of 12 for full row width
//               styles: const PosStyles(align: PosAlign.right))
//         ]);
//       });
//       cgstMap.forEach((rate, amount) {
//         bytes += generator.row([
//           createPosColumn(
//               text:
//                   "CGST (${rate.toStringAsFixed(1)}%): Rs ${amount.toStringAsFixed(2)}",
//               width: 12, // Full width
//               styles: const PosStyles(align: PosAlign.right))
//         ]);
//       });

//       // Add these lines where you're preparing the rest of the receipt details
//       // Inside _printReceiptDetails function

//       bytes += generator.row([
//         createPosColumn(
//             width: 12,
//             text: '----------------------------------------------',
//             styles:
//                 createPosStyles(align: PosAlign.center, codeTable: 'CP1252')),
//       ]);
//       bytes += generator.feed(1);
//       bytes += generator.row([
//         createPosColumn(
//             width: 12,
//             text:
//                 ' TOTAL Rs ${cartProvider.calculateTotal().toStringAsFixed(0)}',
//             styles: createPosStyles(
//                 align: PosAlign.right,
//                 codeTable: 'CP1252',
//                 height: PosTextSize.size2,
//                 width: PosTextSize.size2)),
//       ]);
//       bytes += generator.feed(1);
//       bytes += generator.row([
//         createPosColumn(
//             width: 12,
//             text: 'Thank You ! Visit Again !',
//             styles:
//                 createPosStyles(align: PosAlign.center, codeTable: 'CP1252')),
//       ]);

//       // Inside _printReceiptDetails function
//       bytes += generator.feed(1);

//       const int maxLineWidth = 18;
//       List<String> addressLines = splitAddress(
//           "No.45, Raja Veethi, Aranmanai, Ramanathapuram, Tamil Nadu-623501");

//       for (int i = 0; i < addressLines.length; i++) {
//         bytes += generator.row([
//           createPosColumn(
//             width: 12,
//             text: addressLines[i],
//             styles: createPosStyles(
//               align: PosAlign.center, // Center the text
//               codeTable: 'CP1252',
//             ),
//           ),
//         ]);
//       }
//       bytes += generator.row([
//         createPosColumn(
//             width: 12,
//             text: 'Phone : 9342978427',
//             styles:
//                 createPosStyles(align: PosAlign.center, codeTable: 'CP1252')),
//       ]);
//       bytes += generator.row([
//         createPosColumn(
//           width: 6,
//           text: 'GST : 33AATFB12B1ZW',
//           styles: createPosStyles(align: PosAlign.center, codeTable: 'CP1252'),
//         ),
//         createPosColumn(
//           width: 6,
//           text: 'FSSAI : 1242000',
//           styles: createPosStyles(align: PosAlign.center, codeTable: 'CP1252'),
//         ),
//       ]);

//       bytes += generator.feed(1);

//       printer
//           .rawBytes(Uint8List.fromList(bytes)); // Send the bytes to the printer

//       printer.cut();

//       // Add a delay to ensure the printer completes the print job
//       await Future.delayed(const Duration(seconds: 1));

//       printer
//           .disconnect(); // Disconnect the printer only after ensuring the print is complete
//     } else {
//       print('Could not connect to printer1: ${res.msg}');
//     }

//     Navigator.of(context).pop();
//     cartProvider.clearItems();
//   }

//   List<String> splitAddress(String address) {
//     const int maxLineWidth = 18;
//     List<String> lines = [];
//     String remainingAddress = address ?? '';

//     while (remainingAddress.length > maxLineWidth) {
//       int lastIndex = remainingAddress.lastIndexOf(' ', maxLineWidth);
//       if (lastIndex == -1) {
//         lastIndex = maxLineWidth;
//       }
//       lines.add(remainingAddress.substring(0, lastIndex).trimRight());
//       remainingAddress = remainingAddress.substring(lastIndex).trimLeft();
//     }

//     lines.add(remainingAddress);

//     return lines;
//   }

//   List<String> splitText(String text, int maxLineWidth) {
//     List<String> lines = [];
//     String remainingText = text ?? '';

//     while (remainingText.length > maxLineWidth) {
//       int lastIndex = remainingText.lastIndexOf(' ', maxLineWidth);
//       if (lastIndex == -1) {
//         // If no space is found, break at maxLineWidth
//         lastIndex = maxLineWidth;
//       }
//       lines.add(remainingText.substring(0, lastIndex).trimRight());
//       remainingText = remainingText.substring(lastIndex).trimLeft();
//     }

//     lines.add(remainingText);

//     return lines;
//   }

//   String generateShortHiveInvoiceId() {
//     final random = Random();
//     final timestamp = DateTime.now()
//         .millisecondsSinceEpoch
//         .toString()
//         .substring(6); // Shortened timestamp
//     const characters =
//         'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'; // Alphanumeric characters
//     final randomId =
//         List<int>.generate(6, (_) => random.nextInt(characters.length))
//             .map((index) => characters[index])
//             .join(); // Generate a 6-character random ID
//     return '$timestamp-$randomId'; // Combines timestamp and random alphanumeric ID
//   }
// }

import 'dart:math';
import 'dart:typed_data';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart'; // Import this for PaperSize, PosStyles, etc.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yenposapp/screens/printer_screen/provider/printer_config_provider.dart';
// import '../../../data/global_data_manager.dart';
// import '../../printer_screen/provider/printer_config_provider.dart';
// import '../../regular_mode_page/provider/cart_page_provider.dart';
import '../Global/customposcolumn.dart';
import 'package:yenposapp/screens/take_away_orders/screens/model/sales_order_model.dart';

import '../screens/take_away_orders/take_away_providers/cartProvider.dart';

class ReceiptPrinter {
  final String employeeNameController;
  final String customerNumberController;
  final double discountController;
  final String deliveryDateprint;
  final String deliveryTimeprint;
  final double customChargeController;
  final String selectedPaymentOptionValue;
  final double totalAmount;
  final double advanceAmount;
  final double balanceAmount;
  final String customerType;
  // final BuildContext context;
  final String customAmountController;
  final String selectedPaymentOption;
  final SalesOrder salesOrder;
  // final Function saveInvoiceToHiveAndPrint;
  ReceiptPrinter(
      {required this.employeeNameController,
      required this.customerNumberController,
      required this.discountController,
      required this.deliveryDateprint,
      required this.deliveryTimeprint,
      required this.customChargeController,
      required this.selectedPaymentOptionValue,
      required this.totalAmount,
      required this.advanceAmount,
      required this.balanceAmount,
      // required this.context,
      required this.customerType,
      required this.customAmountController,
      required this.selectedPaymentOption,
      required this.salesOrder
      // required this.saveInvoiceToHiveAndPrint,
      });
  Future<void> printReceiptDetails(BuildContext context) async {
    print('itemName');
    print(salesOrder.itemName);
    print('salesorderlength');
    print(salesOrder.itemName.length);
    // String employeeName = employeeNameController.text ?? '';
    // String customerNumber = customerNumberController.text ?? '';
    String paymentAmount;
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy').format(now);
    String formattedTime =
        DateFormat('hh:mm a').format(now); // 12-hour format with AM/PM

    if (selectedPaymentOption == 'Cash: Custom' &&
        customAmountController.isNotEmpty) {
      paymentAmount =
          'Rs ${customAmountController}'; // Ensuring single currency symbol
    } else if (selectedPaymentOption.contains('')) {
      paymentAmount =
          'Rs ${selectedPaymentOption.split(': ').last.replaceAll('', '').trim()}';
    } else {
      paymentAmount = 'Rs ${totalAmount.toStringAsFixed(0) ?? '0'}';
    }

    var cartProvider = Provider.of<CartProvider>(context, listen: false);

    // List<double> amounts = globals.cartItems.map((item) {
    //   double calculatedAmount;
    //   if (item.uom == 'Pcs' || item.uom == 'Pkt') {
    //     calculatedAmount = item.pricePerKg * item.quantity.toDouble();
    //   } else {
    //     calculatedAmount = item.weight * item.quantity * item.pricePerKg;
    //   }
    //   return calculatedAmount;
    // }).toList();

    // var cartItems = globals.invoiceItems ?? [];

    ;

    final printerProvider =
        Provider.of<PrinterProvider>(context, listen: false);

    String printerIp = printerProvider.getOverallPrinterIp().toString();

    print(printerIp);
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(PaperSize.mm80, profile);

    final PosPrintResult res = await printer.connect(printerIp, port: 9100);

    if (res == PosPrintResult.success) {
      List<int> bytes;
      final generator = Generator(PaperSize.mm80, profile);

      // for (int copy = 0; copy < 2; copy++) {
      bytes = []; // Reset bytes for each copy

      bytes += generator.row([
        createPosColumn(
            width: 12,
            text: '',
            styles: createPosStyles(
              align: PosAlign.center,
              height: PosTextSize.size6,
              width: PosTextSize.size6,
              codeTable: 'CP1252',
            )),
      ]);
      bytes += generator.row([
        createPosColumn(
            width: 12,
            text: 'BestMummy',
            styles: createPosStyles(
              align: PosAlign.center,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              codeTable: 'CP1252',
            )),
      ]);
      bytes += generator.row([
        createPosColumn(
            width: 12,
            text: 'Sweets & Cakes',
            styles: createPosStyles(
              align: PosAlign.center,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              codeTable: 'CP1252',
            )),
      ]);
      bytes += generator.feed(1);
      bytes += generator.feed(1);
      bytes += generator.row([
        createPosColumn(
            width: 12,
            text: 'sales Invoice',
            styles: createPosStyles(
              align: PosAlign.center,
              codeTable: 'CP1252',
              height: PosTextSize.size1,
              width: PosTextSize.size1,
            )),
      ]);
      bytes += generator.feed(1);

      // Add formatted date and time
      bytes += generator.row([
        createPosColumn(
            width: 6,
            text: 'Date: $formattedDate',
            styles: createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
        createPosColumn(
            width: 6,
            text: 'Time: $formattedTime',
            styles:
                createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
      ]);

      bytes += generator.feed(1);

      // bytes += generator.row([
      //   createPosColumn(
      //       width: 6,
      //       text: 'DeliveryDate: $deliveryDateprint',
      //       styles:
      //           createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
      //   createPosColumn(
      //       width: 6,
      //       text: 'DeliveryTime:$deliveryTimeprint',
      //       styles:
      //           createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
      // ]);
      // bytes += generator.feed(1);

      bytes += generator.row([
        createPosColumn(
            width: 6,
            text: 'Branch : Aranmanai',
            styles: createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
        createPosColumn(
            width: 6,
            text: customerType == 'SalesOrder'
                ? 'saleOrderNo:101'
                : 'creditBillNo:101',
            styles:
                createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
      ]);

      bytes += generator.feed(1);

// Print Sales Person and Customer Number on the same line
      bytes += generator.row([
        createPosColumn(
            width: 6,
            text: 'SalesPerson : ${employeeNameController}',
            styles: createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
        createPosColumn(
            width: 6,
            text: 'C No: $customerNumberController',
            styles:
                createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
      ]);

      bytes += generator.feed(1);

      // Add headers for S.No, Item, Price, Qty, and Amount
      bytes += generator.row([
        createPosColumn(
            width: 1,
            text: 'S.No',
            styles: createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
        createPosColumn(
            width: 5,
            text: 'Item',
            styles: createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
        createPosColumn(
            width: 2,
            text: '',
            styles:
                createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
        createPosColumn(
            width: 1,
            text: '',
            styles:
                createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
        createPosColumn(
            width: 3,
            text: 'Amount',
            styles:
                createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
      ]);

      bytes += generator.feed(1);
      double totalSGST = 0.0;
      double totalCGST = 0.0;
      double taxVaule = 0.0;
      Map<double, double> sgstMap = {};
      Map<double, double> cgstMap = {};

      // Process each item
      // for (var item in salesOrder.items) {
      //   // Assuming tax is fetched as dynamic or int, ensure it's treated as double
      //   double taxRate =
      //       (item.tax as num).toDouble(); // num can be both int and double
      //   double itemTotal = cartProvider.calculateSubtotal();
      //   //     .toDouble(); // Ensure itemTotal is a double

      //   double itemTax = itemTotal * (taxRate / 100);
      //   double itemSGST = itemTax / 2;
      //   double itemCGST = itemSGST;

      //   // Update the maps with doubles
      //   sgstMap[taxRate / 2] = (sgstMap[taxRate / 2] ?? 0.0) + itemSGST;
      //   cgstMap[taxRate / 2] = (cgstMap[taxRate / 2] ?? 0.0) + itemCGST;
      // }

      // Adding cart items with item name, quantity, and price in the desired format
      for (int i = 0; i < salesOrder.itemName.length; i++) {
        // final item = cartItems[i];
        String itemName = salesOrder.itemName[i];
        int quantity = salesOrder.qty[i];
        double price = salesOrder.price[i];
        String uom = salesOrder.uom[i];
        int taxRate = salesOrder.tax[i];
        double weight = salesOrder.weight[i];
        double totalTax = totalAmount * (taxRate / 100); // Total tax amount
        double sgstAmount = totalTax / 2; // SGST amount
        double cgstAmount = totalTax / 2;
        // Calculate item amount
        sgstMap[taxRate / 2] = (sgstMap[taxRate / 2] ?? 0.0) + sgstAmount;
        cgstMap[taxRate / 2] = (cgstMap[taxRate / 2] ?? 0.0) + cgstAmount;
        double amount = price * quantity;
        // final String itemName = salesOrder.itemName.toString() ?? 'N/A';
        // print('item from for loop');
        // print('itemName$itemName');
        // final String varianceName = item.itemName ?? 'N/A';
        // print('item from for loop');
        // print('itemName$varianceName');
//         final double price = item.price.toDouble() ?? 0.0;
//         final double weight = (item.weight ?? 0.0).toDouble();
//         final double qty = (item.qty as num).toDouble() ?? 0.0;
//         // final double amount = item.uom == 'Kgs'
//         //     ? 'Rs.${(item.weight * item.quantity * item.pricePerKg).toDouble()}/-'
//         //     : 'Rs.${(item.quantity * item.pricePerKg).toDouble()}/-';

        // final double amount = uoms == 'Kgs'
        //       ? (weights! * quantities! * prices).toDouble()
        //       : (quantities! * prices.toDouble();

// // Now, if you want to display the value with 'Rs.' and '/-', you can do this separately
//         final String amountString = 'Rs.${amount.toStringAsFixed(2)}/-';
//         final double tax = (item.tax as num).toDouble();
//         final String uom = item.uom ?? 'N/A';

//         double taxPercentage = (item.tax as num).toDouble();

//         taxVaule = taxPercentage;

        List<String> itemNameLines = splitText(itemName ?? '', 15);

        // Main item name
        bytes += generator.row([
          createPosColumn(
              width: 1,
              text: (i + 1).toString(), // S.No
              styles:
                  createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
          createPosColumn(
              width: 8,
              text: itemNameLines[0], // First line of item name

              styles:
                  createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
          createPosColumn(
              width: 3,
              text:
                  // "Rs ${cartProvider.calculateSubtotal().toStringAsFixed(0)}", // Price
                  "Rs $amount",
              styles:
                  createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
        ]);

        // If there are additional lines for the item name, print them below
        if (itemNameLines.length > 1) {
          for (int j = 1; j < itemNameLines.length; j++) {
            bytes += generator.row([
              createPosColumn(
                  width: 1,
                  text: '',
                  styles: createPosStyles(align: PosAlign.left)),
              createPosColumn(
                  width: 8,
                  text: itemNameLines[j], // Additional line of item name
                  // text: 'hii',
                  styles: createPosStyles(
                      align: PosAlign.left, codeTable: 'CP1252')),
              createPosColumn(
                  width: 3,
                  text: '',
                  styles: createPosStyles(align: PosAlign.right)),
            ]);
          }
        }

        // Quantity and unit price (for kg, pcs, etc.)
        bytes += generator.row([
          createPosColumn(
              width: 1,
              text: '',
              styles: createPosStyles(align: PosAlign.left)),
          createPosColumn(
              width: 8,
              text:
                  "(${quantity} ${uom} x ${price} ${taxRate}%)", // Quantity and unit price

              styles:
                  createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
          createPosColumn(
              width: 3,
              text: "", // Total amount
              styles:
                  createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
        ]);

        // Add an empty row for spacing between items
        bytes += generator.row([
          createPosColumn(
              width: 12,
              text: '',
              styles: createPosStyles(align: PosAlign.center)),
        ]);
      }

      // Adding totals and other details
      bytes += generator.row([
        createPosColumn(
            width: 12,
            text: '----------------------------------------------',
            styles:
                createPosStyles(align: PosAlign.center, codeTable: 'CP1252')),
      ]);
      // Display the discount amount and percentage
      if (discountController != 0) {
        bytes += generator.row([
          createPosColumn(
              width: 12,
              text: "Discount:  Rs ${discountController.toStringAsFixed(2)}",
              // "",
              styles:
                  createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
        ]);
      }
      // Print Custom Charge
      if (customChargeController != 0) {
        bytes += generator.row([
          createPosColumn(
              width: 12,
              text:
                  "Custom Charge: Rs ${customChargeController.toStringAsFixed(0)}",
              styles:
                  createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
        ]);
      }

      // // Find the section where the payment details are printed and adjust it:

      if (advanceAmount != 0) {
        bytes += generator.row([
          createPosColumn(
              width: 12,
              text: "Advance Amount :Rs ${advanceAmount.toStringAsFixed(0)}",
              styles:
                  createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
        ]);
      }

      // bytes += generator.row([
      //   createPosColumn(
      //       width: 12,
      //       text: "payment Type: $selectedPaymentOptionValue",
      //       styles:
      //           createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
      // ]);

      sgstMap.forEach((rate, amount) {
        bytes += generator.row([
          createPosColumn(
              text:
                  "SGST (${rate.toStringAsFixed(1)}%): Rs ${amount.toStringAsFixed(2)}",
              width: 12, // Assuming a width of 12 for full row width
              styles: const PosStyles(align: PosAlign.right))
        ]);
      });
      cgstMap.forEach((rate, amount) {
        bytes += generator.row([
          createPosColumn(
              text:
                  "CGST (${rate.toStringAsFixed(1)}%): Rs ${amount.toStringAsFixed(2)}",
              width: 12, // Full width
              styles: const PosStyles(align: PosAlign.right))
        ]);
      });

      bytes += generator.row([
        createPosColumn(
            width: 12,
            text:
                "$selectedPaymentOptionValue: ${totalAmount.toStringAsFixed(0)}",
            styles:
                createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
      ]);

      bytes += generator.row([
        createPosColumn(
            width: 12,
            text: "Total Amount :Rs ${totalAmount.toStringAsFixed(0)}",
            styles:
                createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
      ]);

      // bytes += generator.row([
      //   createPosColumn(
      //       width: 12,
      //       text: "Balance Amount :Rs ${balanceAmount.toStringAsFixed(0)}",
      //       styles:
      //           createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
      // ]);

      bytes += generator.row([
        createPosColumn(
            width: 12,
            text: '----------------------------------------------',
            styles:
                createPosStyles(align: PosAlign.center, codeTable: 'CP1252')),
      ]);

      bytes += generator.feed(1);
      bytes += generator.row([
        createPosColumn(
            width: 12,
            text: ' TOTAL Rs ${totalAmount.toStringAsFixed(0)}',
            styles: createPosStyles(
                align: PosAlign.right,
                codeTable: 'CP1252',
                height: PosTextSize.size2,
                width: PosTextSize.size2)),
      ]);
      bytes += generator.feed(1);
      bytes += generator.row([
        createPosColumn(
            width: 12,
            text: 'Thank You ! Visit Again !',
            styles:
                createPosStyles(align: PosAlign.center, codeTable: 'CP1252')),
      ]);

      // Inside _printReceiptDetails function
      bytes += generator.feed(1);

      const int maxLineWidth = 18;
      List<String> addressLines = splitAddress(
          "No.45, Raja Veethi, Aranmanai, Ramanathapuram, Tamil Nadu-623501");

      for (int i = 0; i < addressLines.length; i++) {
        bytes += generator.row([
          createPosColumn(
            width: 12,
            text: addressLines[i],
            styles: createPosStyles(
              align: PosAlign.center, // Center the text
              codeTable: 'CP1252',
            ),
          ),
        ]);
      }
      bytes += generator.row([
        createPosColumn(
            width: 12,
            text: 'Phone : 9342978427',
            styles:
                createPosStyles(align: PosAlign.center, codeTable: 'CP1252')),
      ]);
      bytes += generator.row([
        createPosColumn(
          width: 6,
          text: 'GST : 33AATFB12B1ZW',
          styles: createPosStyles(align: PosAlign.center, codeTable: 'CP1252'),
        ),
        createPosColumn(
          width: 6,
          text: 'FSSAI : 1242000',
          styles: createPosStyles(align: PosAlign.center, codeTable: 'CP1252'),
        ),
      ]);

      printer
          .rawBytes(Uint8List.fromList(bytes)); // Send the bytes to the printer

      printer.cut(); // Cut the paper after each copy

      // Add a slight delay between prints

      // }

      printer.disconnect();
    } else {
      print('Could not connect to printer: ${res.msg}');
    }

    // Navigator.of(context).pop();
    // cartProvider.clearCart();
  }

  List<String> splitAddress(String address) {
    const int maxLineWidth = 18;
    List<String> lines = [];
    String remainingAddress = address ?? '';

    while (remainingAddress.length > maxLineWidth) {
      int lastIndex = remainingAddress.lastIndexOf(' ', maxLineWidth);
      if (lastIndex == -1) {
        lastIndex = maxLineWidth;
      }
      lines.add(remainingAddress.substring(0, lastIndex).trimRight());
      remainingAddress = remainingAddress.substring(lastIndex).trimLeft();
    }

    lines.add(remainingAddress);

    return lines;
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

  String generateShortHiveInvoiceId() {
    final random = Random();
    final timestamp = DateTime.now()
        .millisecondsSinceEpoch
        .toString()
        .substring(6); // Shortened timestamp
    const characters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'; // Alphanumeric characters
    final randomId =
        List<int>.generate(6, (_) => random.nextInt(characters.length))
            .map((index) => characters[index])
            .join(); // Generate a 6-character random ID
    return '$timestamp-$randomId'; // Combines timestamp and random alphanumeric ID
  }
}
