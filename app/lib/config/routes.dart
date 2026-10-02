import 'package:flutter/material.dart';

class AppRoutes {
  /// Root navigator, used where no BuildContext can be trusted (logout).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Lets screens (e.g. Home) refresh when a route above them is popped.
  static final RouteObserver<PageRoute<dynamic>> routeObserver =
      RouteObserver<PageRoute<dynamic>>();

  static void pushReplacement(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static void push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static void pop(BuildContext context) {
    Navigator.of(context).pop();
  }
}
