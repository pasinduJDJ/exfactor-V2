import 'package:exfactor/models/user_model.dart';
import 'package:exfactor/screens/login_page.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';
import '../../widgets/common/custom_button.dart';
import 'admin_update_user.dart';
import '../../services/superbase_service.dart';
import 'admin_reset_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  UserModel? _user;
  bool _loading = true;
  String? supervisorName;
  int? _memberId;

  @override
  void initState() {
    super.initState();
    _initMemberIdAndFetchUser();
  }

  Future<void> _initMemberIdAndFetchUser() async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getInt('member_id');
    if (memberId != null) {
      setState(() {
        _memberId = memberId;
      });
      await _fetchUser(memberId);
      await _fetchSupervisorName();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchUser(int memberId) async {
    setState(() => _loading = true);
    final data = await SupabaseService.getUserByMemberId(memberId);
    if (data != null) {
      setState(() {
        _user = UserModel.fromMap(data);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchSupervisorName() async {
    if (_user?.supervisor != null && _user!.supervisor!.isNotEmpty) {
      final allUsers = await SupabaseService.getAllUsers();
      final sup = allUsers.firstWhere(
        (u) => u['member_id'].toString() == _user!.supervisor,
        orElse: () => {},
      );
      if (sup != null) {
        setState(() {
          supervisorName =
              ((sup['first_name'] ?? '') + ' ' + (sup['last_name'] ?? ''))
                  .trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_user == null) {
      return Center(child: Text('User not found.'));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Admin Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            const SizedBox(height: 15),
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white,
              backgroundImage: (_user?.profileImage != null &&
                      _user!.profileImage!.isNotEmpty)
                  ? NetworkImage(_user!.profileImage!)
                  : const AssetImage('assets/images/admin-avatar.webp')
                      as ImageProvider,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personal Information",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  _infoCard({
                    'First Name': _user?.firstName ?? '',
                    'Last Name': _user?.lastName ?? '',
                  }),
                  const SizedBox(height: 5),
                  const Text(
                    "Company Information",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  _infoCard({
                    'Position': _user?.position ?? '',
                    'Role': _user?.role ?? '',
                    'Email Address': _user?.email ?? '',
                    'Mobile Number': _user?.mobile ?? '',
                  }),
                  const SizedBox(height: 10),
                  // --- Start: New Card for Admin Actions ---
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
                                builder: (_) => AdminUpdateUserScreen(
                                    memberId: _user!.memberId),
                              ),
                            );
                            if (_memberId != null) await _fetchUser(_memberId!);
                          },
                        ),
                        const Divider(thickness: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.lock,
                            color: primaryColor,
                          ),
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
                                builder: (_) => AdminResetPasswordScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // --- End: New Card for Admin Actions ---
                  const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
}
