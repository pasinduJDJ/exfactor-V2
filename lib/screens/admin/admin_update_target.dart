import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/services/saleService.dart';
import 'package:exfactor/services/superbase_service.dart';

class AdminUpdateTarget extends StatefulWidget {
  const AdminUpdateTarget({super.key});

  @override
  State<AdminUpdateTarget> createState() => _AdminUpdateTargetState();
}

class _AdminUpdateTargetState extends State<AdminUpdateTarget> {
  final TextEditingController _revenueController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> salesMembers = [];
  List<Map<String, dynamic>> existingTargets = [];
  Map<int, TextEditingController> memberControllers = {};
  bool isLoading = true;
  bool isSubmitting = false;
  Map<String, dynamic>? selectedTarget;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    _revenueController.dispose();
    memberControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      // Fetch sales members
      final members = await SaleService.getSalesTeamMembers();

      // Fetch existing targets
      final targets = await SupabaseService.getAllTargets();

      setState(() {
        salesMembers = members;
        existingTargets = targets;

        // Initialize controllers for each member
        for (var member in members) {
          memberControllers[member['member_id']] = TextEditingController();
        }

        // Select the most recent target (current year)
        if (targets.isNotEmpty) {
          final currentYear = DateTime.now().year;
          selectedTarget = targets.firstWhere(
            (target) => DateTime.parse(target['year']).year == currentYear,
            orElse: () => targets.first,
          );

          // Populate revenue controller with selected target
          if (selectedTarget != null) {
            _revenueController.text =
                (selectedTarget!['amount'] ?? 0).toString();
          }
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
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

  Future<void> _updateTarget() async {
    if (!_validateForm()) return;

    setState(() => isSubmitting = true);

    try {
      final revenueTarget = double.parse(_revenueController.text);

      // Prepare member assignments
      Map<String, double> memberAssignments = {};
      for (var member in salesMembers) {
        final memberId = member['user_id']; // Use UUID
        final controller = memberControllers[member['member_id']];

        if (controller != null && controller.text.isNotEmpty) {
          memberAssignments[memberId] = double.parse(controller.text);
        }
      }

      // Update target in database
      if (selectedTarget != null) {
        final success = await _updateTargetInDatabase(
          targetId: selectedTarget!['id'],
          newRevenueTarget: revenueTarget,
          memberAssignments: memberAssignments,
        );

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Target updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true); // Return true to indicate success
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error updating target. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating target: $e'),
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

  Future<bool> _updateTargetInDatabase({
    required String targetId,
    required double newRevenueTarget,
    required Map<String, double> memberAssignments,
  }) async {
    try {
      // Update the main target
      final updatedTarget = {
        'amount': newRevenueTarget,
        'annual_amount': newRevenueTarget,
        'monthly_amount': newRevenueTarget / 12,
        'Quater_amount': newRevenueTarget / 4,
      };

      await SupabaseService.updateTarget(targetId, updatedTarget);

      // Update assigned targets for each member
      for (final member in salesMembers) {
        final memberId = member['user_id'];
        final assignedAmount = memberAssignments[memberId] ?? 0;

        if (assignedAmount > 0) {
          // Find existing assigned target for this member and target
          final assignedTargets =
              await SupabaseService.getAssignedTargetsByUserId(memberId);
          final existingAssignedTarget = assignedTargets.firstWhere(
            (target) => target['annual_target_id'] == targetId,
            orElse: () => <String, dynamic>{},
          );

          if (existingAssignedTarget.isNotEmpty) {
            // Update existing assigned target
            final updatedAssignedTarget = {
              'assigned_amount_annual': assignedAmount,
              'assigned_amount_q1': assignedAmount / 4,
              'assigned_amount_q2': assignedAmount / 4,
              'assigned_amount_q3': assignedAmount / 4,
              'assigned_amount_q4': assignedAmount / 4,
            };

            await SupabaseService.updateAssignedTarget(
              existingAssignedTarget['id'],
              updatedAssignedTarget,
            );

            // Update monthly targets
            await _updateMonthlyTargets(
                existingAssignedTarget['id'], assignedAmount);
          }
        }
      }

      return true;
    } catch (e) {
      print('Error updating target in database: $e');
      return false;
    }
  }

  Future<void> _updateMonthlyTargets(
      String assignedTargetId, double annualAmount) async {
    try {
      final monthlyAmount = annualAmount / 12;

      // Get existing monthly targets
      final monthlyTargets =
          await SupabaseService.getAssignedMonthlyTargetsByAssignedTargetId(
              assignedTargetId);

      // Update each monthly target
      for (final monthlyTarget in monthlyTargets) {
        await SupabaseService.updateAssignedMonthlyTarget(
          monthlyTarget['id'],
          {'target_amount': monthlyAmount},
        );
      }
    } catch (e) {
      print('Error updating monthly targets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Update Sales Target",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: kWhite,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Target Selection
                    const Text(
                      "Select Target to Update",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          value: selectedTarget,
                          isExpanded: true,
                          hint: const Text('Select a target'),
                          items: existingTargets.map((target) {
                            final year = DateTime.parse(target['year']).year;
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: target,
                              child: Text(
                                  'Year $year - LKR ${(target['amount'] ?? 0).toStringAsFixed(2)}'),
                            );
                          }).toList(),
                          onChanged: (Map<String, dynamic>? newValue) {
                            setState(() {
                              selectedTarget = newValue;
                              if (newValue != null) {
                                _revenueController.text =
                                    (newValue['amount'] ?? 0).toString();
                              }
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

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
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
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

                    const SizedBox(height: 20),

                    // Sales Members Section
                    const Text(
                      "Sales Members",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    if (salesMembers.isEmpty)
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
                      text: isSubmitting ? "Updating..." : "Update Target",
                      onPressed: isSubmitting ? () {} : _updateTarget,
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
            width: 180,
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                hintText: "Amount",
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
