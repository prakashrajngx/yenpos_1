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
import '../screens/take_away_orders/take_away_providers/cartProvider.dart';

import '../screens/take_away_orders/globals.dart' as globals;

class ReceiptPrinter {
  final TextEditingController employeeNameController;
  final TextEditingController customerNumberController;
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
  final TextEditingController customAmountController;
  final String selectedPaymentOption;
  // final Function saveInvoiceToHiveAndPrint;
  ReceiptPrinter({
    required this.employeeNameController,
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
    // required this.saveInvoiceToHiveAndPrint,
  });
  Future<void> printReceiptDetails(BuildContext context) async {
    String employeeName = employeeNameController.text ?? '';
    String customerNumber = customerNumberController.text ?? '';
    String paymentAmount;
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy').format(now);
    String formattedTime =
        DateFormat('hh:mm a').format(now); // 12-hour format with AM/PM

    if (selectedPaymentOption == 'Cash: Custom' &&
        customAmountController.text.isNotEmpty) {
      paymentAmount =
          'Rs ${customAmountController.text}'; // Ensuring single currency symbol
    } else if (selectedPaymentOption.contains('')) {
      paymentAmount =
          'Rs ${selectedPaymentOption.split(': ').last.replaceAll('', '').trim()}';
    } else {
      paymentAmount = 'Rs ${totalAmount.toStringAsFixed(0) ?? '0'}';
    }

    var cartProvider = Provider.of<CartProvider>(context, listen: false);
    var cartItems = globals.cartItems ?? [];

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

      for (int copy = 0; copy < 2; copy++) {
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
              text: customerType == 'SalesOrder'
                  ? (copy == 0 ? 'Sales order' : 'CustomerCopy')
                  : (customerType == 'CreditOrder'
                      ? (copy == 0 ? 'Credit Order' : 'CustomerCopy')
                      : 'Unknown'),
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
              styles:
                  createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
          createPosColumn(
              width: 6,
              text: 'Time: $formattedTime',
              styles:
                  createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
        ]);

        bytes += generator.feed(1);

        bytes += generator.row([
          createPosColumn(
              width: 6,
              text: 'DeliveryDate: $deliveryDateprint',
              styles:
                  createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
          createPosColumn(
              width: 6,
              text: 'DeliveryTime:$deliveryTimeprint',
              styles:
                  createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
        ]);
        bytes += generator.feed(1);

        bytes += generator.row([
          createPosColumn(
              width: 6,
              text: 'Branch : Aranmanai',
              styles:
                  createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
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
              text: 'SalesPerson : ${employeeNameController.text}',
              styles:
                  createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
          createPosColumn(
              width: 6,
              text: 'C No: $customerNumber',
              styles:
                  createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
        ]);

        bytes += generator.feed(1);

        // Add headers for S.No, Item, Price, Qty, and Amount
        bytes += generator.row([
          createPosColumn(
              width: 1,
              text: 'S.No',
              styles:
                  createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
          createPosColumn(
              width: 5,
              text: 'Item',
              styles:
                  createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
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
        for (var item in cartItems) {
          // Assuming tax is fetched as dynamic or int, ensure it's treated as double
          double taxRate =
              (item.tax as num).toDouble(); // num can be both int and double
          double itemTotal = cartProvider.calculateSubtotal();
          //     .toDouble(); // Ensure itemTotal is a double

          double itemTax = itemTotal * (taxRate / 100);
          double itemSGST = itemTax / 2;
          double itemCGST = itemSGST;

          // Update the maps with doubles
          sgstMap[taxRate / 2] = (sgstMap[taxRate / 2] ?? 0.0) + itemSGST;
          cgstMap[taxRate / 2] = (cgstMap[taxRate / 2] ?? 0.0) + itemCGST;
        }

        // Adding cart items with item name, quantity, and price in the desired format
        for (int i = 0; i < cartItems.length; i++) {
          final item = cartItems[i];

          final String itemName = item.name ?? 'N/A';
          final String varianceName = item.name ?? 'N/A';
          final double price = item.pricePerKg.toDouble() ?? 0.0;
          final double weight = (item.weight ?? 0.0).toDouble();
          final double qty = (item.quantity as num).toDouble() ?? 0.0;
          // final double amount = item.uom == 'Kgs'
          //     ? 'Rs.${(item.weight * item.quantity * item.pricePerKg).toDouble()}/-'
          //     : 'Rs.${(item.quantity * item.pricePerKg).toDouble()}/-';

          final double amount = item.uom == 'Kgs'
              ? (item.weight * item.quantity * item.pricePerKg).toDouble()
              : (item.quantity * item.pricePerKg).toDouble();

// Now, if you want to display the value with 'Rs.' and '/-', you can do this separately
          final String amountString = 'Rs.${amount.toStringAsFixed(2)}/-';
          final double tax = (item.tax as num).toDouble();
          final String uom = item.uom ?? 'N/A';

          double taxPercentage = (item.tax as num).toDouble();

          taxVaule = taxPercentage;

          List<String> itemNameLines = splitText(item.name ?? '', 15);

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
                styles: createPosStyles(
                    align: PosAlign.right, codeTable: 'CP1252')),
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
                    "(${item.quantity} ${item.uom} x ${item.pricePerKg} ${item.tax}%)", // Quantity and unit price

                styles:
                    createPosStyles(align: PosAlign.left, codeTable: 'CP1252')),
            createPosColumn(
                width: 3,
                text: "", // Total amount
                styles: createPosStyles(
                    align: PosAlign.right, codeTable: 'CP1252')),
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
                styles: createPosStyles(
                    align: PosAlign.right, codeTable: 'CP1252')),
          ]);
        }
        // Print Custom Charge
        if (customChargeController != 0) {
          bytes += generator.row([
            createPosColumn(
                width: 12,
                text:
                    "Custom Charge: Rs ${customChargeController.toStringAsFixed(0)}",
                styles: createPosStyles(
                    align: PosAlign.right, codeTable: 'CP1252')),
          ]);
        }

        // // Find the section where the payment details are printed and adjust it:

        bytes += generator.row([
          createPosColumn(
              width: 12,
              text: "Total Amount :Rs ${totalAmount.toStringAsFixed(0)}",
              styles:
                  createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
        ]);
        if (advanceAmount != 0) {
          bytes += generator.row([
            createPosColumn(
                width: 12,
                text: "Advance Amount :Rs ${advanceAmount.toStringAsFixed(0)}",
                styles: createPosStyles(
                    align: PosAlign.right, codeTable: 'CP1252')),
          ]);
        }

        bytes += generator.row([
          createPosColumn(
              width: 12,
              text: "payment Type: $selectedPaymentOptionValue",
              styles:
                  createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
        ]);
        bytes += generator.row([
          createPosColumn(
              width: 12,
              text: "Balance Amount :Rs ${balanceAmount.toStringAsFixed(0)}",
              styles:
                  createPosStyles(align: PosAlign.right, codeTable: 'CP1252')),
        ]);

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
            styles:
                createPosStyles(align: PosAlign.center, codeTable: 'CP1252'),
          ),
          createPosColumn(
            width: 6,
            text: 'FSSAI : 1242000',
            styles:
                createPosStyles(align: PosAlign.center, codeTable: 'CP1252'),
          ),
        ]);

        printer.rawBytes(
            Uint8List.fromList(bytes)); // Send the bytes to the printer

        printer.cut(); // Cut the paper after each copy

        // Add a slight delay between prints
      }

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
