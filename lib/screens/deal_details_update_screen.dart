import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/services/dealService.dart';
import 'package:exfactor/utils/constants.dart';
import 'package:intl/intl.dart';

// Custom formatter for thousands separator
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits and decimal points
    String text = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');

    // Ensure only one decimal point
    List<String> parts = text.split('.');
    if (parts.length > 2) {
      text = '${parts[0]}.${parts.sublist(1).join('')}';
      parts = text.split('.');
    }

    // Format the integer part with commas
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      final formatter = NumberFormat('#,##0');
      parts[0] = formatter.format(int.tryParse(parts[0]) ?? 0);
    }

    String formattedText = parts.join('.');

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class DealDetailsUpdate extends StatefulWidget {
  final Map<String, dynamic>? dealData;

  const DealDetailsUpdate({super.key, this.dealData});

  @override
  State<DealDetailsUpdate> createState() => _DealDetailsUpdateState();
}

class _DealDetailsUpdateState extends State<DealDetailsUpdate> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for each field
  final TextEditingController _prospectNameController = TextEditingController();
  final TextEditingController _dealSizeController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _currentSolutionController =
      TextEditingController();

  // Deal status dropdown
  String _selectedDealStatus = 'active';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Helper method to parse formatted number (remove commas)
  double _parseFormattedNumber(String text) {
    if (text.isEmpty) return 0;
    return double.tryParse(text.replaceAll(',', '')) ?? 0;
  }

  void _initializeData() {
    // Debug logging
    print('=== Deal Details Update Debug ===');
    print('Received deal data: ${widget.dealData}');

    if (widget.dealData != null) {
      // Populate form fields with existing deal data
      _prospectNameController.text = widget.dealData!['prospect_name'] ?? '';

      // Handle deal amount formatting
      final dealAmount = widget.dealData!['deal_amount'] ?? 0;
      _dealSizeController.text = formatWithCommas(dealAmount);
      print(
          'Deal Size Controller initialized with: ${_dealSizeController.text}');

      _productController.text = widget.dealData!['product'] ?? '';
      _cityController.text = widget.dealData!['city'] ?? '';
      _countryController.text = widget.dealData!['country'] ?? '';
      _phoneController.text = widget.dealData!['phone_number'] ?? '';
      _mobileController.text = widget.dealData!['mobile_number'] ?? '';
      _emailController.text = widget.dealData!['email'] ?? '';
      _websiteController.text = widget.dealData!['website'] ?? '';
      _currentSolutionController.text =
          widget.dealData!['current_solution'] ?? '';
      _selectedDealStatus = widget.dealData!['deal_status'] ?? 'active';

      print('Deal ID: ${widget.dealData!['id']}');
      print('Prospect Name: ${widget.dealData!['prospect_name']}');
      print('Deal Amount: ${widget.dealData!['deal_amount']}');
      print('========================');
    } else {
      print('No deal data provided');
      print('========================');
    }
  }

  @override
  void dispose() {
    _prospectNameController.dispose();
    _dealSizeController.dispose();
    _productController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _currentSolutionController.dispose();
    super.dispose();
  }

  Future<void> _updateDeal() async {
    print('=== Starting Deal Update ===');
    print('Deal Data: ${widget.dealData}');

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      print('Deal Size Controller text: "${_dealSizeController.text}"');
      print(
          'Deal Size Controller is empty: ${_dealSizeController.text.isEmpty}');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Validate deal data using DealService
      // Parse deal size to remove commas before validation
      final parsedDealSize =
          _parseFormattedNumber(_dealSizeController.text.trim());

      print('=== Deal Size Validation Debug ===');
      print('Raw deal size text: "${_dealSizeController.text.trim()}"');
      print('Parsed deal size: $parsedDealSize');
      print('Parsed deal size string: "${parsedDealSize.toString()}"');
      print('===============================');

      final validationErrors = DealService.validateDealData(
        prospectName: _prospectNameController.text.trim(),
        dealSize:
            parsedDealSize.toString(), // Pass as string number without commas
        product: _productController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        phone: _phoneController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        currentSolution: _currentSolutionController.text.trim(),
      );

      // Check for validation errors
      if (validationErrors.isNotEmpty) {
        print('=== Validation Errors Found ===');
        validationErrors.forEach((key, value) {
          print('$key: $value');
        });
        print('===============================');

        final errorMessage = validationErrors.values.firstWhere(
          (error) => error != null,
          orElse: () => 'Please check your input',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if deal data and ID are available
      if (widget.dealData == null || widget.dealData!['id'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Deal data not found. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Update deal using DealService
      final success = await DealService.updateDeal(
        dealId: widget.dealData!['id'],
        prospectName: _prospectNameController.text.trim(),
        dealSize: _parseFormattedNumber(_dealSizeController.text.trim()),
        product: _productController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        phone: _phoneController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        currentSolution: _currentSolutionController.text.trim(),
        dealStatus: _selectedDealStatus,
      );

      if (success) {
        print('Deal updated successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Wait a moment for the snackbar to show, then pop
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pop(
              context, true); // Pass true to indicate successful update
        }
      } else {
        print('Failed to update deal');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update deal. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating deal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating deal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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
          'Update Deal',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField('Prospect Name', _prospectNameController),
              _buildFormattedNumberField('Deal Size', _dealSizeController),
              _buildTextField('Product', _productController),
              _buildTextField('City', _cityController),
              _buildTextField('Country', _countryController),
              _buildTextField('Phone Number', _phoneController,
                  keyboardType: TextInputType.phone),
              _buildTextField('Mobile Number', _mobileController,
                  keyboardType: TextInputType.phone),
              _buildTextField('Email', _emailController,
                  keyboardType: TextInputType.emailAddress),
              _buildTextField('Website', _websiteController),
              _buildTextField('Current Solution', _currentSolutionController),

              // Deal Status Dropdown
              const SizedBox(height: 16),
              _buildDealStatusDropdown(),

              // Created Date (Read-only)
              const SizedBox(height: 16),
              _buildReadOnlyField(
                  'Created Date', _formatDate(widget.dealData?['created_at'])),

              const SizedBox(height: 15),
              CustomButton(
                text: _isSubmitting ? 'Submitting...' : 'Submit',
                backgroundColor: kPrimaryColor,
                width: double.infinity,
                height: 48,
                onPressed: () => _updateDeal(),
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kPrimaryColor),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDealStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deal Status',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDealStatus,
              isExpanded: true,
              items: DealService.getDealStatusOptions().map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(DealService.getDealStatusDisplayNames()[status] ??
                      status),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedDealStatus = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to format date
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  // Build read-only field widget
  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build formatted number field with thousands separator
  Widget _buildFormattedNumberField(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              ThousandsFormatter(),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixText: "LKR ",
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kPrimaryColor),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              final amount = double.tryParse(value.replaceAll(',', ''));
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
