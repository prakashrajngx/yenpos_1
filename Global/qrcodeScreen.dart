// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';

// class ScannerScreen extends StatelessWidget {
//   final Function(String) onScanComplete;

//   const ScannerScreen({required this.onScanComplete, Key? key})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Set the device orientation to landscape when this screen is displayed
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeRight,
//       DeviceOrientation.landscapeLeft,
//     ]);

//     return WillPopScope(
//       onWillPop: () async {
//         // Restore orientation when the screen is closed
//         SystemChrome.setPreferredOrientations([
//           DeviceOrientation.landscapeRight,
//           DeviceOrientation.landscapeLeft,
//         ]);
//         return true;
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           automaticallyImplyLeading: false, // Hide back button
//           title: const Text("Scan Code"),
//         ),
//         body: Column(
//           children: [
//             Expanded(
//               child: AiBarcodeScanner(
//                 onDispose: () {
//                   debugPrint("Scanner disposed!");
//                 },
//                 hideGalleryButton: true,
//                 hideSheetDragHandler: true,
//                 hideSheetTitle: true,
//                 onDetect: (BarcodeCapture capture) async {
//                   if (capture.barcodes.isNotEmpty) {
//                     final scannedValue = capture.barcodes.first.rawValue;
//                     if (scannedValue != null) {
//                       debugPrint("Scanned Code: $scannedValue");
//                       onScanComplete(scannedValue); // Pass scanned value
//                       Navigator.pop(context); // Exit the scanner
//                     }
//                   }
//                 },
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: ElevatedButton(
//                 onPressed: () {
//                   // Restore orientation before exiting
//                   SystemChrome.setPreferredOrientations([
//                     DeviceOrientation.landscapeRight,
//                     DeviceOrientation.landscapeLeft,
//                   ]);
//                   Navigator.pop(context); // Allow exiting without scanning
//                 },
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   backgroundColor: Colors.red,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30.0),
//                   ),
//                 ),
//                 child: const Text("Cancel"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatelessWidget {
  final Function(String) onScanComplete;

  const ScannerScreen({required this.onScanComplete, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set the device orientation to landscape when this screen is displayed
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    return WillPopScope(
      onWillPop: () async {
        // Restore orientation when the screen is closed
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Hide back button
          title: const Text("Scan Code"),
        ),
        body: Column(
          children: [
            Expanded(
              child: MobileScanner(
                controller: MobileScannerController(
                  detectionSpeed: DetectionSpeed.normal,
                  facing: CameraFacing.back,
                ),
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final scannedValue = barcodes.first.rawValue;
                    if (scannedValue != null) {
                      debugPrint("Scanned Code: $scannedValue");
                      onScanComplete(scannedValue); // Pass scanned value
                      Navigator.pop(context); // Exit the scanner
                    }
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Restore orientation before exiting
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                    DeviceOrientation.portraitDown,
                    DeviceOrientation.landscapeRight,
                    DeviceOrientation.landscapeLeft,
                  ]);
                  Navigator.pop(context); // Allow exiting without scanning
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text("Cancel"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
