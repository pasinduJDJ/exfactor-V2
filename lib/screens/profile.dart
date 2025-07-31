import 'package:exfactor/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:exfactor/utils/colors.dart';
import '../widgets/common/custom_button.dart';
import '../services/userService.dart';
import 'update_profile.dart';
import 'reset_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userRole; // 'technical', 'supervisor', 'sales'

  const ProfileScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  String? supervisorName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _loading = true);

    try {
      final user = await UserService.getCurrentUser();
      if (user != null) {
        setState(() {
          _user = user;
        });

        // Get supervisor name if applicable
        if (user.supervisor != null && user.supervisor!.isNotEmpty) {
          final supervisorName =
              await UserService.getSupervisorName(user.supervisor);
          setState(() {
            this.supervisorName = supervisorName;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return const Center(child: Text('User not found.'));
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white,
              backgroundImage: (_user?.profileImage != null &&
                      _user!.profileImage!.isNotEmpty)
                  ? NetworkImage(_user!.profileImage!)
                  : _getDefaultAvatar() as ImageProvider,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personal Information",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  _infoCard({
                    'First Name': _user?.firstName ?? '',
                    'Last Name': _user?.lastName ?? '',
                    'Date Of Birth': _user?.birthday ?? '',
                  }),
                  const SizedBox(height: 5),
                  const Text(
                    "Company Information",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  _infoCard({
                    'Position': _user?.position ?? '',
                    'Role': _user?.role ?? '',
                    'Email Address': _user?.email ?? '',
                    'Mobile Number': _user?.mobile ?? '',
                    'Join Date': _user?.joinDate ?? '',
                    'Designation Date': _user?.designationDate ?? '',
                    'Supervisor': supervisorName ?? '',
                  }),
                  const SizedBox(height: 5),
                  const Text(
                    "Emergency Contact Information",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  _infoCard({
                    'Name': _user?.emergencyName ?? '',
                    'Contact Number': _user?.emergencyMobileNumber ?? '',
                    'Relationship': _user?.emergencyRelationship ?? '',
                  }),
                  const SizedBox(height: 5),
                  const Text(
                    "Account Actions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit, color: primaryColor),
                          title: const Text(
                            "Update Profile",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 13,
                            color: primaryColor,
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    UpdateProfileScreen(user: _user!),
                              ),
                            );
                            await _loadUserData(); // Refresh data after update
                          },
                        ),
                        const Divider(thickness: 1),
                        ListTile(
                          leading: const Icon(Icons.lock, color: primaryColor),
                          title: const Text(
                            "Reset Password",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 13,
                            color: primaryColor,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ResetPasswordScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget to create info card
  Widget _infoCard(Map<String, String> infoMap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: infoMap.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Get default avatar based on user role
  AssetImage _getDefaultAvatar() {
    switch (widget.userRole.toLowerCase()) {
      case 'technical':
        return const AssetImage('assets/images/it-avatar.webp');
      case 'supervisor':
        return const AssetImage('assets/images/manager-avatar.webp');
      case 'sales':
        return const AssetImage('assets/images/maledemo-avatar.jpg');
      default:
        return const AssetImage('assets/images/it-avatar.webp');
    }
  }
}
