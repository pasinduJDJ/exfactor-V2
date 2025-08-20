import 'package:flutter/material.dart';
import 'package:exfactor/utils/colors.dart';
import 'deal_details_update_screen.dart';
import 'package:exfactor/services/dealService.dart';
import 'package:exfactor/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exfactor/utils/string_utils.dart';

class DealDetails extends StatefulWidget {
  final Map<String, dynamic>? dealData;

  const DealDetails({super.key, this.dealData});

  @override
  State<DealDetails> createState() => _DealDetailsState();
}

class _DealDetailsState extends State<DealDetails> {
  // Real deal data from database or default sample data
  late Map<String, String> dealData;
  late Map<String, String> contactData;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.dealData != null) {
      // Use real deal data from database
      dealData = {
        'prospectName': widget.dealData!['prospect_name'] ?? 'N/A',
        'dealSize': formatCurrency(widget.dealData!['deal_amount'] ?? 0),
        'dealStatus': _formatDealStatus(widget.dealData!['deal_status']),
        'product': widget.dealData!['product'] ?? 'N/A',
        'createdDate': _formatDate(widget.dealData!['created_at']),
        'salesPerson':
            'Loading...', // Will be updated with actual sales person name
        'LegacySystem': widget.dealData!['current_solution'] ?? 'N/A',
      };

      contactData = {
        'country': widget.dealData!['country'] ?? 'N/A',
        'city': widget.dealData!['city'] ?? 'N/A',
        'phoneNumber': widget.dealData!['phone_number'] ?? 'N/A',
        'mobileNumber': widget.dealData!['mobile_number'] ?? 'N/A',
        'email': widget.dealData!['email'] ?? 'N/A',
        'website': widget.dealData!['website'] ?? 'N/A',
      };

      // Load sales person name asynchronously
      _loadSalesPersonName();
    } else {
      // Fallback to sample data if no deal data provided
      dealData = {
        'prospectName': 'ABC Product',
        'dealSize': formatCurrency(254000.00),
        'dealStatus': 'Active',
        'product': 'Odoo POS',
        'createdDate': '2025-07-25',
        'salesPerson': 'Mohan D',
        'legacySystem': 'Manullay',
      };

      contactData = {
        'country': 'Sri Lanka',
        'city': 'Colombo',
        'phoneNumber': '0767066455',
        'mobileNumber': '0750750879',
        'email': 'dp@exfysy.com',
        'website': 'sdfwifjnwerg.com',
      };
    }
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

  String _formatDealStatus(String? status) {
    if (status == null) return 'N/A';

    // Map status values to display names
    final statusMap = {
      'active': 'Active',
      'pending': 'Pending',
      'in_progress': 'In Progress',
      'negotiation': 'Negotiation',
      'proposal_sent': 'Proposal Sent',
      'closed': 'Closed',
      'won': 'Won',
      'lost': 'Lost',
      'cancelled': 'Cancelled',
    };

    final lower = status.toLowerCase();
    return statusMap[lower] ??
        StringUtils.capitalizeFirst(lower, fallback: 'N/A');
  }

  // Load sales person name from user_id in deal data
  Future<void> _loadSalesPersonName() async {
    try {
      if (widget.dealData != null && widget.dealData!['user_id'] != null) {
        final userId = widget.dealData!['user_id'] as String;
        print('Loading sales person name for user ID: $userId');

        // Try to get user data using direct Supabase query since getUserById has issues
        // The user_id in deals table should map to the user table
        final response = await Supabase.instance.client
            .from('user')
            .select('first_name, last_name')
            .eq('user_id', userId) // Try user_id first
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
            setState(() {
              dealData['salesPerson'] = salesPersonName;
            });
            print('✅ Sales person name loaded: $salesPersonName');
          } else {
            setState(() {
              dealData['salesPerson'] = 'Unknown User';
            });
            print('⚠️ Sales person name is empty, showing "Unknown User"');
          }
        } else {
          setState(() {
            dealData['salesPerson'] = 'User Not Found';
          });
          print('❌ User not found for ID: $userId');
        }
      } else {
        print('⚠️ No user_id found in deal data');
        setState(() {
          dealData['salesPerson'] = 'No Sales Person';
        });
      }
    } catch (e) {
      print('❌ Error loading sales person name: $e');
      setState(() {
        dealData['salesPerson'] = 'Error Loading';
      });
    }
  }

  // Fetch latest deal data from database
  Future<void> _refreshDealData() async {
    if (widget.dealData != null && widget.dealData!['id'] != null) {
      try {
        final updatedDealData =
            await DealService.getDealById(widget.dealData!['id']);
        if (updatedDealData != null) {
          // Update the widget's deal data with fresh data from database
          widget.dealData!.clear();
          widget.dealData!.addAll(updatedDealData);

          // Re-initialize data with fresh data and trigger UI update
          setState(() {
            _initializeData();
          });

          // Reload sales person name with fresh data
          await _loadSalesPersonName();
        } else {
          print('No updated data received from database');
        }
      } catch (e) {
        print('Error refreshing deal data: $e');
      }
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
          'Deal Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DealDetailsUpdate(dealData: widget.dealData),
                ),
              );

              // If update was successful, refresh the data
              if (result == true) {
                // Show loading indicator while refreshing
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshing deal details...'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 1),
                  ),
                );

                // Refresh data from database after returning from update screen
                await _refreshDealData();

                // Show success message after refresh
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Deal details updated and refreshed successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Deal Details Card
            _buildDealDetailsCard(),

            const SizedBox(height: 10),

            // Contact Details Section
            const Text(
              'Contact Details :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 12),

            // Contact Details Card
            _buildContactDetailsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDealDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...dealData.entries.map((entry) {
            final index = dealData.entries.toList().indexOf(entry);
            return Column(
              children: [
                _buildDetailRow(entry.key, entry.value),
                if (index < dealData.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      color: Colors.grey[300],
                      height: 1,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContactDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...contactData.entries.map((entry) {
            final index = contactData.entries.toList().indexOf(entry);
            return Column(
              children: [
                _buildDetailRow(entry.key, entry.value),
                if (index < contactData.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      color: Colors.grey[300],
                      height: 1,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            _formatLabel(label),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  String _formatLabel(String key) {
    switch (key) {
      case 'prospectName':
        return 'Prospect Name:';
      case 'dealSize':
        return 'Deal Size:';
      case 'dealStatus':
        return 'Deal Status:';
      case 'product':
        return 'Product:';
      case 'createdDate':
        return 'Created Date:';
      case 'salesPerson':
        return 'Sales Person:';
      case 'legacySystem':
        return 'Legacy System:';
      case 'country':
        return 'Country:';
      case 'city':
        return 'City:';
      case 'phoneNumber':
        return 'Phone Number:';
      case 'mobileNumber':
        return 'Mobile Number:';
      case 'email':
        return 'Email:';
      case 'website':
        return 'Web Site:';
      default:
        return '$key:';
    }
  }
}
