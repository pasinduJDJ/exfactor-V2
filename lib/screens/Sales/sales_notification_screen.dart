import 'package:flutter/material.dart';
import '../notification_screen.dart';

class SalesNotificationScreen extends StatefulWidget {
  const SalesNotificationScreen({super.key});

  @override
  State<SalesNotificationScreen> createState() =>
      _SalesNotificationScreenState();
}

class _SalesNotificationScreenState extends State<SalesNotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return const NotificationScreen(userRole: 'sales');
  }
}
