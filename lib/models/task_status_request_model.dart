class TaskStatusRequestModel {
  final int? requestId;
  final int taskId;
  final int technicianId;
  final String requestedStatus;
  final bool approved;
  final DateTime createdAt;

  TaskStatusRequestModel({
    this.requestId,
    required this.taskId,
    required this.technicianId,
    required this.requestedStatus,
    required this.approved,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'task_id': taskId,
      'technician_id': technicianId,
      'requested_status': requestedStatus,
      'approved': approved,
      'created_at': createdAt.toIso8601String(),
    };
    if (requestId != null) {
      map['request_id'] = requestId as Object;
    }
    return map;
  }

  factory TaskStatusRequestModel.fromMap(Map<String, dynamic> map) {
    return TaskStatusRequestModel(
      requestId: map['request_id'] != null
          ? int.tryParse(map['request_id'].toString())
          : null,
      taskId: map['task_id'] is int
          ? map['task_id']
          : int.tryParse(map['task_id'].toString()) ?? 0,
      technicianId: map['technician_id'] is int
          ? map['technician_id']
          : int.tryParse(map['technician_id'].toString()) ?? 0,
      requestedStatus: map['requested_status'],
      approved: map['approved'] is bool
          ? map['approved']
          : map['approved'].toString() == 'true',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
