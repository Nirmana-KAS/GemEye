import 'package:flutter/material.dart';

class AppRoutes {
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
