import 'package:exfactor/screens/Sales/sales_create_deal.dart';
import 'package:flutter/material.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/services/saleService.dart';
import 'package:exfactor/utils/constants.dart';

class SalesHomeScreen extends StatefulWidget {
  const SalesHomeScreen({super.key});

  @override
  State<SalesHomeScreen> createState() => _SalesHomeScreenState();
}

class _SalesHomeScreenState extends State<SalesHomeScreen> {
  Map<String, dynamic>? userAssignedTargets;
  Map<String, double>? userAchievedSales;
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserAssignedTargets();
  }

  Future<void> _loadUserAssignedTargets() async {
    setState(() => isLoading = true);

    try {
      // Get assigned targets for current user using SaleService
      final assignedTargets = await SaleService.getCurrentUserAssignedTargets();
      print('Assigned targets: $assignedTargets');

      // Get all registered sales for current user using SaleService (ALL deals)
      final allRegisteredSales =
          await SaleService.getCurrentUserAllRegisteredSales();
      print('All registered sales: $allRegisteredSales');

      setState(() {
        userAssignedTargets = assignedTargets;
        userAchievedSales =
            allRegisteredSales; // Use ALL deals for progress tracking
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user assigned targets: $e');
      setState(() => isLoading = false);
    }
  }

  // Calculate progress percentage using SaleService
  double _calculateProgress(double achieved, double target) {
    return SaleService.calculateProgress(achieved, target);
  }

  // Get current month's target using SaleService
  double _getCurrentMonthTarget() {
    return SaleService.getCurrentMonthTarget(userAssignedTargets);
  }

  // Get current quarter's target using SaleService
  double _getCurrentQuarterTarget() {
    return SaleService.getCurrentQuarterTarget(userAssignedTargets);
  }

  // Get annual target using SaleService
  double _getAnnualTarget() {
    return SaleService.getAnnualTarget(userAssignedTargets);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userAssignedTargets == null
              ? _buildNoTargetsView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                  ),
                  child: Column(
                    children: [
                      // Section 1: Monthly Sales Card
                      _buildMonthlySalesCard(),

                      const SizedBox(height: 20),

                      // Section 2: Sales Analysis Card
                      _buildSalesAnalysisCard(),

                      const SizedBox(height: 20),

                      // Section 3: New Deal Register Button
                      _buildNewDealRegisterButton(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoTargetsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No targets assigned yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact your admin to assign sales targets',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySalesCard() {
    final annualTarget = _getAnnualTarget();
    final quarterlyTarget = _getCurrentQuarterTarget();
    final monthlyTarget = _getCurrentMonthTarget();

    // Get actual achieved values from deals (ALL deals regardless of status)
    final annualAchieved = userAchievedSales?['annual'] ?? 0;
    final quarterlyAchieved = userAchievedSales?['quarterly'] ?? 0;
    final monthlyAchieved = userAchievedSales?['monthly'] ?? 0;

    // Debug prints to verify calculations
    print('=== Sales Home Progress Debug ===');
    print('Annual Target: $annualTarget, Achieved: $annualAchieved');
    print('Quarterly Target: $quarterlyTarget, Achieved: $quarterlyAchieved');
    print('Monthly Target: $monthlyTarget, Achieved: $monthlyAchieved');
    print('===============================');

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
                percentage: _calculateProgress(annualAchieved, annualTarget),
                dealValue: formatCurrency(annualAchieved),
                targetValue: formatCurrency(annualTarget),
                color: cardDarkRed,
                cardWidth: 200,
              ),
              const SizedBox(width: 16),
              _buildSalesCard(
                title: "Quarterly Sales",
                percentage:
                    _calculateProgress(quarterlyAchieved, quarterlyTarget),
                dealValue: formatCurrency(quarterlyAchieved),
                targetValue: formatCurrency(quarterlyTarget),
                color: cardYellow,
                cardWidth: 200,
              ),
              const SizedBox(width: 16),
              _buildSalesCard(
                title: "Monthly Sales",
                percentage: _calculateProgress(monthlyAchieved, monthlyTarget),
                dealValue: formatCurrency(monthlyAchieved),
                targetValue: formatCurrency(monthlyTarget),
                color: cardDarkGreen,
                cardWidth: 200,
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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${percentage.toStringAsFixed(1)}%",
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
                      "Deal:",
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
                      "Target:",
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

  Widget _buildSalesAnalysisCard() {
    final monthlyTarget = _getCurrentMonthTarget();
    final monthlyAchieved = userAchievedSales?['monthly'] ?? 0;
    final remainingSales = monthlyTarget - monthlyAchieved;

    // Debug prints to verify calculations
    print('=== Sales Analysis Card Debug ===');
    print('Monthly Target: $monthlyTarget');
    print('Monthly Achieved: $monthlyAchieved');
    print('Remaining Sales: $remainingSales');
    print('================================');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Monthly Sales Analyze",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 16),

          // Sales metrics
          _buildSalesMetric(
              "Sales Target:", formatCurrency(monthlyTarget), false),
          const SizedBox(height: 8),
          _buildSalesMetric(
              "Registered Sales:", formatCurrency(monthlyAchieved), false),
          const SizedBox(height: 8),
          _buildSalesMetric(
              "Remaining Sales:", formatCurrency(remainingSales), true),
        ],
      ),
    );
  }

  Widget _buildSalesMetric(String label, String value, bool isRemaining) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isRemaining ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildNewDealRegisterButton() {
    return CustomButton(
      text: "New Deal Register",
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateDeal()),
        );
        // Refresh data after returning from deal creation
        _loadUserAssignedTargets();
      },
      backgroundColor: kPrimaryColor,
      width: double.infinity,
      height: 48,
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
