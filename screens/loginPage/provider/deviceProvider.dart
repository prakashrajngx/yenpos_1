import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeviceProvider with ChangeNotifier {
  String _deviceCode = '';
  String _branchName = '';
  String _deviceCodeId = '';
  String get deviceCode => _deviceCode;
  String get branchName => _branchName;
  Map<String, dynamic>? deviceData;

  void setDeviceData(Map<String, dynamic> data) {
    deviceData = data;
    notifyListeners();
  }

  void clearDeviceData() {
    deviceData = null;
    notifyListeners();
  }

  Future<void> fetchAndStoreDeviceData(String deviceCode) async {
    const String url = 'http://192.168.1.113:8888/devicecodes';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> devices = json.decode(response.body);
        final device = devices.firstWhere(
          (device) =>
              device['deviceCode'] == deviceCode && device['status'] == '1',
          orElse: () => null,
        );

        if (device != null) {
          _deviceCodeId = device['deviceCodeId'];
          // Store device data in Hive and patch status
          await storeDeviceData(
              device['deviceCode'], device['branchName'], _deviceCodeId);
        } else {
          print("Device not found or status is not '1'");
          // Handle device not found or incorrect status scenario
        }
      } else {
        print(
            'Failed to fetch device data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching device data: $error');
    }
  }

  Future<void> storeDeviceData(
      String deviceCode, String branchName, String deviceCodeId) async {
    try {
      print("storeDeviceData");

      // Open the Hive box (a storage container for key-value pairs)
      var box = await Hive.openBox('deviceData');

      // Check if the status is 0 in the incoming device data
      if (box.get('status') == '0') {
        print('Device code is expired.');
        // Notify user with a message that the device code is expired
        // You can integrate a Flutter widget like a snackbar, dialog, etc., to inform the user
        return;
      }

      // Save the deviceCode, branchName, and deviceCodeId in Hive
      await box.put('deviceCode', deviceCode);
      await box.put('branchName', branchName);
      await box.put('deviceCodeId', deviceCodeId);
      await box.put('status', '1'); // Assuming you're storing the status

      // Update the state
      _deviceCode = deviceCode;
      _branchName = branchName;
      _deviceCodeId = deviceCodeId;

      // Notify listeners about the changes
      notifyListeners();

      print(
          'Device data stored: Device Code: $deviceCode, Branch: $branchName, Device Code ID: $deviceCodeId');

      // Patch the device status as 0
      await patchDeviceStatus(deviceCodeId);
    } catch (e) {
      print('Error storing device data: $e');
    }
  }

  Future<void> checkDeviceStatusBeforeSubmission() async {
    try {
      var box = await Hive.openBox('deviceData');
      final String status = box.get('status', defaultValue: '');

      if (status == '0') {
        print('Device code is expired.');
        // You can show a message to the user here using a dialog or snackbar
        return;
      }

      // Proceed with submission if the status is not 0
      print('Device code is valid. Proceeding with submission...');
    } catch (e) {
      print('Error checking device status: $e');
    }
  }

  Future<void> patchDeviceStatus(String deviceCodeId) async {
    final String url = 'http://192.168.1.113:8888/devicecodes/$deviceCodeId';
    final Map<String, dynamic> patchData = {
      'status': '0', // Set the status to 0
    };

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(patchData),
      );

      if (response.statusCode == 200) {
        print('Device status updated to 0 for deviceCodeId: $deviceCodeId');
      } else {
        print(
            'Failed to update device status. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error patching device status: $e');
    }
  }

  // Load device data from Hive
  Future<void> loadDeviceData() async {
    try {
      var box = await Hive.openBox('deviceData');
      _deviceCode = box.get('deviceCode', defaultValue: '');
      _branchName = box.get('branchName', defaultValue: '');
      _deviceCodeId = box.get('deviceCodeId', defaultValue: '');

      // Notify listeners about the changes
      notifyListeners();

      print(
          'Loaded device data: Device Code: $_deviceCode, Branch: $_branchName, Device Code ID: $_deviceCodeId');
    } catch (e) {
      print('Error loading device data: $e');
    }
  }
}
