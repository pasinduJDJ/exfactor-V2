import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/utils/constants.dart';
import 'package:exfactor/widgets/technical_notification_card.dart';
import 'package:flutter/material.dart';

class SupervisorNotification extends StatefulWidget {
  const SupervisorNotification({super.key});

  @override
  State<SupervisorNotification> createState() => _SupervisorNotificationState();
}

class _SupervisorNotificationState extends State<SupervisorNotification> {
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> todayNotifications = [];
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
    return Container(
      color: KbgColor,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          isLoading
              ? const CircularProgressIndicator()
              : todayNotifications.isEmpty
                  ? const Center(
                      child: Text('Notification Bucket Clear',
                          style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : TechnicalNotificationCard.buildNotificationCards(
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
                        await SupabaseService.deleteNotification(
                            notificationId);
                        await fetchNotifications();
                      },
                    ),
        ],
      ),
    );
  }
}
