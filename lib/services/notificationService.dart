import 'package:exfactor/services/superbase_service.dart';

class NotificationService {
  // Get all notifications for today (same logic for all user types)
  static Future<List<Map<String, dynamic>>> getTodayNotifications() async {
    try {
      final allNotifications = await SupabaseService.getAllNotifications();
      final todayNotifications = <Map<String, dynamic>>[];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var notification in allNotifications) {
        final dateStr = notification['schedule_date'] ?? '';
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
          todayNotifications.add(notification);
        }
      }

      return todayNotifications;
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Delete notification by ID
  static Future<bool> deleteNotification(int notificationId) async {
    try {
      await SupabaseService.deleteNotification(notificationId);
      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  // Format notification data for UI
  static List<Map<String, dynamic>> formatNotificationsForUI(
      List<Map<String, dynamic>> notifications) {
    return notifications
        .map((n) => {
              'notification_id': n['notification_id'],
              'title': n['title'] ?? '',
              'subtitle': n['message'] ?? '',
              'type': n['type'] ?? '',
              'submission_date': n['schedule_date'] ?? '',
            })
        .toList();
  }
}
