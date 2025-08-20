import 'package:flutter/material.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/services/saleService.dart';
import 'package:exfactor/services/dealService.dart';
import 'sales_create_deal.dart';
import '../deal_deatils_screen.dart';
import 'package:exfactor/utils/constants.dart';
import 'package:exfactor/utils/string_utils.dart';

class SalesTaskScreen extends StatefulWidget {
  const SalesTaskScreen({super.key});

  @override
  State<SalesTaskScreen> createState() => _SalesTaskScreenState();
}

class _SalesTaskScreenState extends State<SalesTaskScreen> {
  Map<String, dynamic>? userAssignedTargets;
  Map<String, double>? userAchievedSales;
  List<Map<String, dynamic>> latestDeals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);

    try {
      final assignedTargets = await SaleService.getCurrentUserAssignedTargets();

      final achievedSales = await SaleService.getCurrentUserAchievedSales();

      final pipelineDeals = await SaleService.getCurrentUserPipelineDeals();

      final deals = await DealService.getCurrentUserDeals();

      setState(() {
        userAssignedTargets = assignedTargets;
        userAchievedSales = achievedSales;
        latestDeals = deals;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  double _calculateProgress(double achieved, double target) {
    return SaleService.calculateProgress(achieved, target);
  }

  double _getCurrentMonthTarget() {
    return SaleService.getCurrentMonthTarget(userAssignedTargets);
  }

  double _getCurrentQuarterTarget() {
    return SaleService.getCurrentQuarterTarget(userAssignedTargets);
  }

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
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: [
                      _buildMonthlySalesAnalyzeCard(),
                      const SizedBox(height: 15),
                      _buildNewDealRegisterButton(context),
                      const SizedBox(height: 15),
                      _buildLatestRegisteredDealsCard(),
                      const SizedBox(height: 15),
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

  Widget _buildMonthlySalesAnalyzeCard() {
    final annualTarget = _getAnnualTarget();
    final quarterlyTarget = _getCurrentQuarterTarget();
    final monthlyTarget = _getCurrentMonthTarget();

    // Calculate achieved sales (negotiation + won deals only)
    final annualAchieved = latestDeals.where((deal) {
      final dealDate = DateTime.parse(deal['created_at']);
      final now = DateTime.now();
      final dealStatus = (deal['deal_status'] ?? '').toString().toLowerCase();
      return dealDate.year == now.year &&
          (dealStatus == 'negotiation' || dealStatus == 'won');
    }).fold<double>(0, (sum, deal) => sum + (deal['deal_amount'] ?? 0));

    final quarterlyAchieved = latestDeals.where((deal) {
      final dealDate = DateTime.parse(deal['created_at']);
      final now = DateTime.now();
      final dealQuarter = ((dealDate.month - 1) / 3).floor() + 1;
      final currentQuarter = ((now.month - 1) / 3).floor() + 1;
      final dealStatus = (deal['deal_status'] ?? '').toString().toLowerCase();
      return dealDate.year == now.year &&
          dealQuarter == currentQuarter &&
          (dealStatus == 'negotiation' || dealStatus == 'won');
    }).fold<double>(0, (sum, deal) => sum + (deal['deal_amount'] ?? 0));

    final monthlyAchieved = latestDeals.where((deal) {
      final dealDate = DateTime.parse(deal['created_at']);
      final now = DateTime.now();
      final dealStatus = (deal['deal_status'] ?? '').toString().toLowerCase();
      return dealDate.year == now.year &&
          dealDate.month == now.month &&
          (dealStatus == 'negotiation' || dealStatus == 'won');
    }).fold<double>(0, (sum, deal) => sum + (deal['deal_amount'] ?? 0));

    // Calculate pipeline deals (all deals except lost)
    final annualPipeline = latestDeals.where((deal) {
      final dealDate = DateTime.parse(deal['created_at']);
      final now = DateTime.now();
      final dealStatus = (deal['deal_status'] ?? '').toString().toLowerCase();
      return dealDate.year == now.year && dealStatus != 'lost';
    }).fold<double>(0, (sum, deal) => sum + (deal['deal_amount'] ?? 0));

    final quarterlyPipeline = latestDeals.where((deal) {
      final dealDate = DateTime.parse(deal['created_at']);
      final now = DateTime.now();
      final dealQuarter = ((dealDate.month - 1) / 3).floor() + 1;
      final currentQuarter = ((now.month - 1) / 3).floor() + 1;
      final dealStatus = (deal['deal_status'] ?? '').toString().toLowerCase();
      return dealDate.year == now.year &&
          dealQuarter == currentQuarter &&
          dealStatus != 'lost';
    }).fold<double>(0, (sum, deal) => sum + (deal['deal_amount'] ?? 0));

    final monthlyPipeline = latestDeals.where((deal) {
      final dealDate = DateTime.parse(deal['created_at']);
      final now = DateTime.now();
      final dealStatus = (deal['deal_status'] ?? '').toString().toLowerCase();
      return dealDate.year == now.year &&
          dealDate.month == now.month &&
          dealStatus != 'lost';
    }).fold<double>(0, (sum, deal) => sum + (deal['deal_amount'] ?? 0));

    // Calculate remaining amounts (target - achievement)
    final annualRemaining = annualTarget - annualAchieved;
    final quarterlyRemaining = quarterlyTarget - quarterlyAchieved;
    final monthlyRemaining = monthlyTarget - monthlyAchieved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: [
              _buildSalesAnalyzeCard(
                title: "Monthly Sales Analysis",
                salesTarget: formatCurrency(monthlyTarget),
                registeredClients: latestDeals
                    .where((deal) {
                      final dealDate = DateTime.parse(deal['created_at']);
                      final now = DateTime.now();
                      final dealStatus =
                          (deal['deal_status'] ?? '').toString().toLowerCase();
                      return dealDate.year == now.year &&
                          dealDate.month == now.month &&
                          dealStatus != 'lost';
                    })
                    .length
                    .toString(),
                registeredSales: formatCurrency(monthlyPipeline),
                remainingSales: formatCurrency(monthlyRemaining),
              ),
              const SizedBox(width: 16),
              _buildSalesAnalyzeCard(
                title: "Quarterly Sales Analysis",
                salesTarget: formatCurrency(quarterlyTarget),
                registeredClients: latestDeals
                    .where((deal) {
                      final dealDate = DateTime.parse(deal['created_at']);
                      final now = DateTime.now();
                      final dealQuarter =
                          ((dealDate.month - 1) / 3).floor() + 1;
                      final currentQuarter = ((now.month - 1) / 3).floor() + 1;
                      final dealStatus =
                          (deal['deal_status'] ?? '').toString().toLowerCase();
                      return dealDate.year == now.year &&
                          dealQuarter == currentQuarter &&
                          dealStatus != 'lost';
                    })
                    .length
                    .toString(),
                registeredSales: formatCurrency(quarterlyPipeline),
                remainingSales: formatCurrency(quarterlyRemaining),
              ),
              const SizedBox(width: 16),
              _buildSalesAnalyzeCard(
                title: "Annual Sales Analysis",
                salesTarget: formatCurrency(annualTarget),
                registeredClients: latestDeals
                    .where((deal) {
                      final dealDate = DateTime.parse(deal['created_at']);
                      final now = DateTime.now();
                      final dealStatus =
                          (deal['deal_status'] ?? '').toString().toLowerCase();
                      return dealDate.year == now.year && dealStatus != 'lost';
                    })
                    .length
                    .toString(),
                registeredSales: formatCurrency(annualPipeline),
                remainingSales: formatCurrency(annualRemaining),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesAnalyzeCard({
    required String title,
    required String salesTarget,
    required String registeredClients,
    required String registeredSales,
    required String remainingSales,
  }) {
    return Container(
      width: 320,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 16),

          // Sales metrics
          _buildSalesMetric("Benchmark", salesTarget, false),
          const SizedBox(height: 8),
          _buildSalesMetric("Booked Clients", registeredClients, false),
          const SizedBox(height: 8),
          _buildSalesMetric("Booked", registeredSales, false),
          const SizedBox(height: 8),
          _buildSalesMetric("Remaining", remainingSales, true),
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

  Widget _buildNewDealRegisterButton(BuildContext context) {
    return CustomButton(
      text: "New Deal Register",
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateDeal()),
        );
        // Refresh data after returning from deal creation
        _loadUserData();
      },
      backgroundColor: kPrimaryColor,
      width: double.infinity,
      height: 48,
    );
  }

  Widget _buildLatestRegisteredDealsCard() {
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
            "Latest Registered Deals",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 16),

          // Show message if no deals
          if (latestDeals.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No deals registered yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create your first deal to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            // Deals list
            ...latestDeals.asMap().entries.map((entry) {
              final index = entry.key;
              final deal = entry.value;

              return Column(
                children: [
                  _buildDealCard(deal),
                  // Add divider except for last item
                  if (index < latestDeals.length - 1)
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
        ],
      ),
    );
  }

  Widget _buildDealCard(Map<String, dynamic> deal) {
    return GestureDetector(
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
        child: Row(
          children: [
            // Left side - Deal info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Prospect Name:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deal['prospect_name'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Product: ${deal['product'] ?? 'N/A'}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Status: ${StringUtils.capitalizeFirst(deal['deal_status']?.toString() ?? 'N/A')}",
                    style: TextStyle(
                      fontSize: 12,
                      color: deal['deal_status'] == 'closed' ||
                              deal['deal_status'] == 'won'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Right side - Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(deal['deal_amount'] ?? 0),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(deal['created_at']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
