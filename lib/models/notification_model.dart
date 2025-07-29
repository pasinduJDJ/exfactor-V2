class NotificationModel {
  final int? notification_id;
  final String title;
  final String message;
  final String type;
  final String schedule_date;

  NotificationModel({
    this.notification_id,
    required this.title,
    required this.message,
    required this.type,
    required this.schedule_date,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'message': message,
      'type': type,
      'schedule_date': schedule_date,
    };

    // Only include notification_id if it's not null
    if (notification_id != null) {
      map['notification_id'] = notification_id.toString();
    }

    return map;
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      notification_id: map['notification_id'] != null
          ? int.tryParse(map['notification_id'].toString())
          : null,
      title: map['title'],
      message: map['message'],
      type: map['type'],
      schedule_date: map['schedule_date'],
    );
  }
}
