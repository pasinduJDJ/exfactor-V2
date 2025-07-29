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
      appBar: AppBar(title: Text("Admin Profile")),
      backgroundColor: const Color(0xFFe9ecef),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            const SizedBox(height: 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personal Information",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _infoCard({
                    'First Name': _user?.firstName ?? '',
                    'Last Name': _user?.lastName ?? '',
                  }),
                  const SizedBox(height: 16),
                  const Text(
                    "Company Information",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _infoCard({
                    'Position': _user?.position ?? '',
                    'Role': _user?.role ?? '',
                    'Email Address': _user?.email ?? '',
                    'Mobile Number': _user?.mobile ?? '',
                  }),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: "Update",
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminUpdateUserScreen(memberId: _user!.memberId),
                        ),
                      );
                      if (_memberId != null) await _fetchUser(_memberId!);
                    },
                    backgroundColor: cardGreen,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 5),
                  CustomButton(
                    text: "Log Out",
                    onPressed: () {
                      handleLogout(context);
                    },
                    backgroundColor: cardRed,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 5),
                  CustomButton(
                    text: "Reset Password",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminResetPasswordScreen(),
                        ),
                      );
                    },
                    backgroundColor: Colors.blueGrey,
                    width: double.infinity,
                  ),
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
