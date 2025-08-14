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
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _currentSolutionController =
      TextEditingController();

  // Product options for dropdown
  final List<String> _productOptions = [
    'Odoo ERP',
    'Odoo Development',
    'Odoo Supermarket',
    'Odoo Pharmacy',
    'Odoo Restaurant',
    'Odoo Distribution',
    'SAP Support',
    'SalesForce',
    'WorkHub24',
    'Hosting & Server',
    'SMS Gateway',
    'Payment Gateway',
    'Mobile Application',
  ];

  // Selected product
  String _selectedProduct = 'Odoo ERP';

  // Country options for dropdown
  final List<String> _countryOptions = [
    'Sri Lanka',
    'India',
    'Pakistan',
    'Bangladesh',
    'Nepal',
    'Maldives',
    'Afghanistan',
    'United States',
    'Canada',
    'United Kingdom',
    'Germany',
    'France',
    'Italy',
    'Spain',
    'Netherlands',
    'Belgium',
    'Switzerland',
    'Austria',
    'Sweden',
    'Norway',
    'Denmark',
    'Finland',
    'Australia',
    'New Zealand',
    'Japan',
    'South Korea',
    'China',
    'Singapore',
    'Malaysia',
    'Thailand',
    'Vietnam',
    'Indonesia',
    'Philippines',
    'Taiwan',
    'Hong Kong',
    'United Arab Emirates',
    'Saudi Arabia',
    'Qatar',
    'Kuwait',
    'Bahrain',
    'Oman',
    'Turkey',
    'Israel',
    'Egypt',
    'South Africa',
    'Nigeria',
    'Kenya',
    'Ghana',
    'Morocco',
    'Tunisia',
    'Brazil',
    'Argentina',
    'Chile',
    'Colombia',
    'Mexico',
    'Peru',
    'Venezuela',
    'Uruguay',
    'Paraguay',
    'Ecuador',
    'Bolivia',
    'Russia',
    'Ukraine',
    'Poland',
    'Czech Republic',
    'Hungary',
    'Romania',
    'Bulgaria',
    'Croatia',
    'Slovenia',
    'Slovakia',
    'Estonia',
    'Latvia',
    'Lithuania',
    'Ireland',
    'Portugal',
    'Greece',
    'Cyprus',
    'Malta',
    'Luxembourg',
    'Iceland',
    'Greenland',
    'Fiji',
    'Papua New Guinea',
    'Solomon Islands',
    'Vanuatu',
    'New Caledonia',
    'French Polynesia',
    'Samoa',
    'Tonga',
    'Kiribati',
    'Tuvalu',
    'Nauru',
    'Palau',
    'Marshall Islands',
    'Micronesia',
    'Guam',
    'Northern Mariana Islands',
    'American Samoa',
    'Cook Islands',
    'Niue',
    'Tokelau',
    'Wallis and Futuna',
    'Pitcairn Islands',
    'Easter Island',
    'Galapagos Islands',
    'Falkland Islands',
    'South Georgia',
    'Bouvet Island',
    'Heard Island',
    'McDonald Islands',
    'Kerguelen Islands',
    'Crozet Islands',
    'Prince Edward Islands',
    'Gough Island',
    'Tristan da Cunha',
    'Saint Helena',
    'Ascension Island',
    'Bermuda',
    'Cayman Islands',
    'Turks and Caicos Islands',
    'British Virgin Islands',
    'Anguilla',
    'Montserrat',
    'Saint Kitts and Nevis',
    'Antigua and Barbuda',
    'Dominica',
    'Saint Lucia',
    'Saint Vincent and the Grenadines',
    'Grenada',
    'Barbados',
    'Trinidad and Tobago',
    'Guyana',
    'Suriname',
    'French Guiana',
  ];

  // Selected country
  String _selectedCountry = 'Sri Lanka';

  // Deal status dropdown
  String _selectedDealStatus = 'interested';
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

      // Handle product selection - check if existing product is in our options
      final existingProduct = widget.dealData!['product'] ?? '';
      if (_productOptions.contains(existingProduct)) {
        _selectedProduct = existingProduct;
      } else {
        // If existing product is not in our options, set default and log warning
        _selectedProduct = 'Odoo ERP';
        print(
            'Warning: Existing product "$existingProduct" not found in dropdown options. Using default: $_selectedProduct');
      }

      _cityController.text = widget.dealData!['city'] ?? '';

      // Handle country selection - check if existing country is in our options
      final existingCountry = widget.dealData!['country'] ?? '';
      if (_countryOptions.contains(existingCountry)) {
        _selectedCountry = existingCountry;
      } else {
        // If existing country is not in our options, set default and log warning
        _selectedCountry = 'Sri Lanka';
        print(
            'Warning: Existing country "$existingCountry" not found in dropdown options. Using default: $_selectedCountry');
      }

      _phoneController.text = widget.dealData!['phone_number'] ?? '';
      _mobileController.text = widget.dealData!['mobile_number'] ?? '';
      _emailController.text = widget.dealData!['email'] ?? '';
      _websiteController.text = widget.dealData!['website'] ?? '';
      _currentSolutionController.text =
          widget.dealData!['current_solution'] ?? '';
      _selectedDealStatus =
          _mapOldStatusToNew(widget.dealData!['deal_status'] ?? 'interested');

      print('Deal ID: ${widget.dealData!['id']}');
      print('Prospect Name: ${widget.dealData!['prospect_name']}');
      print('Deal Amount: ${widget.dealData!['deal_amount']}');
      print('Selected Product: $_selectedProduct');
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
    _cityController.dispose();
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
        product: _selectedProduct,
        city: _cityController.text.trim(),
        country: _selectedCountry,
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
        product: _selectedProduct,
        city: _cityController.text.trim(),
        country: _selectedCountry,
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
              _buildProductDropdown(),
              _buildTextField('City', _cityController),
              _buildCountryDropdown(),
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
    // Show all available statuses for maximum flexibility
    final allStatuses = DealService.getDealStatusOptions();

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
              items: allStatuses.map((String status) {
                final displayName =
                    DealService.getDealStatusDisplayNames()[status] ?? status;
                final icon = _getStatusIcon(status);
                final color = _getStatusColor(status);
                final isCurrentStatus = status == _selectedDealStatus;

                return DropdownMenuItem<String>(
                  value: status,
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isCurrentStatus)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
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
        const SizedBox(height: 8),
        // Show helpful info
      ],
    );
  }

  // Helper method to get status icon
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'interested':
        return Icons.favorite;
      case 'ready_for_demo':
        return Icons.play_circle;
      case 'proposal':
        return Icons.description;
      case 'negotiation':
        return Icons.handshake;
      case 'won':
        return Icons.check_circle;
      case 'lost':
        return Icons.cancel;
      default:
        return Icons.circle;
    }
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'interested':
        return kPrimaryColor;
      case 'ready_for_demo':
        return kPrimaryColor;
      case 'proposal':
        return kPrimaryColor;
      case 'negotiation':
        return kPrimaryColor;
      case 'won':
        return kPrimaryColor;
      case 'lost':
        return kPrimaryColor;
      default:
        return kPrimaryColor;
    }
  }

  // Build pipeline step indicator
  Widget _buildPipelineStep(String number, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? Colors.blue : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.blue.shade700 : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Build pipeline arrow
  Widget _buildPipelineArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.arrow_forward,
        color: Colors.grey.shade400,
        size: 16,
      ),
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

  // Helper method to map old statuses to new ones
  String _mapOldStatusToNew(String oldStatus) {
    switch (oldStatus.toLowerCase()) {
      case 'interested':
      case 'ready_for_demo':
      case 'proposal':
      case 'negotiation':
      case 'won':
      case 'lost':
        return oldStatus.toLowerCase();
      case 'active':
      case 'in_progress':
      case 'pending':
        return 'interested'; // Map old active statuses to interested
      case 'closed':
      case 'completed':
        return 'won'; // Map old closed statuses to won
      default:
        return 'interested'; // Fallback to default status
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

  Widget _buildProductDropdown() {
    // Safety check: ensure selected product is in the options list
    if (!_productOptions.contains(_selectedProduct)) {
      _selectedProduct = 'Odoo ERP';
      print(
          'Safety check: Reset invalid product selection to default: $_selectedProduct');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
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
                value: _selectedProduct,
                isExpanded: true,
                items: _productOptions.map((String product) {
                  return DropdownMenuItem<String>(
                    value: product,
                    child: Text(product),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedProduct = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown() {
    // Safety check: ensure selected country is in the options list
    if (!_countryOptions.contains(_selectedCountry)) {
      _selectedCountry = 'Sri Lanka';
      print(
          'Safety check: Reset invalid country selection to default: $_selectedCountry');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Country',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
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
                value: _selectedCountry,
                isExpanded: true,
                items: _countryOptions.map((String country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCountry = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
