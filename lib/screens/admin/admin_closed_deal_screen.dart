import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:exfactor/services/dealService.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/screens/deal_deatils_screen.dart';
import 'package:exfactor/utils/constants.dart';
import 'package:exfactor/services/userService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminCloseDeal extends StatefulWidget {
  const AdminCloseDeal({super.key});

  @override
  State<AdminCloseDeal> createState() => _AdminCloseDealState();
}

class _AdminCloseDealState extends State<AdminCloseDeal> {
  List<Map<String, dynamic>> closedDeals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClosedDeals();
  }

  Future<void> _loadClosedDeals() async {
    setState(() => isLoading = true);

    try {
      // Get all deals from the database
      final allDeals = await SupabaseService.getAllDeals();
      print('📊 Total deals loaded: ${allDeals.length}');

      // Filter for closed deals (status: won)
      final closedDealsList = allDeals.where((deal) {
        final status = (deal['deal_status'] ?? '').toString().toLowerCase();
        return status == 'won';
      }).toList();

      print('✅ Closed deals found: ${closedDealsList.length}');

      // Debug: Print first deal structure
      if (closedDealsList.isNotEmpty) {
        print('🔍 First deal structure: ${closedDealsList.first}');
        print('🔍 First deal user_id: ${closedDealsList.first['user_id']}');
        print('🔍 First deal keys: ${closedDealsList.first.keys.toList()}');
      }

      // Load sales person names for each deal
      await _loadSalesPersonNames(closedDealsList);

      setState(() {
        closedDeals = closedDealsList;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading closed deals: $e');
      setState(() => isLoading = false);
    }
  }

  // Load sales person names for all deals
  Future<void> _loadSalesPersonNames(List<Map<String, dynamic>> deals) async {
    // Set initial loading state for all deals
    for (int i = 0; i < deals.length; i++) {
      deals[i]['sales_person_name'] = 'Loading...';
    }

    // Trigger UI update to show loading state
    if (mounted) {
      setState(() {});
    }

    for (int i = 0; i < deals.length; i++) {
      final deal = deals[i];
      final userId = deal['user_id'];

      print(
          'Processing deal $i: prospect=${deal['prospect_name']}, user_id=$userId');

      if (userId != null) {
        try {
          // Use direct Supabase query like in deal_deatils_screen.dart
          print('Trying direct Supabase query with user_id: $userId');

          final response = await Supabase.instance.client
              .from('user')
              .select('first_name, last_name')
              .eq('user_id', userId)
              .maybeSingle();

          Map<String, dynamic>? userData = response;

          // If user_id doesn't work, try with id field
          if (userData == null) {
            print('Trying with id field...');
            final response2 = await Supabase.instance.client
                .from('user')
                .select('first_name, last_name')
                .eq('id', userId)
                .maybeSingle();
            userData = response2;
          }

          if (userData != null) {
            final firstName = userData['first_name'] ?? '';
            final lastName = userData['last_name'] ?? '';
            final salesPersonName = '$firstName $lastName'.trim();

            if (salesPersonName.isNotEmpty) {
              deals[i]['sales_person_name'] = salesPersonName;
              print('✅ Success with direct query: $salesPersonName');
            } else {
              deals[i]['sales_person_name'] = 'Unknown User';
              print('⚠️ Sales person name is empty, showing "Unknown User"');
            }
          } else {
            // Fallback: Try to parse userId as int and use getUserByMemberId
            print('Direct query failed, trying getUserByMemberId...');
            final memberId = int.tryParse(userId);
            if (memberId != null) {
              final fallbackUserData =
                  await SupabaseService.getUserByMemberId(memberId);
              if (fallbackUserData != null) {
                final firstName = fallbackUserData['first_name'] ?? '';
                final lastName = fallbackUserData['last_name'] ?? '';
                final salesPersonName = '$firstName $lastName'.trim();

                deals[i]['sales_person_name'] = salesPersonName.isNotEmpty
                    ? salesPersonName
                    : 'Unknown User';
                print('✅ Success with getUserByMemberId: $salesPersonName');
              } else {
                deals[i]['sales_person_name'] = 'User Not Found';
                print('❌ User not found with getUserByMemberId for: $memberId');
              }
            } else {
              deals[i]['sales_person_name'] = 'User Not Found';
              print('❌ Could not parse userId as int: $userId');
            }
          }
        } catch (e) {
          print('❌ Error loading sales person name for deal $i: $e');
          deals[i]['sales_person_name'] = 'Error Loading';
        }
      } else {
        deals[i]['sales_person_name'] = 'No Sales Person';
        print('⚠️ No user_id found in deal data');
      }
    }
  }

  // Format currency values
  String _formatCurrency(double amount) {
    return formatCurrency(amount);
  }

  // Format date
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Closed Deals',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => _loadClosedDeals(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : closedDeals.isEmpty
              ? _buildNoDealsView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      ...closedDeals.map((deal) => _buildDealCard(deal)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoDealsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No won deals found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Won deals will appear here',
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

  Widget _buildDealCard(Map<String, dynamic> deal) {
    final prospectName = deal['prospect_name'] ?? 'N/A';
    final dealAmount = (deal['deal_amount'] ?? 0).toDouble();
    final product = deal['product'] ?? 'N/A';
    final createdDate = _formatDate(deal['created_at']);
    final dealStatus = deal['deal_status'] ?? 'N/A';

    // Get sales person name from the loaded data
    final salesPerson = deal['sales_person_name'] ?? 'Loading...';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DealDetails(dealData: deal),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with prospect name and amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Prospect Name: $prospectName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      _formatCurrency(dealAmount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cardGreen,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Details row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ' $salesPerson',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          if (salesPerson == 'Loading...')
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey[400]!,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Start date: $createdDate',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Status: ${dealStatus.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(dealStatus),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Product: $product',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'won':
        return cardGreen;
      default:
        return Colors.grey;
    }
  }
}
