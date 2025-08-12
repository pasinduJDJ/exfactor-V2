import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateProfileScreen extends StatefulWidget {
  final UserModel user;

  const UpdateProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  UserModel? _user;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _joinDateController = TextEditingController();
  final _designationDateController = TextEditingController();
  final _roleController = TextEditingController();
  final _supervisorController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyMobileNumberController = TextEditingController();
  final _emergencyRelationshipController = TextEditingController();
  final _positionController = TextEditingController();

  DateTime? _selectedBirthday;
  DateTime? _selectedJoinDate;
  DateTime? _selectedDesignationDate;

  List<Map<String, dynamic>> _supervisors = [];
  int? _selectedSupervisorId;
  final List<String> _roles = ['Technical', 'Supervisor', 'Sales', 'Admin'];
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _fetchSupervisors();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _birthdayController.dispose();
    _joinDateController.dispose();
    _designationDateController.dispose();
    _roleController.dispose();
    _supervisorController.dispose();
    _emergencyNameController.dispose();
    _emergencyMobileNumberController.dispose();
    _emergencyRelationshipController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _fetchSupervisors() async {
    final supervisors = await SupabaseService.getSupervisors();
    setState(() {
      _supervisors = supervisors;
    });
  }

  void _initializeUser() {
    setState(() => _loading = true);

    _user = widget.user;
    _firstNameController.text = _user?.firstName ?? '';
    _lastNameController.text = _user?.lastName ?? '';
    _emailController.text = _user?.email ?? '';
    _mobileController.text = _user?.mobile ?? '';
    _birthdayController.text = _user?.birthday ?? '';
    _joinDateController.text = _user?.joinDate ?? '';
    _designationDateController.text = _user?.designationDate ?? '';
    _positionController.text = _user?.position ?? '';

    if (_user?.birthday != null && _user!.birthday!.isNotEmpty) {
      _selectedBirthday = DateTime.tryParse(_user!.birthday!);
    }
    if (_user?.joinDate != null && _user!.joinDate!.isNotEmpty) {
      _selectedJoinDate = DateTime.tryParse(_user!.joinDate!);
    }
    if (_user?.designationDate != null && _user!.designationDate!.isNotEmpty) {
      _selectedDesignationDate = DateTime.tryParse(_user!.designationDate!);
    }

    _selectedRole = _user?.role;

    if (_user?.supervisor != null && _user!.supervisor!.isNotEmpty) {
      final sup = _supervisors.firstWhere(
        (s) => s['member_id'].toString() == _user!.supervisor,
        orElse: () => {},
      );
      if (sup.isNotEmpty) {
        _selectedSupervisorId = sup['member_id'];
      }
    }

    _emergencyNameController.text = _user?.emergencyName ?? '';
    _emergencyMobileNumberController.text = _user?.emergencyMobileNumber ?? '';
    _emergencyRelationshipController.text = _user?.emergencyRelationship ?? '';

    setState(() => _loading = false);
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      final updatedData = {
        'member_id': widget.user.memberId,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'mobile': _mobileController.text,
        'birthday':
            _birthdayController.text.isEmpty ? null : _birthdayController.text,
        'join_date':
            _joinDateController.text.isEmpty ? null : _joinDateController.text,
        'designation_date': _designationDateController.text.isEmpty
            ? null
            : _designationDateController.text,
        'role': _selectedRole ?? '',
        'supervisor': _selectedSupervisorId?.toString() ?? '',
        'emergency_name': _emergencyNameController.text,
        'emergency_number': _emergencyMobileNumberController.text,
        'emergency_relationship': _emergencyRelationshipController.text,
        'position': _positionController.text,
      };

      await SupabaseService.updateUserProfile(updatedData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Update Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        toolbarHeight: 70,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("First Name"),
              TextFormField(
                controller: _firstNameController,
              ),
              const SizedBox(height: 15),
              const Text("Last Name"),
              TextFormField(
                controller: _lastNameController,
              ),
              const SizedBox(height: 15),
              const Text("Email Address"),
              TextFormField(
                controller: _emailController,
              ),
              const SizedBox(height: 15),
              const Text("Mobile Number"),
              TextFormField(
                controller: _mobileController,
              ),
              const SizedBox(height: 15),
              const Text("Select Birthday"),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedBirthday ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    _selectedBirthday = picked;
                    _birthdayController.text =
                        _selectedBirthday!.toIso8601String().split('T')[0];
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _birthdayController,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Select Join Date"),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedJoinDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    _selectedJoinDate = picked;
                    _joinDateController.text =
                        _selectedJoinDate!.toIso8601String().split('T')[0];
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _joinDateController,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Select Designation Date"),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDesignationDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    _selectedDesignationDate = picked;
                    _designationDateController.text = _selectedDesignationDate!
                        .toIso8601String()
                        .split('T')[0];
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _designationDateController,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Select Role"),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: _roles
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Select Supervisor"),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _selectedSupervisorId,
                items: _supervisors
                    .map((sup) => DropdownMenuItem<int>(
                          value: sup['member_id'],
                          child:
                              Text('${sup['first_name']} ${sup['last_name']}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSupervisorId = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Enter Position"),
              TextFormField(
                controller: _positionController,
              ),
              const SizedBox(height: 15),
              const Text("Enter Emergency Contact Name"),
              TextFormField(
                controller: _emergencyNameController,
              ),
              const SizedBox(height: 15),
              const Text("Enter Emergency Contact Number"),
              TextFormField(
                controller: _emergencyMobileNumberController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              const Text("Select Relationship"),
              TextFormField(
                controller: _emergencyRelationshipController,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
