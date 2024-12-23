import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'global/globals.dart';
import 'provider/order_provider.dart';
import 'provider/printer_provider.dart';

class PreInvoiceScreen extends StatelessWidget {
  const PreInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final printerProvider = Provider.of<KotPrinterProvider>(context);
    final preInvoices = orderProvider.preInvoices;
    final uniquePreInvoices =
        {for (var v in preInvoices) v['preInvoiceId']: v}.values.toList();

    print("preinvoices....");
    print(preInvoices);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('KOT Invoice'),
        ),
        body: InvoiceList(orderProvider: orderProvider),
      ),
    );
  }
}

class InvoiceList extends StatelessWidget {
  final OrderProvider orderProvider;

  const InvoiceList({
    super.key,
    required this.orderProvider,
  });

  @override
  Widget build(BuildContext context) {
    final invoices = orderProvider.preInvoices; // Fetch the invoices
    print("Invoices fetched: $invoices");

    // Group invoices by table number
    Map<String, List<dynamic>> groupedInvoices = {};
    final filteredInvoices = invoices.where((invoice) {
      return invoice['preInvoiceId'] != null; // Filter valid invoices
    }).toList();

    // Group filtered invoices by table number
    for (var invoice in filteredInvoices) {
      final tableNumber = invoice['table']?.toString() ?? 'Unknown';
      if (groupedInvoices[tableNumber] == null) {
        groupedInvoices[tableNumber] = [];
      }
      groupedInvoices[tableNumber]?.add(invoice);
    }

    Future<void> sendInvoiceToServer(Map<String, dynamic> invoiceData) async {
      final channel = IOWebSocketChannel.connect('ws://$serverip:$port');
      channel.sink.add(jsonEncode(invoiceData));
      channel.sink.close();
      print('Invoice data sent to server: $invoiceData');
    }

    return ListView(
      padding: const EdgeInsets.all(10.0),
      children: groupedInvoices.entries.map((entry) {
        final tableNumber = entry.key;
        final tableInvoices = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 20.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Table $tableNumber',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                itemCount: tableInvoices.length,
                itemBuilder: (context, index) {
                  final invoice = tableInvoices[index];
                  // Manually create seatOrders using available data
                  final seatOrders = [
                    {
                      'items':
                          List.generate(invoice['itemNames']?.length ?? 0, (i) {
                        return {
                          'varianceName': invoice['varianceNames'][i],
                          'price': invoice['prices'][i],
                          'quantity': invoice['quantities'][i],
                          'total':
                              (invoice['prices'][i] * invoice['quantities'][i]),
                          'isCanceled':
                              false, // Adjust this as needed based on your logic
                        };
                      }),
                      'tokenNo': invoice['tokenNo']
                    }
                  ];

                  final total = seatOrders.fold<double>(
                      0.0,
                      (sum, order) =>
                          sum +
                          order['items'].fold(0.0,
                              (subtotal, item) => subtotal + item['total']));

                  final preInvoiceId = invoice['preInvoiceId'];
                  final seat = invoice['seat'] ?? 'Unknown';
                  final tableNo = invoice['table'] ?? 'Unknown';

                  // Debugging output to check seatOrders content
                  print("Invoice for Table $tableNo, Seat $seat: $seatOrders");

                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Table $tableNo - $seat',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Text('Id: $preInvoiceId',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                                const Divider(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: seatOrders.isNotEmpty
                                      ? seatOrders.map<Widget>((order) {
                                          final orderItems =
                                              order['items'] ?? [];
                                          int orderIndex =
                                              seatOrders.indexOf(order) + 1;

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'Order $orderIndex: TknNo ${order['tokenNo'] ?? 'N/A'}: (${orderItems.length} Items)',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              const Divider(),
                                              Table(
                                                columnWidths: const {
                                                  0: FlexColumnWidth(2),
                                                  1: FlexColumnWidth(1),
                                                  2: FlexColumnWidth(1),
                                                  3: FlexColumnWidth(1),
                                                },
                                                children: [
                                                  const TableRow(children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(4.0),
                                                      child: Text('Item Name',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(4.0),
                                                      child: Text('Unit',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(4.0),
                                                      child: Text('Qty',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(4.0),
                                                      child: Text('Total',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ),
                                                  ]),
                                                  for (var item in orderItems)
                                                    TableRow(children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4.0),
                                                        child: Text(
                                                            '${item['varianceName'] ?? 'N/A'}',
                                                            style: item['isCanceled'] ==
                                                                    true
                                                                ? const TextStyle(
                                                                    decoration:
                                                                        TextDecoration
                                                                            .lineThrough)
                                                                : null),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4.0),
                                                        child: Text(
                                                            '₹${(item['price']).toStringAsFixed(2)}',
                                                            style: item['isCanceled'] ==
                                                                    true
                                                                ? const TextStyle(
                                                                    decoration:
                                                                        TextDecoration
                                                                            .lineThrough)
                                                                : null),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4.0),
                                                        child: Text(
                                                            '${item['quantity']}',
                                                            style: item['quantity'] ==
                                                                    0
                                                                ? const TextStyle(
                                                                    decoration:
                                                                        TextDecoration
                                                                            .lineThrough)
                                                                : null),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4.0),
                                                        child: Text(
                                                            '₹${(item['total']).toStringAsFixed(2)}',
                                                            style: item['quantity'] ==
                                                                    0
                                                                ? const TextStyle(
                                                                    decoration:
                                                                        TextDecoration
                                                                            .lineThrough)
                                                                : null),
                                                      ),
                                                    ]),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                          );
                                        }).toList()
                                      : [const Text('No orders available.')],
                                ),
                                const SizedBox(height: 10),
                                Text('Total: ₹${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 239, 72, 72),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            // ElevatedButton(
                            //   onPressed: () async {
                            //     // Fetch the invoice printer from the printer provider
                            //     final invoicePrinter =
                            //         printerProvider.printers.firstWhere(
                            //       (printer) => printer.type == 'Invoice',
                            //       orElse: () => Printer(
                            //         name: 'default_printer_name',
                            //         ipAddress: 'default_ip',
                            //         type: 'default_type',
                            //       ),
                            //     );

                            //     if (invoicePrinter != null) {
                            //       // Print the invoice receipt using the PreInvoicePrinter service
                            //       await PreInvoicePrinter.printReceipt(
                            //         ipAddress: invoicePrinter
                            //             .ipAddress, // Use the IP address of the printer
                            //         tableNumber: invoice[
                            //             'table'], // Table number of the invoice
                            //         seat: invoice[
                            //             'seat'], // Seat number of the invoice
                            //         total: total, // Total amount of the invoice
                            //         seatOrders:
                            //             seatOrders, // The seat orders to be printed
                            //         receiptType:
                            //             'Invoice', // Specify the receipt type as 'Invoice'
                            //       );
                            //     }

                            //     // Preparing the invoice data to be sent to the server
                            //     final now = DateTime.now();
                            //     final formattedDate =
                            //         DateFormat('dd-MM-yyyy').format(now);
                            //     final formattedTime =
                            //         DateFormat('HH:mm:ss').format(now);

                            //     final invoiceData = {
                            //       'tableNumber': invoice['table'],
                            //       'seat': invoice['seat'],
                            //       'total': total,
                            //       'type': "invoice",
                            //       'date': formattedDate,
                            //       'time': formattedTime,
                            //       'preInvoiceId': preInvoiceId,
                            //       'seatOrders': seatOrders,
                            //     };

                            //     // Send the invoice data to the server
                            //     await sendInvoiceToServer(invoiceData);

                            //     // Clear invoice and pre-invoice records on this client
                            //     orderProvider.clearOrdersForseatAtTable(
                            //         invoice['table'], invoice['seat']);

                            //     // Notify listeners about the change
                            //     orderProvider.notifyListeners();

                            //     // Close the dialog
                            //     Navigator.of(context).pop();
                            //   },
                            //   style: ElevatedButton.styleFrom(
                            //     backgroundColor: const Color(0xFFA5D6A7),
                            //   ),
                            //   child: const Text(
                            //     'Print Invoice',
                            //     style: TextStyle(color: Colors.black),
                            //   ),
                            // ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.pink[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 5),
                          Text('SEAT $seat',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 5),
                          Text(' ₹${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
