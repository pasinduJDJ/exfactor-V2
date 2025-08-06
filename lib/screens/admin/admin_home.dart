import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/services/targetService.dart';
import 'package:exfactor/services/dealService.dart';
import 'package:exfactor/services/projectService.dart';
import 'package:exfactor/screens/admin/admin_revenu_screen.dart';
import 'package:exfactor/screens/admin/admin_closed_deal_screen.dart';
import 'package:exfactor/utils/constants.dart';

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

  // Revenue tracking variables
  Map<String, dynamic>? revenueData;
  bool hasTarget = false;

  // Closed deals tracking
  int closedDealsCount = 0;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() => isLoading = true);

    try {
      // Fetch notifications
      final notifications = await SupabaseService.getAllNotifications();

      // Fetch revenue data
      final revenueProgress = await TargetService.calculateCompanyProgress();

      // Fetch closed deals count
      final closedDeals = await DealService.getTotalClosedDealsCount();

      // Fetch live projects count
      final liveProjects = await ProjectService.getTotalLiveProjectsCount();

      final now = DateTime.now();

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

      setState(() {
        isLoading = false;
        revenueData = revenueProgress;
        hasTarget = revenueProgress['hasTarget'] as bool;
        closedDealsCount = closedDeals;
        liveProjectCount = liveProjects;
      });
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
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Revenue Card
                  _buildRevenueCard(),

                  const SizedBox(height: 10),

                  // Total Closed Deals Card
                  _buildSimpleCard(
                    title: "Total Closed Deals",
                    value: formatWithCommas(closedDealsCount),
                    svgAsset: "assets/svg/Closed Deals.svg",
                    color: cardGreen,
                    onTap: () {
                      // Navigate to Closed Deals Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminCloseDeal(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Live Projects Card
                  _buildSimpleCard(
                    title: "Live Projects",
                    value: formatWithCommas(liveProjectCount),
                    svgAsset: "assets/svg/Projects.svg",
                    color: kPrimaryColor,
                    onTap: () {
                      // Navigate to Tasks tab (index 2)
                      widget.onNavigateToTab?.call(2);
                    },
                  ),

                  const SizedBox(height: 10),

                  // Events Card
                  _buildSimpleCard(
                    title: "Events",
                    value: formatWithCommas(todayNotificationCount),
                    svgAsset: "assets/svg/Events.svg",
                    color: cardYellow,
                    onTap: () {
                      // Navigate to Events tab (index 3)
                      widget.onNavigateToTab?.call(3);
                    },
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.18, // Uniform height
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
            // Navigate to Revenue Screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RevenueScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header Row with Title and Image
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    const Text(
                      "Revenue",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    // SVG Image
                    SvgPicture.asset(
                      "assets/svg/Revenue.svg",
                      width: 75,
                      height: 75,
                    ),
                  ],
                ),

                // Content based on target availability
                if (hasTarget && revenueData != null) ...[
                  // Progress Bar and Value - Bottom
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
                          widthFactor:
                              (revenueData!['progressPercentage'] as double)
                                  .clamp(0.0, 1.0),
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
                        "${formatCurrency(revenueData!['currentRevenue'])} / ${formatCurrency(revenueData!['targetAmount'])}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cardGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ] else ...[
                  // No target message
                  Expanded(
                    child: Center(
                      child: Text(
                        "What about Current Revenue",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
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
    required String svgAsset,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.18, // Uniform height
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    SvgPicture.asset(
                      svgAsset,
                      width: 100,
                      height: 100,
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
}
