class UserModel {
  final String? userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? mobile;
  final String? birthday;
  final String? joinDate;
  final String? designationDate;
  final String? role;
  final String? profileImage;
  final String? supervisor;
  final String? emergencyName;
  final String? emergencyMobileNumber;
  final String? emergencyRelationship;
  final String? position;
  final int memberId;

  UserModel({
    this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.mobile,
    this.birthday,
    this.joinDate,
    this.designationDate,
    this.role,
    this.profileImage,
    this.supervisor,
    this.emergencyName,
    this.emergencyMobileNumber,
    this.emergencyRelationship,
    this.position,
    required this.memberId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      'birthday': birthday,
      'join_date': joinDate,
      'designation_date': designationDate,
      'role': role,
      'profile_image': profileImage,
      'supervisor': supervisor,
      'emergency_name': emergencyName,
      'emergency_number': emergencyMobileNumber,
      'emergency_relationship': emergencyRelationship,
      'position': position,
      'member_id': memberId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      email: map['email'],
      mobile: map['mobile'],
      birthday: map['birthday']?.toString(),
      joinDate: map['join_date']?.toString(),
      designationDate: map['designation_date']?.toString(),
      role: map['role'],
      profileImage: map['profile_image'],
      supervisor: map['supervisor'],
      emergencyName: map['emergency_name'],
      emergencyMobileNumber: map['emergency_number'],
      emergencyRelationship: map['emergency_relationship'],
      position: map['position'],
      memberId: map['member_id'] is int
          ? map['member_id']
          : int.tryParse(map['member_id']?.toString() ?? '0') ?? 0,
    );
  }

  UserModel copyWith({
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    String? birthday,
    String? joinDate,
    String? designationDate,
    String? role,
    String? profileImage,
    String? supervisor,
    String? emergencyName,
    String? emergencyMobileNumber,
    String? emergencyRelationship,
    String? position,
    int? memberId,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      birthday: birthday ?? this.birthday,
      joinDate: joinDate ?? this.joinDate,
      designationDate: designationDate ?? this.designationDate,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      supervisor: supervisor ?? this.supervisor,
      emergencyName: emergencyName ?? this.emergencyName,
      emergencyMobileNumber:
          emergencyMobileNumber ?? this.emergencyMobileNumber,
      emergencyRelationship:
          emergencyRelationship ?? this.emergencyRelationship,
      position: position ?? this.position,
      memberId: memberId ?? this.memberId,
    );
  }
}
