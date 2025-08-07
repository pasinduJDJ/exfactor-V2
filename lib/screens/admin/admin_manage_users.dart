import 'package:exfactor/screens/admin/admin_add_user.dart';
import 'package:exfactor/screens/admin/admin_profile.dart';
import 'package:exfactor/screens/login_page.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/widgets/user_card_view.dart';
import 'package:flutter/material.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'admin_reset_password_screen.dart';
import 'admin_main_screen.dart';

class MangeUsers extends StatefulWidget {
  const MangeUsers({super.key});

  @override
  State<MangeUsers> createState() => _MangeUsersState();
}

class _MangeUsersState extends State<MangeUsers> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final fetchedUsers = await SupabaseService.getAllUsers();
      // Filter users to show only Supervisors and Technicians
      final filteredUsers = fetchedUsers.where((user) {
        final role = user['role']?.toString().toLowerCase() ?? '';
        return role == 'supervisor' || role == 'technical' || role == 'sales';
      }).toList();

      setState(() {
        users = filteredUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor,
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              const SizedBox(
                height: 15,
              ),
              CustomButton(
                text: "Add New Members",
                width: double.infinity,
                backgroundColor: kPrimaryColor,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddUserScreen()),
                  );

                  if (result == 'user_added') {
                    fetchUsers();
                  } else if (result == 'user_removed') {
                    fetchUsers();
                  }
                },
              ),
              const SizedBox(
                height: 12,
              ),
              CustomButton(
                text: "Profile",
                width: double.infinity,
                backgroundColor: kWhite,
                textColor: primaryColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminProfile(),
                    ),
                  );
                },
                icon: Icon(Icons.person),
              ),
              const SizedBox(
                height: 15,
              ),
              isLoading
                  ? const CircularProgressIndicator()
                  : UserCard.buildUserGridCard(
                      users
                          .map((u) => {
                                'id': u['id']?.toString() ?? '',
                                'name':
                                    '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}',
                                'email': u['email']?.toString() ?? '',
                                'role': u['role']?.toString() ?? '',
                                'avatar': u['profile_image']?.toString() ?? '',
                              } as Map<String, String>)
                          .toList(),
                      onUserRemoved: (String result) {
                        if (result == 'user_removed') {
                          fetchUsers(); // Refresh the user list
                        }
                      },
                    ),
            ],
          ),
        ));
  }
}
