import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminUpdateUserScreen extends StatefulWidget {
  final int memberId;

  const AdminUpdateUserScreen({Key? key, required this.memberId})
      : super(key: key);

  @override
  State<AdminUpdateUserScreen> createState() => _AdminUpdateUserScreenState();
}

class _AdminUpdateUserScreenState extends State<AdminUpdateUserScreen> {
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
  final List<String> _roles = ['Admin', 'Supervisor', 'Technician'];
  String? _selectedRole;

  int? _memberId;
  File? _pickedImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _memberId = widget.memberId;
    _fetchUser(widget.memberId);
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

  Future<void> _fetchUser(int memberId) async {
    setState(() => _loading = true);
    final data = await SupabaseService.getUserByMemberId(memberId);
    if (data != null) {
      _user = UserModel.fromMap(data);
      _firstNameController.text = _user?.firstName ?? '';
      _lastNameController.text = _user?.lastName ?? '';
      _emailController.text = _user?.email ?? '';
      _mobileController.text = _user?.mobile ?? '';
      _birthdayController.text = _user?.birthday ?? '';
      _joinDateController.text = _user?.joinDate ?? '';
      _designationDateController.text = _user?.designationDate ?? '';
      if (_user?.birthday != null && _user!.birthday!.isNotEmpty) {
        _selectedBirthday = DateTime.tryParse(_user!.birthday!);
      }
      if (_user?.joinDate != null && _user!.joinDate!.isNotEmpty) {
        _selectedJoinDate = DateTime.tryParse(_user!.joinDate!);
      }
      if (_user?.designationDate != null &&
          _user!.designationDate!.isNotEmpty) {
        _selectedDesignationDate = DateTime.tryParse(_user!.designationDate!);
      }
      _selectedRole = _user?.role;
      if (_user?.profileImage != null && _user!.profileImage!.isNotEmpty) {
        _profileImageUrl = _user!.profileImage;
      }
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
      _emergencyMobileNumberController.text =
          _user?.emergencyMobileNumber ?? '';
      _emergencyRelationshipController.text =
          _user?.emergencyRelationship ?? '';
      _positionController.text = _user?.position ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _fetchSupervisors() async {
    final supervisors = await SupabaseService.getSupervisors();
    setState(() {
      _supervisors = supervisors;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      String? imageUrl = _profileImageUrl;
      if (_pickedImage != null && _memberId != null) {
        final uploadedUrl = await SupabaseService.uploadProfileImage(
            _memberId.toString(), _pickedImage!.path);

        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
          await SupabaseService.updateUserProfileImage(_memberId!, imageUrl);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Image upload failed. Please try again.')),
            );
          }
          setState(() => _saving = false);
          return;
        }
      }
      final updatedData = {
        'member_id': _memberId,
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
        'profile_image': imageUrl,
      };

      await SupabaseService.updateUserProfile(updatedData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Error handling for production
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
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (_profileImageUrl != null &&
                                  _profileImageUrl!.isNotEmpty)
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : const AssetImage(
                                  'assets/images/admin-avatar.webp'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Change Profile Image'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text("First Name"),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Last Name"),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Email Address"),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Mobile Number"),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 15),
              const Text("Role"),
              TextFormField(
                controller: TextEditingController(text: _selectedRole ?? ''),
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 15),
              const Text("Enter Position"),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _handleSave,
                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
