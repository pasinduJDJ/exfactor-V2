import 'package:flutter/material.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/utils/constants.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/services/dealService.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Top-level formatter for thousand separators with optional decimals
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-numeric characters except decimal point
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

    // Calculate cursor position
    int newCursorPosition = formattedText.length;
    if (oldValue.text.isNotEmpty) {
      // Try to maintain cursor position relative to the end
      int oldCursorPosition = oldValue.selection.baseOffset;
      if (oldCursorPosition < oldValue.text.length) {
        // Calculate how many commas were added/removed
        int oldCommas = oldValue.text.split(',').length - 1;
        int newCommas = formattedText.split(',').length - 1;
        int commaDiff = newCommas - oldCommas;
        newCursorPosition = oldCursorPosition + commaDiff;
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
          offset: newCursorPosition.clamp(0, formattedText.length)),
    );
  }
}

class CreateDeal extends StatefulWidget {
  const CreateDeal({super.key});

  @override
  State<CreateDeal> createState() => _CreateDealState();
}

class _CreateDealState extends State<CreateDeal> {
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

  // Auto-generated fields (read-only)
  String _dealStatus = 'interested';
  DateTime _createdAt = DateTime.now();

  bool _isSubmitting = false;

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

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
  }

  Future<void> _loadCurrentUserInfo() async {
    // This method is kept for future use if needed
    // Currently we only need user_id which is handled in DealService
    try {
      final prefs = await SharedPreferences.getInstance();
      final memberId = prefs.getInt('member_id');
      print('Current member ID: $memberId');
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  @override
  void dispose() {
    _prospectNameController.dispose();
    _dealSizeController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _currentSolutionController.dispose();
    super.dispose();
  }

  double _parseFormattedNumber(String text) {
    if (text.isEmpty) return 0;

    // Remove all commas and spaces, keep only numbers and decimal point
    String cleanText = text.replaceAll(RegExp(r'[,\s]'), '');

    // Try to parse the cleaned text
    double? result = double.tryParse(cleanText);

    // Debug logging
    print('Original text: "$text"');
    print('Cleaned text: "$cleanText"');
    print('Parsed result: $result');

    return result ?? 0;
  }

  // Debug method to help troubleshoot validation issues
  void _debugFormState() {
    print('=== FORM DEBUG INFO ===');
    print('Prospect Name: "${_prospectNameController.text}"');
    print('Deal Size: "${_dealSizeController.text}"');
    print(
        'Parsed Deal Size: ${_parseFormattedNumber(_dealSizeController.text)}');
    print('Deal Size Validation Test:');
    _testDealSizeValidation();
    print('Product: "${_selectedProduct}"');
    print('City: "${_cityController.text}"');
    print('Country: "${_countryController.text}"');
    print('Phone: "${_phoneController.text}"');
    print('Mobile: "${_mobileController.text}"');
    print('Email: "${_emailController.text}"');
    print('Website: "${_websiteController.text}"');
    print('Current Solution: "${_currentSolutionController.text}"');
    print('Form Valid: ${_formKey.currentState?.validate()}');
    print('=======================');
  }

  // Test deal size validation specifically
  void _testDealSizeValidation() {
    final dealSizeText = _dealSizeController.text.trim();
    final parsedAmount = _parseFormattedNumber(dealSizeText);

    print('  - Raw text: "$dealSizeText"');
    print('  - Parsed amount: $parsedAmount');
    print('  - Is valid number: ${parsedAmount > 0}');
    print('  - Meets minimum: ${parsedAmount >= 1000}');
    print('  - Formatted display: ${formatCurrency(parsedAmount)}');
  }

  Future<void> _submitDeal() async {
    // Debug form state before validation
    _debugFormState();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for deal size
    final dealSizeText = _dealSizeController.text.trim();
    final dealSize = _parseFormattedNumber(dealSizeText);

    if (dealSize <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid deal amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (dealSize < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deal size must be at least ${formatCurrency(1000)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Step 1: Validate user has assigned target
      final hasAssignedTarget =
          await DealService.validateUserHasAssignedTarget();
      if (!hasAssignedTarget) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No assigned target found for current year. Please contact admin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Step 2: Validate deal data using DealService
      final validationErrors = DealService.validateDealData(
        prospectName: _prospectNameController.text.trim(),
        dealSize: dealSizeText,
        product: _selectedProduct,
        city: _cityController.text.trim(),
        country: _selectedCountry,
        phone: _phoneController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        currentSolution: _currentSolutionController.text.trim(),
      );

      // Debug validation errors
      print('=== VALIDATION ERRORS ===');
      validationErrors.forEach((key, value) {
        if (value != null) {
          print('$key: $value');
        }
      });
      print('========================');

      // Check for validation errors - improved logic
      if (validationErrors.isNotEmpty) {
        // Find the first non-null error message
        String? firstError;
        for (final error in validationErrors.values) {
          if (error != null) {
            firstError = error;
            break;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(firstError ?? 'Please check your input'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'View Details',
                onPressed: () {
                  // Show detailed validation errors
                  _showValidationErrorsDialog(validationErrors);
                },
              ),
            ),
          );
        }
        return;
      }

      // Create deal using DealService
      final success = await DealService.createDeal(
        prospectName: _prospectNameController.text.trim(),
        dealSize: dealSize,
        product: _selectedProduct,
        city: _cityController.text.trim(),
        country: _selectedCountry,
        phone: _phoneController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        currentSolution: _currentSolutionController.text.trim(),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deal created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create deal. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating deal: $e'),
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
          'Create Deal',
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
              _buildTextField('Deal Size', _dealSizeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [ThousandsFormatter()],
                  hintText: 'Enter amount (e.g., 50,000)',
                  suffixText: 'LKR'),
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
              _buildTextField('Legacy System', _currentSolutionController),

              // Auto-generated fields (read-only)
              const SizedBox(height: 16),
              _buildReadOnlyField('Deal Status', _dealStatus),
              _buildReadOnlyField('Created Date', _formatDate(_createdAt)),

              const SizedBox(height: 24),
              CustomButton(
                text: _isSubmitting ? 'Creating Deal...' : 'New Deal Register',
                backgroundColor: kPrimaryColor,
                width: double.infinity,
                height: 48,
                onPressed: () => _submitDeal(),
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build product dropdown widget
  Widget _buildProductDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product',
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
                value: _selectedProduct,
                isExpanded: true,
                items: _productOptions.map((String product) {
                  return DropdownMenuItem<String>(
                    value: product,
                    child: Text(
                      product,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Country',
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
                value: _selectedCountry,
                isExpanded: true,
                items: _countryOptions.map((String country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(
                      country,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
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

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      List<TextInputFormatter>? inputFormatters,
      String? hintText,
      String? suffixText}) {
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
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: hintText,
              suffixText: suffixText,
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
              if (label == 'Deal Size') {
                final amount = _parseFormattedNumber(value);
                if (amount <= 0) {
                  return 'Please enter a valid amount';
                }
                // Additional validation for deal size
                if (amount < 1000) {
                  // Minimum deal size of 1000
                  return 'Deal size must be at least ${formatCurrency(1000)}';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // Helper method to format date - using constants formatting
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  // Method to show detailed validation errors in a dialog
  void _showValidationErrorsDialog(Map<String, String?> errors) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Validation Errors'),
          content: SingleChildScrollView(
            child: ListBody(
              children: errors.entries.map((entry) {
                final key = entry.key;
                final value = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '$key: ${value ?? 'Invalid input'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
