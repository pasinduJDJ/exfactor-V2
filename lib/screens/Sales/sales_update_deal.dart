import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
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

class UpdateDeal extends StatefulWidget {
  const UpdateDeal({super.key});

  @override
  State<UpdateDeal> createState() => _UpdateDealState();
}

class _UpdateDealState extends State<UpdateDeal> {
  final _formKey = GlobalKey<FormState>();

  // Helper method to parse formatted number (remove commas)
  double _parseFormattedNumber(String text) {
    if (text.isEmpty) return 0;
    return double.tryParse(text.replaceAll(',', '')) ?? 0;
  }

  // Controllers for each field - pre-filled with existing data
  final TextEditingController _prospectNameController =
      TextEditingController(text: 'ABC Product');
  final TextEditingController _dealSizeController =
      TextEditingController(text: formatWithCommas(254000));
  final TextEditingController _productController =
      TextEditingController(text: 'Odoo POS');
  final TextEditingController _cityController =
      TextEditingController(text: 'Colombo');
  final TextEditingController _countryController =
      TextEditingController(text: 'Sri Lanka');
  final TextEditingController _phoneController =
      TextEditingController(text: '0767066455');
  final TextEditingController _mobileController =
      TextEditingController(text: '0750750879');
  final TextEditingController _websiteController =
      TextEditingController(text: 'sdfwifjnwerg.com');
  final TextEditingController _currentSolutionController =
      TextEditingController(text: 'Manullay');

  @override
  void dispose() {
    _prospectNameController.dispose();
    _dealSizeController.dispose();
    _productController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _websiteController.dispose();
    _currentSolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        toolbarHeight: 70,
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
              _buildTextField('WebSite', _websiteController),
              _buildTextField('legacy System', _currentSolutionController),
              const SizedBox(height: 15),
              CustomButton(
                text: 'Update Deal',
                backgroundColor: kPrimaryColor,
                width: double.infinity,
                height: 48,
                onPressed: () {
                  // TODO: Implement deal update logic
                  if (_formKey.currentState!.validate()) {
                    // Parse deal size for processing
                    final dealSize =
                        _parseFormattedNumber(_dealSizeController.text);
                    print('Deal size: $dealSize');
                    // Update deal
                    Navigator.of(context).pop();
                  }
                },
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
                return 'Please enter a valid deal amount';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
