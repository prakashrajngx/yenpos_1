// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Global/custom_sized_box.dart';
import '../item_asign_printer_screen/item_asign.dart';
import '../regular_mode_page/widget/custom_reusable_widget/letter_keyborard.dart';
import 'model/printer_model.dart';
import 'provider/printer_config_provider.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart'; // Import this for PaperSize, PosStyles, etc.

// ignore: use_key_in_widget_constructors
class PrinterSettingsScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  String _selectedType = 'Overall';

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

  @override
  void initState() {
    super.initState();
    final printerProvider =
        Provider.of<PrinterProvider>(context, listen: false);
    printerProvider.initializeHive();
  }

  void _showAddPrinterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'ADD PRINTER',
            style: TextStyle(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Printer Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.text, // Use default system keyboard
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ipController,
                decoration: InputDecoration(
                  labelText: 'IP Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType:
                    TextInputType.number, // Use default system keyboard
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
                items: <String>['Overall', 'Item-wise', 'POS', 'Invoice']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Printer Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 239, 72, 72),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isEmpty ||
                    _ipController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter both Name and IP Address'),
                    ),
                  );
                  return;
                }

                final newPrinter = Printer(
                  name: _nameController.text,
                  ipAddress: _ipController.text,
                  type: _selectedType,
                  items: [],
                );

                final printerProvider =
                    Provider.of<PrinterProvider>(context, listen: false);

                printerProvider.addPrinter(newPrinter);

                _nameController.clear();
                _ipController.clear();
                setState(() {
                  _selectedType = 'Overall';
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA5D6A7),
              ),
              child: const Text(
                'Add Printer',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRemovePrinterDialog(
      BuildContext context, PrinterProvider printerProvider, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove PrinterIp'),
          content:
              const Text('Are you sure you want to remove this printerIp?'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 239, 72, 72),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final printer = printerProvider.printers[index];
                printerProvider.removePrinter(index);

                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA5D6A7),
              ),
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Example receipt print function
  void testReceipt(NetworkPrinter printer) {
    printer.text(
      'Sample Data',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    printer.feed(2);
    printer.cut();
  }

  @override
  Widget build(BuildContext context) {
    final printerProvider = Provider.of<PrinterProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Printer Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor:
          Colors.white, // Light blue background for the entire Scaffold

      body: printerProvider.printers.isEmpty
          ? const Center(
              child: Text(
                'No Printer Config',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const CustomSizedBox(height: 20),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: printerProvider.printers.length,
                      itemBuilder: (context, index) {
                        final printer = printerProvider.printers[index];
                        return Card(
                          margin: const EdgeInsets.all(10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                          child: ExpansionTile(
                            title: Row(
                              children: [
                                const Icon(
                                  Icons.print,
                                  color: Color(0xFFA5D6A7),
                                ),
                                const CustomSizedBox(width: 10),
                                Text(
                                  printer.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            subtitle:
                                Text('${printer.ipAddress} - ${printer.type}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (printer.type == 'Item-wise')
                                  IconButton(
                                    icon: const Icon(Icons.assignment),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ItemAssignmentScreen(
                                                  printerIndex: index),
                                        ),
                                      );
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _showDeleteConfirmationDialog(
                                        context, printerProvider, index);
                                  },
                                ),
                              ],
                            ),
                            children: [
                              if (printer.items.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Column(
                                    children: printer.items
                                        .map((item) => ListTile(
                                              title: Text(item),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              if (printer.items.isEmpty)
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.0),
                                  child: ListTile(
                                    title: Text('No items assigned'),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPrinterDialog(context);
        },
        backgroundColor: const Color(0xFFA5D6A7),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, PrinterProvider printerProvider, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this printer?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Perform the delete action
                printerProvider.removePrinter(index);
                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA5D6A7),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }
}



























// import 'package:flutter/material.dart';
// import 'package:yenposapp/screens/printer_screen/find_network_config_provider.dart';

// class PrinterSettingsScreen extends StatefulWidget {
//   @override
//   _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
// }

// class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
//   List<String> _detectedPrinters = [];
//   bool _isScanning = false;

//   void _scanForPrinters() async {
//     setState(() {
//       _isScanning = true;
//     });

//     try {
//       final printers = await NetworkPrinterScanner.discoverPrinters(9100);
//       setState(() {
//         _detectedPrinters = printers;
//         _isScanning = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isScanning = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error scanning for printers: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Printer Settings'),
//       ),
//       body: _isScanning
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               itemCount: _detectedPrinters.length,
//               itemBuilder: (context, index) {
//                 final printerIp = _detectedPrinters[index];
//                 return ListTile(
//                   title: Text(printerIp),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.add),
//                     onPressed: () {
//                       // Logic to add this printer IP
//                       print('Selected Printer: $printerIp');
//                     },
//                   ),
//                 );
//               },
//             ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _scanForPrinters,
//         child: const Icon(Icons.search),
//       ),
//     );
//   }
// }
