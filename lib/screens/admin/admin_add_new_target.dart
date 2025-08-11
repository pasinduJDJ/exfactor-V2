import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/services/saleService.dart';
import 'package:exfactor/utils/constants.dart';
import 'package:intl/intl.dart';

class AdminAddNewTarget extends StatefulWidget {
  const AdminAddNewTarget({super.key});

  @override
  State<AdminAddNewTarget> createState() => _AdminAddNewTargetState();
}

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

class _AdminAddNewTargetState extends State<AdminAddNewTarget> {
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _revenueController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> salesMembers = [];
  Map<int, TextEditingController> memberControllers = {};
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _yearController.text = DateTime.now().year.toString();
    fetchSalesMembers();
  }

  @override
  void dispose() {
    _yearController.dispose();
    _revenueController.dispose();
    memberControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> fetchSalesMembers() async {
    setState(() => isLoading = true);
    try {
      final members = await SaleService.getSalesTeamMembers();
      setState(() {
        salesMembers = members;
        // Initialize controllers for each member
        for (var member in members) {
          memberControllers[member['member_id']] = TextEditingController();
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading sales members: $e')),
      );
    }
  }

  Future<void> _selectYear() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _yearController.text = picked.year.toString();
      });
    }
  }

  // Helper method to parse formatted number (remove commas)
  double _parseFormattedNumber(String text) {
    if (text.isEmpty) return 0;
    return double.tryParse(text.replaceAll(',', '')) ?? 0;
  }

  double _getTotalMemberTarget() {
    double total = 0;
    for (var controller in memberControllers.values) {
      if (controller.text.isNotEmpty) {
        total += _parseFormattedNumber(controller.text);
      }
    }
    return total;
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;

    final revenueTarget = _parseFormattedNumber(_revenueController.text);
    final totalMemberTarget = _getTotalMemberTarget();

    if (!SaleService.validateTargetAssignment(
        totalMemberTarget, revenueTarget)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total member targets cannot exceed revenue target'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() => isSubmitting = true);

    try {
      final year = int.parse(_yearController.text);
      final revenueTarget = _parseFormattedNumber(_revenueController.text);

      // Prepare member assignments
      Map<String, double> memberAssignments = {};
      for (var member in salesMembers) {
        final memberId = member['user_id']; // Use UUID
        final controller = memberControllers[member['member_id']];

        if (controller != null && controller.text.isNotEmpty) {
          memberAssignments[memberId] = _parseFormattedNumber(controller.text);
        }
      }

      // Use SaleService to create and assign targets
      final success = await SaleService.createAndAssignTargets(
        year: year,
        revenueTarget: revenueTarget,
        memberAssignments: memberAssignments,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Target added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error adding target. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting target: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Add Sales Target",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: kWhite,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Year Input
              const Text(
                "Year",
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _yearController,
                readOnly: true,
                onTap: _selectYear,
                decoration: InputDecoration(
                  hintText: "Select Year",
                  suffixIcon: Icon(Icons.calendar_today),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a year';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),

              // Revenue Input
              const Text(
                "Target Revenue",
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _revenueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  ThousandsFormatter(),
                ],
                decoration: InputDecoration(
                  hintText:
                      "Enter target revenue (e.g., ${formatWithCommas(1000000)})",
                  prefixText: "LKR ",
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter target revenue';
                  }
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),

              // Sales Members Section
              const Text(
                "Sales Members",
              ),

              const SizedBox(height: 4),

              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (salesMembers.isEmpty)
                const Center(
                  child: Text(
                    'No sales members found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...salesMembers.map((member) => _buildMemberCard(member)),

              const SizedBox(height: 15),

              CustomButton(
                text: isSubmitting ? "Submitting..." : "Submit",
                onPressed: isSubmitting ? () {} : _submitForm,
                backgroundColor: primaryColor,
                width: double.infinity,
                height: 50,
                isLoading: isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final memberId = member['member_id'];
    final controller = memberControllers[memberId];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Member Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${member['first_name'] ?? ''} ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member['position'] ?? 'Sales Representative',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Amount Input
          SizedBox(
            width: 180,
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                ThousandsFormatter(),
              ],
              decoration: InputDecoration(
                hintText: "Amount (e.g., ${formatWithCommas(500000)})",
                prefixText: "LKR ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount < 0) {
                    return 'Invalid amount';
                  }
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
