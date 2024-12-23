// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';

// import '../kot_screen/kot_screen.dart';
// import '../more_page/more_page.dart';

// import '../regular_mode_page/regular_mode_screen.dart';
// import '../take_away_orders/screens/current_orders_page/current_orders.dart';
// import '../transactionPage/transaction_page.dart';
// import 'takeorderNavigator.dart';

// class BottomNavigationPageRegularModeScreen extends StatefulWidget {
//   const BottomNavigationPageRegularModeScreen({super.key});

//   @override
//   // ignore: library_private_types_in_public_api
//   _BottomNavigationPageRegularModeScreenState createState() =>
//       _BottomNavigationPageRegularModeScreenState();
// }

// class _BottomNavigationPageRegularModeScreenState
//     extends State<BottomNavigationPageRegularModeScreen> {
//   int _currentIndex = 0;
//   late Box _invoiceBox;
//   bool _isHiveInitialized = false; // Loading state

//   final List<Widget> _pages = [
//     const RegularModeScreen(),
//     const PreInvoiceScreen(),
//     const TakeAwayOrdersNavigator(),
//     const TransactionPage(),

//     // const PromotionalOffersPage(),

//     const MorePage(),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _initializeHive();
//   }

//   Future<void> _initializeHive() async {
//     await Hive.initFlutter();
//     _invoiceBox = await Hive.openBox('invoiceBox');
//     setState(() {
//       _isHiveInitialized = true; // Set loading state to complete
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isHiveInitialized) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return SafeArea(
//       child: Scaffold(
//         body: _pages[_currentIndex],
//         bottomNavigationBar: Container(
//           decoration: const BoxDecoration(
//               border: Border(top: BorderSide(color: Colors.black12))),
//           child: ValueListenableBuilder(
//             valueListenable: _invoiceBox.listenable(),
//             builder: (context, box, widget) {
//               int transactionCount = box.values
//                   .where((item) => item['status'] == 'active')
//                   .length; // Corrected access to the 'status' property

//               return BottomNavigationBar(
//                 currentIndex: _currentIndex,
//                 onTap: (index) {
//                   setState(() {
//                     _currentIndex = index;
//                   });
//                 },
//                 backgroundColor: Colors.white,
//                 type: BottomNavigationBarType.fixed,
//                 selectedLabelStyle:
//                     const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//                 unselectedLabelStyle:
//                     const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//                 items: [
//                   const BottomNavigationBarItem(
//                     icon: Icon(Icons.grid_view),
//                     label: 'Take Away',
//                   ),
//                   const BottomNavigationBarItem(
//                     icon: Icon(Icons.receipt_sharp),
//                     label: 'Dine in',
//                   ),
//                   const BottomNavigationBarItem(
//                     icon: Icon(Icons.chrome_reader_mode),
//                     label: 'Take Away Orders',
//                   ),
//                   BottomNavigationBarItem(
//                     icon: Stack(
//                       children: [
//                         const Icon(Icons.sync),
//                         if (transactionCount > 0)
//                           Positioned(
//                             right: 0,
//                             child: Container(
//                               padding: const EdgeInsets.all(2),
//                               decoration: BoxDecoration(
//                                 color: Colors.red,
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               constraints: const BoxConstraints(
//                                 minWidth: 16,
//                                 minHeight: 16,
//                               ),
//                               child: Text(
//                                 '$transactionCount',
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                     label: 'Transactions',
//                   ),
//                   const BottomNavigationBarItem(
//                     icon: Icon(Icons.more_horiz),
//                     label: 'More',
//                   ),
//                 ],
//                 selectedItemColor: Colors.blue,
//                 unselectedItemColor: Colors.black,
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yenposapp/screens/bottomNavigation_Regular_Page/takeorderNavigator.dart';

import '../birthday_cakes_screen/screen/birthday_cakes_screen.dart';
import '../kot_screen/kot_screen.dart';
import '../more_page/more_page.dart';

import '../regular_mode_page/regular_mode_screen.dart';
import '../transactionPage/transaction_page.dart';

class BottomNavigationPageRegularModeScreen extends StatefulWidget {
  const BottomNavigationPageRegularModeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BottomNavigationPageRegularModeScreenState createState() =>
      _BottomNavigationPageRegularModeScreenState();
}

class _BottomNavigationPageRegularModeScreenState
    extends State<BottomNavigationPageRegularModeScreen> {
  int _currentIndex = 0;
  late Box _invoiceBox;
  bool _isHiveInitialized = false; // Loading state

  final List<Widget> _pages = [
    const RegularModeScreen(),
    const BirthdayCakesScreen(),
    const PreInvoiceScreen(),
    // const CurrentOrdersPage(),
    const TakeAwayOrdersNavigator(),
    const TransactionPage(),
    const MorePage(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    await Hive.initFlutter();
    _invoiceBox = await Hive.openBox('invoiceBox');
    setState(() {
      _isHiveInitialized = true; // Set loading state to complete
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isHiveInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black12))),
          child: ValueListenableBuilder(
            valueListenable: _invoiceBox.listenable(),
            builder: (context, box, widget) {
              int transactionCount = box.values
                  .where((item) => item['status'] == 'active')
                  .length; // Corrected access to the 'status' property

              return BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                backgroundColor: Colors.white,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view),
                    label: 'Take Away',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.cake),
                    label: 'Birth Day Cakes',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_sharp),
                    label: 'Dine in',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.chrome_reader_mode),
                    label: 'Order Management',
                  ),
                  BottomNavigationBarItem(
                    icon: Stack(
                      children: [
                        const Icon(Icons.sync),
                        if (transactionCount > 0)
                          Positioned(
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$transactionCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: 'Transactions',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.more_horiz),
                    label: 'More',
                  ),
                ],
                selectedItemColor: Colors.blue,
                unselectedItemColor: Colors.black,
              );
            },
          ),
        ),
      ),
    );
  }
}
