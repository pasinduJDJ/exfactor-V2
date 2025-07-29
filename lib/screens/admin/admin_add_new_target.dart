import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/services/userService.dart';

class AdminAddNewTarget extends StatefulWidget {
  const AdminAddNewTarget({super.key});

  @override
  State<AdminAddNewTarget> createState() => _AdminAddNewTargetState();
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
      final members = await UserService.getSalesTeamMembers();
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

  double _getTotalMemberTarget() {
    double total = 0;
    for (var controller in memberControllers.values) {
      if (controller.text.isNotEmpty) {
        total += double.tryParse(controller.text) ?? 0;
      }
    }
    return total;
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;

    final revenueTarget = double.tryParse(_revenueController.text) ?? 0;
    final totalMemberTarget = _getTotalMemberTarget();

    if (totalMemberTarget > revenueTarget) {
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
      // TODO: Implement actual submission to database
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Target added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
              const SizedBox(height: 20),

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
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  hintText: "Enter target revenue",
                  prefixText: "LKR ",
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter target revenue';
                  }
                  final amount = double.tryParse(value);
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
                  '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}',
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
            width: 120,
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                hintText: "Amount",
                prefixText: "\LKR ",
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
                  final amount = double.tryParse(value);
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
