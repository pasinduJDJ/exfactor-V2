import 'package:flutter/material.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/services/saleService.dart';
import 'package:exfactor/screens/deal_deatils_screen.dart';
import 'package:exfactor/utils/constants.dart';

class MemberSalesTrack extends StatefulWidget {
  final String memberId;
  final String memberName;

  const MemberSalesTrack({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  @override
  State<MemberSalesTrack> createState() => _MemberSalesTrackState();
}

class _MemberSalesTrackState extends State<MemberSalesTrack> {
  Map<String, dynamic>? memberAssignedTargets;
  Map<String, double>? memberAchievedSales;
  Map<String, List<Map<String, dynamic>>>? memberDealsByPeriod;
  bool isLoading = true;
  late String memberName;

  @override
  void initState() {
    super.initState();
    memberName = widget.memberName;
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    setState(() => isLoading = true);

    try {
      // Get member's assigned targets
      final assignedTargets =
          await SaleService.getMemberAssignedTargets(widget.memberId);

      // Get member's achieved sales
      final achievedSales =
          await SaleService.getMemberAchievedSales(widget.memberId);

      // Get member's deals by period
      final dealsByPeriod =
          await SaleService.getMemberDealsByPeriod(widget.memberId);

      setState(() {
        memberAssignedTargets = assignedTargets;
        memberAchievedSales = achievedSales;
        memberDealsByPeriod = dealsByPeriod;
        isLoading = false;
      });
    } catch (e) {
      // Remove print statement for production
      setState(() => isLoading = false);
    }
  }

  // Calculate progress percentage
  double _calculateProgress(double achieved, double target) {
    if (target == 0) return 0;
    return (achieved / target) * 100;
  }

  // Get current month's target
  double _getCurrentMonthTarget() {
    if (memberAssignedTargets == null) return 0;
    return SaleService.getCurrentMonthTarget(memberAssignedTargets);
  }

  // Get current quarter's target
  double _getCurrentQuarterTarget() {
    if (memberAssignedTargets == null) return 0;
    return SaleService.getCurrentQuarterTarget(memberAssignedTargets);
  }

  // Get annual target
  double _getAnnualTarget() {
    if (memberAssignedTargets == null) return 0;
    return SaleService.getAnnualTarget(memberAssignedTargets);
  }

  // Format currency values - using constants.dart utility
  String _formatCurrency(double amount) {
    return formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          memberName,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: backgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : memberAssignedTargets == null
              ? _buildNoTargetsView()
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Column(
                    children: [
                      // Section 1: Progress Circles
                      _buildProgressCirclesSection(),

                      const SizedBox(height: 15),

                      // Section 2: Deal Cards
                      _buildDealCardsSection(),

                      const SizedBox(height: 10),
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
            'No targets assigned to ${widget.memberName}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Contact admin to assign sales targets',
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

  Widget _buildProgressCirclesSection() {
    final annualTarget = _getAnnualTarget();
    final quarterlyTarget = _getCurrentQuarterTarget();
    final monthlyTarget = _getCurrentMonthTarget();

    final annualAchieved = memberAchievedSales?['annual'] ?? 0;
    final quarterlyAchieved = memberAchievedSales?['quarterly'] ?? 0;
    final monthlyAchieved = memberAchievedSales?['monthly'] ?? 0;

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
              _buildProgressCard(
                title: "Annual Sales",
                percentage: _calculateProgress(annualAchieved, annualTarget),
                achievedValue: _formatCurrency(annualAchieved),
                targetValue: _formatCurrency(annualTarget),
                color: cardDarkRed,
                cardWidth: 200,
              ),
              const SizedBox(width: 16),
              _buildProgressCard(
                title: "Quarterly Sales",
                percentage:
                    _calculateProgress(quarterlyAchieved, quarterlyTarget),
                achievedValue: _formatCurrency(quarterlyAchieved),
                targetValue: _formatCurrency(quarterlyTarget),
                color: cardYellow,
                cardWidth: 200,
              ),
              const SizedBox(width: 16),
              _buildProgressCard(
                title: "Monthly Sales",
                percentage: _calculateProgress(monthlyAchieved, monthlyTarget),
                achievedValue: _formatCurrency(monthlyAchieved),
                targetValue: _formatCurrency(monthlyTarget),
                color: cardDarkGreen,
                cardWidth: 200,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard({
    required String title,
    required double percentage,
    required String achievedValue,
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
                      "Achieved Sales:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      achievedValue,
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
                      "Target Sales:",
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

  Widget _buildDealCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Deal Details",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 16),

        // Monthly Deals Card
        _buildDealCard(
          title: "Monthly",
          deals: memberDealsByPeriod?['monthly'] ?? [],
          color: cardDarkGreen,
        ),

        const SizedBox(height: 16),

        // Quarterly Deals Card
        _buildDealCard(
          title: "Quarterly",
          deals: memberDealsByPeriod?['quarterly'] ?? [],
          color: cardYellow,
        ),

        const SizedBox(height: 16),

        // Annual Deals Card
        _buildDealCard(
          title: "Annual",
          deals: memberDealsByPeriod?['annual'] ?? [],
          color: cardDarkRed,
        ),
      ],
    );
  }

  Widget _buildDealCard({
    required String title,
    required List<Map<String, dynamic>> deals,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with circle and title
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Deals list (show only 5 initially)
          if (deals.isEmpty)
            const Center(
              child: Text(
                'No deals found',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            )
          else
            _DealListWidget(
              deals: deals,
              title: title,
            ),
        ],
      ),
    );
  }
}

// Separate widget for deal list with show more functionality
class _DealListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> deals;
  final String title;

  const _DealListWidget({
    required this.deals,
    required this.title,
  });

  @override
  State<_DealListWidget> createState() => _DealListWidgetState();
}

class _DealListWidgetState extends State<_DealListWidget> {
  bool showAll = false;

  @override
  Widget build(BuildContext context) {
    final displayDeals = showAll ? widget.deals : widget.deals.take(5).toList();
    final hasMoreDeals = widget.deals.length > 5;

    return Column(
      children: [
        // Deal items
        ...displayDeals.asMap().entries.map((entry) {
          final index = entry.key;
          final deal = entry.value;
          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DealDetails(dealData: deal),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Deal info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${deal['prospect_name'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${deal['deal_status'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Deal amount
                      Text(
                        formatCurrency((deal['deal_amount'] ?? 0).toDouble()),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
              // Divider (except for last item)
              if (index < displayDeals.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    color: Colors.grey[300],
                    height: 1,
                  ),
                ),
            ],
          );
        }).toList(),

        // Show More/Less button
        if (hasMoreDeals)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  showAll = !showAll;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue[50],
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      showAll
                          ? 'Show Less'
                          : 'Show More (${widget.deals.length - 5} more)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      showAll
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.blue[700],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return formatCurrency(amount);
  }
}

// Custom painter for rounded progress indicator
class RoundedProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  const RoundedProgressPainter({
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
