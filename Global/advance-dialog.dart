// import 'package:flutter/material.dart';

// class AdvanceAmountDialog extends StatefulWidget {
//   const AdvanceAmountDialog({Key? key}) : super(key: key);

//   @override
//   _AdvanceAmountDialogState createState() => _AdvanceAmountDialogState();

//   // Static method to show the dialog
//   static Future<Map<String, String>?> show(BuildContext context) {
//     return showDialog<Map<String, String>>(
//       context: context,
//       builder: (context) => const AdvanceAmountDialog(),
//     );
//   }
// }

// class _AdvanceAmountDialogState extends State<AdvanceAmountDialog>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;

//   final TextEditingController _remarksController = TextEditingController();
//   final TextEditingController _amountController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();

//     // Create an animation controller
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     );

//     // Create a scale animation with a curve for a bouncy effect
//     _scaleAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.elasticOut,
//     );

//     // Start the animation when the dialog is first shown
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _remarksController.dispose();
//     _amountController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ScaleTransition(
//       scale: _scaleAnimation,
//       child: AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         title: const Text(
//           'Cancel Order',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.deepPurple,
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Remarks TextField

//             TextField(
//               controller: _amountController,
//               decoration: InputDecoration(
//                 labelText: 'Advance Amount',
//                 prefixIcon:
//                     const Icon(Icons.attach_money, color: Colors.deepPurple),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                   borderSide:
//                       const BorderSide(color: Colors.deepPurple, width: 2),
//                 ),
//               ),
//               keyboardType: TextInputType.number,
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _amountController,
//               decoration: InputDecoration(
//                 labelText: 'SalesPerson Name',
//                 prefixIcon: const Icon(Icons.account_circle_outlined,
//                     color: Colors.deepPurple),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                   borderSide:
//                       const BorderSide(color: Colors.deepPurple, width: 2),
//                 ),
//               ),
//               keyboardType: TextInputType.number,
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _remarksController,
//               decoration: InputDecoration(
//                 labelText: 'Remarks',
//                 prefixIcon: const Icon(Icons.comment, color: Colors.deepPurple),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                   borderSide:
//                       const BorderSide(color: Colors.deepPurple, width: 2),
//                 ),
//               ),
//               maxLines: 2,
//               keyboardType: TextInputType.multiline,
//             ),

//             // Advance Amount TextField
//           ],
//         ),
//         actions: [
//           // Cancel Button
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text(
//               'Cancel',
//               style: TextStyle(color: Colors.red),
//             ),
//           ),

//           // Submit Button
//           ElevatedButton(
//             onPressed: () {
//               // Here you can add validation and processing logic
//               Navigator.of(context).pop({
//                 'remarks': _remarksController.text,
//                 'amount': _amountController.text,
//               });
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(15),
//               ),
//             ),
//             child: const Text('Submit'),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class AdvanceAmountDialog extends StatefulWidget {
  final double advanceAmount; // Accept advance amount as a parameter

  const AdvanceAmountDialog({Key? key, required this.advanceAmount})
      : super(key: key);

  @override
  _AdvanceAmountDialogState createState() => _AdvanceAmountDialogState();

  // Static method to show the dialog
  static Future<Map<String, String>?> show(BuildContext context,
      {required double advanceAmount}) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AdvanceAmountDialog(advanceAmount: advanceAmount),
    );
  }
}

class _AdvanceAmountDialogState extends State<AdvanceAmountDialog> {
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _salesPersonController = TextEditingController();
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    // Initialize the advance amount controller with the passed value
    _amountController =
        TextEditingController(text: widget.advanceAmount.toString());
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _amountController.dispose();
    _salesPersonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Cancel Order',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Disabled Advance Amount Field
          TextField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Advance Amount',
              prefixIcon:
                  const Icon(Icons.attach_money, color: Colors.deepPurple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide:
                    const BorderSide(color: Colors.deepPurple, width: 2),
              ),
            ),
            enabled: false, // Disable the field
          ),
          const SizedBox(height: 16),

          // Salesperson Name Field
          TextField(
            controller: _salesPersonController,
            decoration: InputDecoration(
              labelText: 'SalesPerson Name',
              prefixIcon: const Icon(Icons.account_circle_outlined,
                  color: Colors.deepPurple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide:
                    const BorderSide(color: Colors.deepPurple, width: 2),
              ),
            ),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),

          // Remarks Field
          TextField(
            controller: _remarksController,
            decoration: InputDecoration(
              labelText: 'Remarks',
              prefixIcon: const Icon(Icons.comment, color: Colors.deepPurple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide:
                    const BorderSide(color: Colors.deepPurple, width: 2),
              ),
            ),
            maxLines: 2,
            keyboardType: TextInputType.multiline,
          ),
        ],
      ),
      actions: [
        // Cancel Button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.red),
          ),
        ),

        // Submit Button
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'remarks': _remarksController.text,
              'salesPerson': _salesPersonController.text,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
