class ProjectModel {
  final int? projectId;
  final String projectTitle;
  final String projectDescription;
  final String clientName;
  final String contactPerson;
  final String contactPersonEmail;
  final String contactPersonPhone;
  final String clientCountry;
  final String projectStartDate;
  final String projectEndDate;
  final String projectStatus;
  final int supervisorId;

  ProjectModel({
    this.projectId,
    required this.projectTitle,
    required this.projectDescription,
    required this.clientName,
    required this.contactPerson,
    required this.contactPersonEmail,
    required this.contactPersonPhone,
    required this.clientCountry,
    required this.projectStartDate,
    required this.projectEndDate,
    required this.projectStatus,
    required this.supervisorId,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'title': projectTitle,
      'description': projectDescription,
      'client_name': clientName,
      'contact_person': contactPerson,
      'contact_email': contactPersonEmail,
      'contact_mobile': contactPersonPhone,
      'client_country': clientCountry,
      'start_date': projectStartDate,
      'end_date': projectEndDate,
      'status': projectStatus,
      'supervisor_id': supervisorId,
    };

    // Only include project_id if it's not null
    if (projectId != null) {
      map['project_id'] = projectId.toString();
    }

    return map;
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      projectId: map['project_id'] != null
          ? int.tryParse(map['project_id'].toString())
          : null,
      projectTitle: map['title'],
      projectDescription: map['description'],
      clientName: map['client_name'],
      contactPerson: map['contact_person'],
      contactPersonEmail: map['contact_email'],
      contactPersonPhone: map['contact_mobile'],
      clientCountry: map['client_country'],
      projectStartDate: map['start_date'],
      projectEndDate: map['end_date'],
      projectStatus: map['status'],
      supervisorId: map['supervisor_id'] is int
          ? map['supervisor_id']
          : int.tryParse(map['supervisor_id'].toString()) ?? 0,
    );
  }
}
