import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/technical_notification_card.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/notificationService.dart';

class NotificationScreen extends StatefulWidget {
  final String userRole; // 'technical', 'supervisor', 'sales'

  const NotificationScreen({Key? key, required this.userRole})
      : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final todayNotifications =
          await NotificationService.getTodayNotifications();
      final formattedNotifications =
          NotificationService.formatNotificationsForUI(todayNotifications);

      setState(() {
        notifications = formattedNotifications;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching notifications: $e');
    }
  }

  Future<void> _handleDeleteNotification(int notificationId) async {
    setState(() {
      isLoading = true;
    });

    final success =
        await NotificationService.deleteNotification(notificationId);

    if (success) {
      await fetchNotifications(); // Refresh the list
    } else {
      setState(() {
        isLoading = false;
      });
      // You could show an error message here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: KbgColor,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
                  ? const Center(
                      child: Text(
                        'Notification Bucket Clear',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : TechnicalNotificationCard.buildNotificationCards(
                      notifications,
                      onDelete: _handleDeleteNotification,
                    ),
        ],
      ),
    );
  }
}
