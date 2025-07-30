import 'package:flutter/material.dart';
import '../notification_screen.dart';

class SupervisorNotification extends StatefulWidget {
  const SupervisorNotification({super.key});

  @override
  State<SupervisorNotification> createState() => _SupervisorNotificationState();
}

class _SupervisorNotificationState extends State<SupervisorNotification> {
  @override
  Widget build(BuildContext context) {
    return const NotificationScreen(userRole: 'supervisor');
  }
}
