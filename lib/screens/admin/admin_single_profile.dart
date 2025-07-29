import 'package:exfactor/widgets/common/custom_app_bar_with_icon.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/widgets/utils_widget.dart';

class AdminSingleProfileScreen extends StatefulWidget {
  final String userEmail;

  const AdminSingleProfileScreen({Key? key, required this.userEmail})
      : super(key: key);

  @override
  State<AdminSingleProfileScreen> createState() =>
      _AdminSingleProfileScreenState();
}

class _AdminSingleProfileScreenState extends State<AdminSingleProfileScreen> {
  Map<String, dynamic>? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    try {
      final userEmail = widget.userEmail;
      if (userEmail == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      final userData = await SupabaseService.getUserByEmail(userEmail);
      setState(() {
        user = userData;
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
      backgroundColor: KbgColor,
      appBar: AppBar(
          title: Text(
        user != null
            ? "${user!['first_name'] ?? ''} ${user!['last_name'] ?? ''}"
            : "User Profile",
      )),

      // appBar: CustomAppBarWithIcon(
      //   icon: Icons.person,
      //   title: user != null
      //       ? "${user!['first_name'] ?? ''} ${user!['last_name'] ?? ''}"
      //       : "User Profile",
      // ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : user == null
                ? const Center(child: Text('User not found'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white,
                        backgroundImage: (user?['profile_image'] != null &&
                                (user?['profile_image'] as String).isNotEmpty)
                            ? NetworkImage(user!['profile_image'])
                            : const AssetImage('assets/images/it-avatar.webp')
                                as ImageProvider,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "Personal Information",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _infoRow('Full Name',
                                  "${user!['first_name'] ?? ''} ${user!['last_name'] ?? ''}"),
                              const Divider(thickness: 1),
                              _infoRow(
                                  'Date of Birth', user!['birthday'] ?? ''),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "Company  Information",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _infoRow('Position ', user!['position'] ?? ''),
                              const Divider(thickness: 1),
                              _infoRow('Role', user!['role'] ?? ''),
                              const Divider(thickness: 1),
                              _infoRow('Email Address', user!['email'] ?? ''),
                              const Divider(thickness: 1),
                              _infoRow('Mobile Number', user!['mobile'] ?? ''),
                              const Divider(thickness: 1),
                              _infoRow('Joined Date', user!['join_date'] ?? ''),
                              const Divider(thickness: 1),
                              _infoRow('Designation',
                                  user!['designation_date'] ?? ''),
                              const Divider(thickness: 1),
                              _infoRow('Supervisor', user!['supervisor'] ?? ''),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "Emergency Contact Information",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (user!['emergency_name'] != null)
                                _infoRow('Contact Name',
                                    user!['emergency_name'] ?? ''),
                              const Divider(thickness: 1),
                              if (user!['emergency_relationship'] != null)
                                _infoRow('Relationship',
                                    user!['emergency_relationship'] ?? ''),
                              const Divider(thickness: 1),
                              if (user!['emergency_number'] != null)
                                _infoRow('Contact number',
                                    user!['emergency_number'] ?? ''),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      CustomButton(
                        text: "Remove Member",
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remove Member'),
                              content: const Text(
                                  'Are you sure you want to remove this user?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('No'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            setState(() {
                              isLoading = true;
                            });
                            try {
                              final userIdInt =
                                  int.tryParse(user!['member_id'].toString());
                              if (userIdInt == null) {
                                if (mounted) {
                                  UserUtils.showToast(
                                    "Error: member_id is null or invalid.",
                                    Colors.red,
                                    context,
                                  );
                                }
                              } else {
                                await SupabaseService.deleteUser(userIdInt);
                                if (mounted) {
                                  UserUtils.showToast(
                                    "User removed successfully.",
                                    Colors.green,
                                    context,
                                  );
                                  // Navigate back with result
                                  if (context.mounted) {
                                    Navigator.of(context).pop('user_removed');
                                  }
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                UserUtils.showToast(
                                  "Failed to remove user: ${e.toString()}",
                                  Colors.red,
                                  context,
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            }
                          }
                        },
                        backgroundColor: cardDarkRed,
                        width: double.infinity / 2,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 4,
              child: Text('$label :',
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 6, child: Text(value)),
        ],
      ),
    );
  }
}
