import 'package:exfactor/screens/admin/admin_add_task_screen.dart';
import 'package:exfactor/screens/admin/admin_single_profile.dart';
import 'package:exfactor/screens/admin/admin_revenu_screen.dart';
import 'package:exfactor/screens/admin/admin_closed_deal_screen.dart';
import 'package:exfactor/screens/admin/admin_manage_project&TaskScreen.dart';
import 'package:exfactor/screens/admin/admin_notification_screen.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/widgets/utils_widget.dart';
import 'package:flutter/material.dart';
import 'package:exfactor/screens/admin/admin_single_project_screen.dart';
import 'package:exfactor/screens/admin/admin_single_task_screen.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/screens/task_screen.dart';

class AdminHome extends StatefulWidget {
  final Function(int)? onNavigateToTab; // Add callback for navigation
  const AdminHome({super.key, this.onNavigateToTab});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int liveProjectCount = 0;
  int todayNotificationCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() => isLoading = true);

    try {
      // Fetch projects and tasks
      final projects = await SupabaseService.getAllProjects();
      final tasks = await SupabaseService.getAllTasks();
      final notifications = await SupabaseService.getAllNotifications();

      final now = DateTime.now();

      // Calculate live projects count
      liveProjectCount = projects.where((p) {
        final status = (p['status'] ?? '').toString().toLowerCase();
        return status == 'on progress' || status == 'progress';
      }).length;

      // Calculate today's notifications count
      final today = DateTime(now.year, now.month, now.day);
      todayNotificationCount = notifications.where((n) {
        final dateStr = n['schedule_date'] ?? '';
        if (dateStr.isEmpty) return false;
        try {
          final notifDate = DateTime.parse(dateStr);
          final notifDay =
              DateTime(notifDate.year, notifDate.month, notifDate.day);
          return notifDay == today;
        } catch (_) {
          return false;
        }
      }).length;

      setState(() => isLoading = false);
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // Revenue Card
                  _buildRevenueCard(),

                  const SizedBox(height: 16),

                  // Total Closed Deals Card
                  _buildSimpleCard(
                    title: "Total Closed Deals",
                    value: "10",
                    color: cardGreen,
                    onTap: () {
                      // Navigate to Sales tab (index 1)
                      widget.onNavigateToTab?.call(1);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Live Projects Card
                  _buildSimpleCard(
                    title: "Live Projects",
                    value: liveProjectCount.toString(),
                    color: kPrimaryColor,
                    onTap: () {
                      // Navigate to Tasks tab (index 2)
                      widget.onNavigateToTab?.call(2);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Events Card
                  _buildSimpleCard(
                    title: "Events",
                    value: todayNotificationCount.toString(),
                    color: cardYellow,
                    onTap: () {
                      // Navigate to Events tab (index 3)
                      widget.onNavigateToTab?.call(3);
                    },
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.2, // Flexible height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color.fromARGB(255, 121, 121, 121), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to Sales tab (index 1) for Revenue
            widget.onNavigateToTab?.call(1);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title - Top Left
                const Text(
                  "Revenue",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),

                const Spacer(), // Pushes content to bottom

                // Progress Bar and Value - Bottom Center
                Column(
                  children: [
                    // Progress Bar
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.69, // 18M / 26M ≈ 0.69
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Value Text
                    Text(
                      "18,000,000.00 / 26,000,000.00",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cardGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleCard({
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.15, // Flexible height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color.fromARGB(255, 121, 121, 121), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title - Top Left
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),

                const Spacer(), // Pushes value to bottom

                // Value - Bottom Right
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
