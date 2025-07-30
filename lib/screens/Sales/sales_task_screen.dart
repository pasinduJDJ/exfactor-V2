import 'package:flutter/material.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'sales_create_deal.dart';
import '../deal_deatils_screen.dart';

class SalesTaskScreen extends StatefulWidget {
  const SalesTaskScreen({super.key});

  @override
  State<SalesTaskScreen> createState() => _SalesTaskScreenState();
}

class _SalesTaskScreenState extends State<SalesTaskScreen> {
  // Sample data for latest registered deals
  final List<Map<String, String>> latestDeals = [
    {
      'prospectName': 'John Smith',
      'product': 'Product A',
      'amount': '400,000.00',
    },
    {
      'prospectName': 'Sarah Johnson',
      'product': 'Product B',
      'amount': '250,000.00',
    },
    {
      'prospectName': 'Mike Wilson',
      'product': 'Product C',
      'amount': '180,000.00',
    },
    {
      'prospectName': 'Emily Davis',
      'product': 'Product D',
      'amount': '320,000.00',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
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

  Widget _buildMonthlySalesAnalyzeCard() {
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
                salesTarget: "400,000",
                registeredClients: "3",
                registeredSales: "100,000",
                remainingSales: "300,000",
              ),
              const SizedBox(width: 16),
              _buildSalesAnalyzeCard(
                title: "Quarterly Sales Analyze",
                salesTarget: "400,000",
                registeredClients: "3",
                registeredSales: "100,000",
                remainingSales: "300,000",
              ),
              const SizedBox(width: 16),
              _buildSalesAnalyzeCard(
                title: "Annual Sales Analyze",
                salesTarget: "400,000",
                registeredClients: "3",
                registeredSales: "100,000",
                remainingSales: "300,000",
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
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateDeal()),
        );
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

  Widget _buildDealCard(Map<String, String> deal) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DealDetails()),
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
                    "Prospect Name :",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deal['product'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Right side - Amount
            Text(
              deal['amount'] ?? '',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
