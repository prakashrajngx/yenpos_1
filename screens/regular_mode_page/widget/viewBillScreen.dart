import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../Global/custom_button_reuse.dart';
import '../provider/cart_page_provider.dart';

class ViewSavedBillsWidget extends StatelessWidget {
  const ViewSavedBillsWidget({super.key});

  void _viewBills(BuildContext context) async {
    var box = await Hive.openBox('cartBox');
    List<Map<String, dynamic>> holdBills = box.values
        .where((bill) => bill is Map && bill['status'] == 'hold')
        .map((bill) => Map<String, dynamic>.from(bill as Map))
        .toList();

    if (holdBills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No saved bills available!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Saved Hold Bills'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: ListView.builder(
              itemCount: holdBills.length,
              itemBuilder: (context, index) {
                final bill = holdBills[index];
                return ListTile(
                  title: Text('Hold ID: ${bill['holdId']}'),
                  subtitle: Text(
                    'Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(bill['date']))}',
                  ),
                  onTap: () {
                    var saleProvider = Provider.of<CurrentSaleProvider>(context,
                        listen: false);
                    saleProvider.loadItemsFromBill(bill['items'],
                        merge: false, holdId: bill['holdId'].toString());

                    Navigator.of(context).pop(); // Close dialog
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.blue),
                    onPressed: () async {
                      await box.deleteAt(index); // Remove hold bill from Hive
                      Navigator.of(context).pop(); // Close dialog
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: 'ViewBills',
      onPressed: () => _viewBills(context),
      backgroundColor: Colors.white70,
      textColor: Colors.blue,
    );
  }
}






















// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';

// import '../../../Global/custom_button_reuse.dart';
// import '../provider/cart_page_provider.dart';

// class ViewSavedBillsWidget extends StatelessWidget {
//   const ViewSavedBillsWidget({super.key});

//   void _viewBills(BuildContext context) async {
//     var box = await Hive.openBox('holdinvoiceBox');
//     if (box.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text(
//             'No saved bills!',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 2),
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.only(left: 20, bottom: 20, right: 680),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       );
//       return;
//     }

//     List<Map<String, dynamic>> holdBills = box.values
//         .where((bill) =>
//             (bill as Map)['status'] == 'hold' && (bill)['items'].isNotEmpty)
//         .map((bill) => Map<String, dynamic>.from(bill as Map))
//         .toList();

//     if (holdBills.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text(
//             'No hold bills with items found!',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           backgroundColor: Colors.orange,
//           duration: const Duration(seconds: 2),
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.only(left: 20, bottom: 20, right: 680),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text(
//             'Saved Bills',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.blueAccent,
//             ),
//           ),
//           content: SizedBox(
//             width: 400,
//             height: 350,
//             child: ListView.builder(
//               itemCount: holdBills.length,
//               itemBuilder: (context, index) {
//                 final bill = holdBills[index];
//                 DateTime billDate = DateTime.parse(bill['date']);
//                 String formattedDate = DateFormat('dd-MM-yy').format(billDate);
//                 String formattedTime = DateFormat('hh:mm').format(billDate);

//                 return Card(
//                   elevation: 2,
//                   margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: ListTile(
//                     leading: Icon(
//                       Icons.receipt_long,
//                       color: Colors.blueAccent,
//                     ),
//                     title: Text(
//                       'Bill #${index + 1}',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const SizedBox(height: 4),
//                         Row(
//                           children: [
//                             const Icon(Icons.date_range, size: 16, color: Colors.grey),
//                             const SizedBox(width: 4),
//                             Text('Date: $formattedDate'),
//                           ],
//                         ),
//                         Row(
//                           children: [
//                             const Icon(Icons.access_time, size: 16, color: Colors.grey),
//                             const SizedBox(width: 4),
//                             Text('Time: $formattedTime'),
//                           ],
//                         ),
//                         Row(
//                           children: [
//                             const Icon(Icons.attach_money, size: 16, color: Colors.grey),
//                             const SizedBox(width: 4),
//                             Text('Total: ₹${bill['total']}'),
//                           ],
//                         ),
//                       ],
//                     ),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
//                       onPressed: () {
//                         var saleProvider = Provider.of<CurrentSaleProvider>(
//                           context,
//                           listen: false,
//                         );
//                         saleProvider.loadItemsFromBill(bill['items']);
//                         print('Selected Bill: $bill');
//                         Navigator.of(context).pop();
//                       },
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text(
//                 'Close',
//                 style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: CustomButton(
//         text: 'View Saved Bills',
//         onPressed: () => _viewBills(context),
//         backgroundColor: Colors.blueAccent,
//         textColor: Colors.white,
//       ),
//     );
//   }
// }
