import 'package:flutter/material.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/services/saleService.dart';
import 'package:exfactor/services/dealService.dart';
import 'sales_create_deal.dart';
import '../deal_deatils_screen.dart';

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
      // Get assigned targets for current user using SaleService
      final assignedTargets = await SaleService.getCurrentUserAssignedTargets();
      print('Assigned targets: $assignedTargets');

      // Get all registered sales for current user using SaleService (ALL deals)
      final allRegisteredSales =
          await SaleService.getCurrentUserAllRegisteredSales();
      print('All registered sales: $allRegisteredSales');

      // Get latest deals for current user using DealService
      final deals = await DealService.getCurrentUserDeals();
      print('Latest deals: $deals');

      setState(() {
        userAssignedTargets = assignedTargets;
        userAchievedSales = allRegisteredSales;
        latestDeals = deals;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
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
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),

                      // Section 1: Monthly Sales Analyze Card
                      _buildMonthlySalesAnalyzeCard(),

                      const SizedBox(height: 20),

                      // Section 2: New Deal Register Button
                      _buildNewDealRegisterButton(context),

                      const SizedBox(height: 20),

                      // Section 3: Latest Registered Deals
                      _buildLatestRegisteredDealsCard(),

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

  Widget _buildMonthlySalesAnalyzeCard() {
    final annualTarget = _getAnnualTarget();
    final quarterlyTarget = _getCurrentQuarterTarget();
    final monthlyTarget = _getCurrentMonthTarget();

    // Calculate registered sales (ALL deals regardless of status)
    final annualRegisteredSales = latestDeals.where((deal) {
      final dealDate = DateTime.parse(deal['created_at']);
      final now = DateTime.now();
      return dealDate.year == now.year;
    }).fold<double>(0, (sum, deal) => sum + (deal['deal_amount'] ?? 0));

    final quarterlyRegisteredSales = latestDeals.where((deal) {
      final dealDate = DateTime.parse(deal['created_at']);
      final now = DateTime.now();
      final dealQuarter = ((dealDate.month - 1) / 3).floor() + 1;
      final currentQuarter = ((now.month - 1) / 3).floor() + 1;
      return dealDate.year == now.year && dealQuarter == currentQuarter;
    }).fold<double>(0, (sum, deal) => sum + (deal['deal_amount'] ?? 0));

    final monthlyRegisteredSales = latestDeals.where((deal) {
      final dealDate = DateTime.parse(deal['created_at']);
      final now = DateTime.now();
      return dealDate.year == now.year && dealDate.month == now.month;
    }).fold<double>(0, (sum, deal) => sum + (deal['deal_amount'] ?? 0));

    // Calculate remaining amounts
    final annualRemaining = annualTarget - annualRegisteredSales;
    final quarterlyRemaining = quarterlyTarget - quarterlyRegisteredSales;
    final monthlyRemaining = monthlyTarget - monthlyRegisteredSales;

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
                title: "Monthly Sales Analyze",
                salesTarget: monthlyTarget.toStringAsFixed(0),
                registeredClients: latestDeals
                    .where((deal) {
                      final dealDate = DateTime.parse(deal['created_at']);
                      final now = DateTime.now();
                      return dealDate.year == now.year &&
                          dealDate.month == now.month;
                    })
                    .length
                    .toString(),
                registeredSales: monthlyRegisteredSales.toStringAsFixed(0),
                remainingSales: monthlyRemaining.toStringAsFixed(0),
              ),
              const SizedBox(width: 16),
              _buildSalesAnalyzeCard(
                title: "Quarterly Sales Analyze",
                salesTarget: quarterlyTarget.toStringAsFixed(0),
                registeredClients: latestDeals
                    .where((deal) {
                      final dealDate = DateTime.parse(deal['created_at']);
                      final now = DateTime.now();
                      final dealQuarter =
                          ((dealDate.month - 1) / 3).floor() + 1;
                      final currentQuarter = ((now.month - 1) / 3).floor() + 1;
                      return dealDate.year == now.year &&
                          dealQuarter == currentQuarter;
                    })
                    .length
                    .toString(),
                registeredSales: quarterlyRegisteredSales.toStringAsFixed(0),
                remainingSales: quarterlyRemaining.toStringAsFixed(0),
              ),
              const SizedBox(width: 16),
              _buildSalesAnalyzeCard(
                title: "Annual Sales Analyze",
                salesTarget: annualTarget.toStringAsFixed(0),
                registeredClients: latestDeals
                    .where((deal) {
                      final dealDate = DateTime.parse(deal['created_at']);
                      final now = DateTime.now();
                      return dealDate.year == now.year;
                    })
                    .length
                    .toString(),
                registeredSales: annualRegisteredSales.toStringAsFixed(0),
                remainingSales: annualRemaining.toStringAsFixed(0),
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
          _buildSalesMetric("Sales Target:", salesTarget, false),
          const SizedBox(height: 8),
          _buildSalesMetric("Registered Clients:", registeredClients, false),
          const SizedBox(height: 8),
          _buildSalesMetric("Registered Sales:", registeredSales, false),
          const SizedBox(height: 8),
          _buildSalesMetric("Remaining Sales:", remainingSales, true),
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
                    "Status: ${deal['deal_status'] ?? 'N/A'}",
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
                  "\$${(deal['deal_amount'] ?? 0).toStringAsFixed(0)}",
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
