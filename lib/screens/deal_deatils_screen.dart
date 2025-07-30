import 'package:flutter/material.dart';
import 'package:exfactor/utils/colors.dart';
import 'Sales/sales_update_deal.dart';

class DealDetails extends StatefulWidget {
  const DealDetails({super.key});

  @override
  State<DealDetails> createState() => _DealDetailsState();
}

class _DealDetailsState extends State<DealDetails> {
  // Sample deal data - in real app this would come from API/database
  final Map<String, String> dealData = {
    'prospectName': 'ABC Product',
    'dealSize': '254000',
    'product': 'Odoo POS',
    'createdDate': '2025-07-25',
    'salesPerson': 'Mohan D',
    'currentSolution': 'Manullay',
  };

  final Map<String, String> contactData = {
    'country': 'Sri Lanka',
    'city': 'Colombo',
    'phoneNumber': '0767066455',
    'mobileNumber': '0750750879',
    'email': 'dp@exfysy.com',
    'website': 'sdfwifjnwerg.com',
  };

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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UpdateDeal()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Deal Details Card
            _buildDealDetailsCard(),

            const SizedBox(height: 20),

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
