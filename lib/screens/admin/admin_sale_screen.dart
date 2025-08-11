import 'package:exfactor/screens/admin/admin_add_new_target.dart';
import 'package:exfactor/screens/admin/admin_update_target.dart';
import 'package:exfactor/screens/sales_member_sales_track_sceen.dart';
import 'package:flutter/material.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/services/userService.dart';
import 'package:exfactor/services/saleService.dart';
import 'package:exfactor/utils/constants.dart';

class AdminSaleScreen extends StatefulWidget {
  const AdminSaleScreen({super.key});

  @override
  State<AdminSaleScreen> createState() => _AdminSaleScreenState();
}

class _AdminSaleScreenState extends State<AdminSaleScreen> {
  List<Map<String, dynamic>> salesTeamMembers = [];
  bool isLoading = true;
  bool isLoadingSalesData = true;

  // Company sales data
  Map<String, dynamic>? companySalesProgress;

  @override
  void initState() {
    super.initState();
    fetchSalesTeamMembers();
    fetchCompanySalesData();
  }

  Future<void> fetchSalesTeamMembers() async {
    setState(() => isLoading = true);
    try {
      final members = await UserService.getSalesTeamMembers();
      setState(() {
        salesTeamMembers = members;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchCompanySalesData() async {
    setState(() => isLoadingSalesData = true);
    try {
      final progress = await SaleService.getCompanySalesProgress();
      setState(() {
        companySalesProgress = progress;
        isLoadingSalesData = false;
      });
    } catch (e) {
      print('Error fetching company sales data: $e');
      setState(() => isLoadingSalesData = false);
    }
  }

  // Format currency values - using constants.dart utility
  String _formatCurrency(double amount) {
    return formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            // Section 1: Monthly Sales Card
            _buildMonthlySalesCard(),

            const SizedBox(height: 20),

            // Section 2: Action Buttons
            _buildActionButtons(),

            const SizedBox(height: 20),

            // Section 3: Sales Team Members
            _buildSalesTeamMembersCard(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySalesCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 400,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: [
              _buildSalesCard(
                title: "Annual Sales",
                percentage: companySalesProgress?['progress']?['annual'] ?? 0.0,
                dealValue: _formatCurrency(
                    companySalesProgress?['achieved']?['annual'] ?? 0),
                targetValue: _formatCurrency(
                    companySalesProgress?['targets']?['annual'] ?? 0),
                color: cardDarkRed,
                cardWidth: 200,
                isLoading: isLoadingSalesData,
              ),
              const SizedBox(width: 16),
              _buildSalesCard(
                title: "Quarterly Sales",
                percentage:
                    companySalesProgress?['progress']?['quarterly'] ?? 0.0,
                dealValue: _formatCurrency(
                    companySalesProgress?['achieved']?['quarterly'] ?? 0),
                targetValue: _formatCurrency(
                    companySalesProgress?['targets']?['quarterly'] ?? 0),
                color: cardYellow,
                cardWidth: 200,
                isLoading: isLoadingSalesData,
              ),
              const SizedBox(width: 16),
              _buildSalesCard(
                title: "Monthly Sales",
                percentage:
                    companySalesProgress?['progress']?['monthly'] ?? 0.0,
                dealValue: _formatCurrency(
                    companySalesProgress?['achieved']?['monthly'] ?? 0),
                targetValue: _formatCurrency(
                    companySalesProgress?['targets']?['monthly'] ?? 0),
                color: cardDarkGreen,
                cardWidth: 200,
                isLoading: isLoadingSalesData,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesCard({
    required String title,
    required double percentage,
    required String dealValue,
    required String targetValue,
    required Color color,
    required double cardWidth,
    required bool isLoading,
  }) {
    return Container(
      height: 720,
      width: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle with gradient
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.3),
                        color.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),

                // Loading indicator or progress circle
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  // Beautiful progress circle with gradient
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CustomPaint(
                      painter: RoundedProgressPainter(
                        progress: percentage / 100,
                        strokeWidth: 30,
                        backgroundColor: Colors.grey[200]!,
                        progressColor: color,
                      ),
                    ),
                  ),

                // Inner circle for depth effect
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),

                // Percentage text with shadow
                if (!isLoading)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${formatWithCommas(percentage, decimals: 1)}%",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Values with improved styling
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Achieve Sales:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      dealValue,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Target sales:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      targetValue,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: "Add New Target",
          onPressed: () async {
            final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AdminAddNewTarget()));
            if (result == true) {
              fetchCompanySalesData();
            }
          },
          backgroundColor: kPrimaryColor,
          width: double.infinity,
          height: 48,
          icon: const Icon(Icons.track_changes),
        ),
        const SizedBox(height: 10),
        CustomButton(
          text: "Update Target",
          onPressed: () async {
            final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AdminUpdateTarget()));

            // Refresh data after returning from update target screen
            if (result == true) {
              fetchCompanySalesData();
            }
          },
          backgroundColor: kPrimaryColor,
          width: double.infinity,
          height: 48,
          icon: const Icon(Icons.check),
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: "Refresh Data",
          onPressed: () {
            fetchCompanySalesData();
            fetchSalesTeamMembers();
          },
          textColor: Color.fromARGB(255, 0, 0, 0),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          width: double.infinity,
          height: 48,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildSalesTeamMembersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(255, 121, 121, 121),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            "Sales Team members",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 16),

          // Team Members List
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : salesTeamMembers.isEmpty
                  ? const Center(
                      child: Text(
                        'No sales team members found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Column(
                      children: salesTeamMembers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final member = entry.value;

                        return Column(
                          children: [
                            // Member Row
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => MemberSalesTrack(
                                      memberId: member['member_id'].toString(),
                                      memberName:
                                          '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}',
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  // Member Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          member['position'] ??
                                              'Sales Representative',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Profile Picture Placeholder
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[300],
                                    ),
                                    child: member['profile_image'] != null &&
                                            member['profile_image']
                                                .toString()
                                                .isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              member['profile_image'],
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.person,
                                                  color: Colors.grey[600],
                                                  size: 20,
                                                );
                                              },
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            color: Colors.grey[600],
                                            size: 20,
                                          ),
                                  ),
                                ],
                              ),
                            ),

                            // Divider (except for last item)
                            if (index < salesTeamMembers.length - 1)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: Colors.grey[300],
                                  height: 1,
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }
}

// Custom painter for rounded progress indicator
class RoundedProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  RoundedProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc with rounded endpoints
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -90 * (3.14159 / 180); // Start from top
    final sweepAngle = 2 * 3.14159 * progress; // Convert progress to radians

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
