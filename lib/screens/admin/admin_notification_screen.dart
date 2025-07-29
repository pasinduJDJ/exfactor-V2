import 'package:exfactor/screens/admin/admin_add_notification.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/widgets/notification_card_view.dart';
import 'admin_notification_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:exfactor/services/superbase_service.dart';

class AdminNotificationScreen extends StatelessWidget {
  const AdminNotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _AdminNotificationScreenBody();
  }
}

class _AdminNotificationScreenBody extends StatefulWidget {
  @override
  State<_AdminNotificationScreenBody> createState() =>
      _AdminNotificationScreenBodyState();
}

class _AdminNotificationScreenBodyState
    extends State<_AdminNotificationScreenBody> {
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> todayNotifications = [];
  List<Map<String, dynamic>> futureNotifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final fetchedNotifications = await SupabaseService.getAllNotifications();
      notifications = fetchedNotifications;
      todayNotifications.clear();
      futureNotifications.clear();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var n in notifications) {
        final dateStr = n['schedule_date'] ?? '';
        if (dateStr.isEmpty) continue;
        DateTime? notifDate;
        try {
          notifDate = DateTime.parse(dateStr);
        } catch (_) {
          continue;
        }
        final notifDay =
            DateTime(notifDate.year, notifDate.month, notifDate.day);
        if (notifDay == today) {
          todayNotifications.add(n);
        } else if (notifDay.isAfter(today)) {
          futureNotifications.add(n);
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          const SizedBox(
            height: 30,
          ),
          CustomButton(
            text: "Add Alert",
            width: double.infinity,
            backgroundColor: kPrimaryColor,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AdminAddNotificationScreen()),
              );

              if (result == 'notification_added') {
                fetchNotifications(); // Refresh after a notification is added
              }
            },
          ),
          const SizedBox(
            height: 20,
          ),
          const Row(
            children: [
              Text(
                "Notification ",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              )
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          const SizedBox(
            height: 20,
          ),
          const Row(
            children: [
              Text(
                "Today Notification ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          isLoading
              ? const CircularProgressIndicator()
              : NotificationCard.buildNotificationCards(
                  todayNotifications
                      .map((n) => {
                            'notification_id': n['notification_id'],
                            'title': n['title'] ?? '',
                            'subtitle': n['message'] ?? '',
                            'type': n['type'] ?? '',
                            'submission_date': n['schedule_date'] ?? '',
                          })
                      .toList(),
                  onDelete: (int notificationId) async {
                    setState(() {
                      isLoading = true;
                    });
                    await SupabaseService.deleteNotification(notificationId);
                    await fetchNotifications();
                  },
                  onEdit: (notification) async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminNotificationEditScreen(
                            notification: notification),
                      ),
                    );
                    if (result == true) {
                      await fetchNotifications();
                    }
                  },
                ),
          const SizedBox(
            height: 20,
          ),
          const Row(
            children: [
              Text(
                "Up coming Notification ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          isLoading
              ? const CircularProgressIndicator()
              : NotificationCard.buildNotificationCards(
                  futureNotifications
                      .map((n) => {
                            'notification_id': n['notification_id'],
                            'title': n['title'] ?? '',
                            'subtitle': n['message'] ?? '',
                            'type': n['type'] ?? '',
                            'submission_date': n['schedule_date'] ?? '',
                          })
                      .toList(),
                  onDelete: (int notificationId) async {
                    setState(() {
                      isLoading = true;
                    });
                    await SupabaseService.deleteNotification(notificationId);
                    await fetchNotifications();
                  },
                  onEdit: (notification) async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminNotificationEditScreen(
                            notification: notification),
                      ),
                    );
                    if (result == true) {
                      await fetchNotifications();
                    }
                  },
                ),
        ],
      ),
    );
  }
}
