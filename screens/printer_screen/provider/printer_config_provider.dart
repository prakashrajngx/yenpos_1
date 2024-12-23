import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../model/printer_model.dart';

class PrinterProvider with ChangeNotifier {
  late Box? _printerBox;
  List<Printer> _printers = [];
  List<Printer> get printers =>
      _printers.where((printer) => printer.status).toList();

  String? _clientIp;

  String? get clientIp => _clientIp;
  Future<void> initializeHive() async {
    print("init hive");

    try {
      _printerBox = await Hive.openBox('printers');
      _clientIp = _printerBox!.get('clientIp');
      print('Retrieved Client IP from Hive: $_clientIp');

      _loadPrintersFromHive();
    } catch (e) {
      print("Error opening Hive box: $e");
    }
  }

  Future<void> saveClientIp(String? clientIp) async {
    _clientIp = clientIp;
    await _printerBox!.put('clientIp', clientIp);
    print('Client IP saved to Hive: $clientIp');

    notifyListeners();
  }

  void _loadPrintersFromHive() {
    print("LOAD.. hive");

    try {
      final data = _printerBox!.get('data');
      print("Retrieved data from Hive: $data");

      if (data != null && data is List) {
        _printers = data
            .map((json) {
              if (json is Map) {
                final map = Map<String, dynamic>.from(json);
                return Printer.fromJson(map);
              } else {
                print("Invalid data format: $json");
                return null;
              }
            })
            .whereType<Printer>()
            .toList();

        notifyListeners();
        print("_printers....4");
        print(_printers);
      } else {
        print("No data found in Hive or data is not a list");
      }
    } catch (e) {
      print("Error loading data from Hive: $e");
    }
  }

  void addPrinter(Printer printer) {
    if (_printers.any((p) => p.name == printer.name)) {
      print("Printer already exists: ${printer.name}");
      return;
    }
    print("Adding printer: ${printer.name}");

    final newPrinter = Printer(
      name: printer.name,
      ipAddress: printer.ipAddress,
      type: printer.type,
      items: printer.items,
    );

    _printers.add(newPrinter);
    _savePrintersToHive();
  }

  void updatePrinter(Printer updatedPrinter) {
    final index =
        _printers.indexWhere((printer) => printer.name == updatedPrinter.name);
    if (index != -1) {
      _printers[index] = updatedPrinter;
      _savePrintersToHive();
    }
  }

  void removePrinter(int index) {
    print("Removing printer at index: $index");
    if (index >= 0 && index < _printers.length) {
      final removedPrinter = _printers.removeAt(index); // Remove from list
      _savePrintersToHive(); // Save updated list to Hive
      print("Printer removed: ${removedPrinter.name}");
      notifyListeners(); // Notify listeners to refresh the UI
    } else {
      print("Invalid index: $index");
    }
  }

  void removePrinterByName(String printerName) {
    final index =
        _printers.indexWhere((printer) => printer.name == printerName);
    if (index != -1) {
      final removedPrinter = _printers.removeAt(index); // Remove from list

      print("Printer removed by name: ${removedPrinter.name}");
      notifyListeners();
    } else {
      print("Printer not found with name: $printerName");
    }
  }

  void _savePrintersToHive() {
    final data = _printers.map((printer) => printer.toJson()).toList();
    _printerBox?.put('data', data);
    print("Data saved to Hive: ${_printerBox?.get('data')}");
    notifyListeners();
  }

  String? getPrinterIpForItem(String itemName) {
    itemName = itemName.trim().toLowerCase(); // Normalize the item name
    for (final printer in _printers) {
      print("priinter itemnaem..");
      print(itemName);
      print(printer.ipAddress);
      for (final item in printer.items) {
        print("Checking item: $item"); // Add this line for debugging
        if (item.trim().toLowerCase() == itemName) {
          return printer.ipAddress;
        }
      }
    }
    return null;
  }

  String? getOverallPrinterIp() {
    for (var printer in _printers) {
      if (printer.type == 'Overall') {
        return printer.ipAddress;
      }
    }
    return null;
  }
}
