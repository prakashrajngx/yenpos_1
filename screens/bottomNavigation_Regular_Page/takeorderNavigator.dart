import 'package:flutter/material.dart';
import 'package:yenposapp/screens/take_away_orders/screens/all_orders_page/all_orders.dart';
import 'package:yenposapp/screens/take_away_orders/screens/current_orders_page/current_orders.dart';

class TakeAwayOrdersNavigator extends StatelessWidget {
  const TakeAwayOrdersNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (RouteSettings settings) {
        Widget page;

        // Default to Current Orders
        switch (settings.name) {
          case '/all-orders':
            page = const AllOrdersPage();
            break;
          case '/current-orders':
          default:
            page = const CurrentOrdersPage();
            break;
        }

        return MaterialPageRoute(
          builder: (context) => page,
          settings: settings,
        );
      },
    );
  }
}
