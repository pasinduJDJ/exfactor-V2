import 'package:flutter/material.dart';
import 'package:exfactor/utils/colors.dart';
import 'deal_details_update_screen.dart';
import 'package:exfactor/services/dealService.dart';

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
      // Debug print to verify deal data
      print('=== Deal Details Debug ===');
      print('Received deal data: ${widget.dealData}');

      // Use real deal data from database
      dealData = {
        'prospectName': widget.dealData!['prospect_name'] ?? 'N/A',
        'dealSize':
            'LKR ${(widget.dealData!['deal_amount'] ?? 0).toStringAsFixed(2)}',
        'dealStatus': _formatDealStatus(widget.dealData!['deal_status']),
        'product': widget.dealData!['product'] ?? 'N/A',
        'createdDate': _formatDate(widget.dealData!['created_at']),
        'salesPerson':
            'Current User', // We can get this from user data if needed
        'currentSolution': widget.dealData!['current_solution'] ?? 'N/A',
      };

      contactData = {
        'country': widget.dealData!['country'] ?? 'N/A',
        'city': widget.dealData!['city'] ?? 'N/A',
        'phoneNumber': widget.dealData!['phone_number'] ?? 'N/A',
        'mobileNumber': widget.dealData!['mobile_number'] ?? 'N/A',
        'email': widget.dealData!['email'] ?? 'N/A',
        'website': widget.dealData!['website'] ?? 'N/A',
      };

      print('Processed deal data: $dealData');
      print('Processed contact data: $contactData');
      print('========================');
    } else {
      // Fallback to sample data if no deal data provided
      dealData = {
        'prospectName': 'ABC Product',
        'dealSize': 'LKR 254000.00',
        'dealStatus': 'Active',
        'product': 'Odoo POS',
        'createdDate': '2025-07-25',
        'salesPerson': 'Mohan D',
        'currentSolution': 'Manullay',
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

    return statusMap[status.toLowerCase()] ?? status;
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

          // Re-initialize data with fresh data
          _initializeData();
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
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Deal details refreshed successfully!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );

                // Refresh data from database after returning from update screen
                await _refreshDealData();
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
          }).toList(),
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
          }).toList(),
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
      case 'currentSolution':
        return 'Current Solution:';
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
