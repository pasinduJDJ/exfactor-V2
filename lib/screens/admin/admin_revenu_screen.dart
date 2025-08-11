import 'package:flutter/material.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/services/saleService.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/screens/sales_member_sales_track_sceen.dart';
import 'package:exfactor/utils/constants.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  List<Map<String, dynamic>> salesMembers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSalesMembersData();
  }

  Future<void> _loadSalesMembersData() async {
    setState(() => isLoading = true);

    try {
      // Get all users and filter sales members
      final allUsers = await SupabaseService.getAllUsers();
      final salesUsers = allUsers
          .where((user) =>
              (user['role'] ?? '').toString().toLowerCase() == 'sales')
          .toList();

      print('Found ${salesUsers.length} sales users');

      // Get revenue data for each sales member
      final membersWithRevenue = <Map<String, dynamic>>[];

      for (final user in salesUsers) {
        try {
          final memberId =
              user['member_id']; // Remove .toString() to keep as int
          final memberName =
              '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();

          print('Processing sales member: $memberName (ID: $memberId)');

          // Get member's assigned targets
          final assignedTargets =
              await SaleService.getMemberAssignedTargets(memberId.toString());

          // Get member's achieved sales
          final achievedSales =
              await SaleService.getMemberAchievedSales(memberId.toString());

          // Calculate current period targets and achievements
          final annualTarget = SaleService.getAnnualTarget(assignedTargets);
          final quarterlyTarget =
              SaleService.getCurrentQuarterTarget(assignedTargets);
          final monthlyTarget =
              SaleService.getCurrentMonthTarget(assignedTargets);

          final annualAchieved = achievedSales['annual'] ?? 0.0;
          final quarterlyAchieved = achievedSales['quarterly'] ?? 0.0;
          final monthlyAchieved = achievedSales['monthly'] ?? 0.0;

          // Calculate overall progress (using annual as primary)
          final totalTarget = annualTarget;
          final totalAchieved = annualAchieved;
          final progressPercentage =
              totalTarget > 0 ? (totalAchieved / totalTarget) * 100 : 0;

          print(
              'Member $memberName - Target: $totalTarget, Achieved: $totalAchieved, Progress: $progressPercentage%');

          // Validate data before adding
          if (memberName.isNotEmpty) {
            membersWithRevenue.add({
              'member_id': memberId.toString(),
              'member_name': memberName,
              'assigned_targets': assignedTargets,
              'achieved_sales': achievedSales,
              'annual_target': annualTarget,
              'quarterly_target': quarterlyTarget,
              'monthly_target': monthlyTarget,
              'annual_achieved': annualAchieved,
              'quarterly_achieved': quarterlyAchieved,
              'monthly_achieved': monthlyAchieved,
              'total_target': totalTarget,
              'total_achieved': totalAchieved,
              'progress_percentage': progressPercentage,
            });
          } else {
            print('Skipping member with empty name');
          }
        } catch (e) {
          print('Error processing sales member ${user['first_name']}: $e');
          // Continue with other members even if one fails
          continue;
        }
      }

      setState(() {
        salesMembers = membersWithRevenue;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading sales members data: $e');
      setState(() => isLoading = false);
    }
  }

  // Format currency values
  String _formatCurrency(double amount) {
    return formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Revenue Overview',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        backgroundColor: backgroundColor,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : salesMembers.isEmpty
                ? _buildNoMembersView()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        ...salesMembers
                            .map((member) => _buildMemberRevenueCard(member))
                            .toList(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      );
    } catch (e) {
      print('Error building revenue screen: $e');
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Revenue Overview',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please try again or contact support',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                  });
                  _loadSalesMembersData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildNoMembersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No sales members found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add sales members to view revenue data',
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

  Widget _buildMemberRevenueCard(Map<String, dynamic> member) {
    final memberName = member['member_name'] as String? ?? 'Unknown Member';
    final totalTarget = (member['total_target'] ?? 0).toDouble();
    final totalAchieved = (member['total_achieved'] ?? 0).toDouble();
    final progressPercentage = (member['progress_percentage'] ?? 0).toDouble();
    final memberId = member['member_id'] as String? ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MemberSalesTrack(
                  memberId: memberId,
                  memberName: memberName,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with member name and progress percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      memberName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getProgressColor(progressPercentage)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getProgressColor(progressPercentage)
                            .withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${formatWithCommas(progressPercentage, decimals: 1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(progressPercentage),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (progressPercentage / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getProgressColor(progressPercentage),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Revenue details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Target',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatCurrency(totalTarget),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Achieved',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatCurrency(totalAchieved),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getProgressColor(progressPercentage),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return cardGreen;
    if (percentage >= 60) return cardYellow;
    if (percentage >= 40) return cardDarkRed;
    return Colors.red;
  }
}
