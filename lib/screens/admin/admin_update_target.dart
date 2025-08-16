import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/services/saleService.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool isLoadingMembers = false;
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
      // Fetch sales members and targets concurrently
      final results = await Future.wait([
        SaleService.getSalesTeamMembers(),
        SupabaseService.getAllTargets(),
      ], eagerError: false)
          .timeout(const Duration(seconds: 20));

      final members = results[0] as List<Map<String, dynamic>>;
      final targets = results[1] as List<Map<String, dynamic>>;

      setState(() {
        salesMembers = members;
        existingTargets = targets;

        // Initialize controllers for each member
        for (var member in members) {
          final controller = TextEditingController();
          memberControllers[member['member_id']] = controller;

          // Add listener to refresh summary when values change
          controller.addListener(() {
            if (mounted) setState(() {});
          });
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
                formatWithCommas(selectedTarget!['amount'] ?? 0);
          }
        }

        isLoading = false;
      });

      // After setting state, fetch and populate member assigned targets
      if (selectedTarget != null) {
        await _loadMemberAssignedTargets();
      }
    } on TimeoutException {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Connection timeout. Please check your internet connection and try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // New method to load existing assigned targets for each member
  Future<void> _loadMemberAssignedTargets() async {
    if (selectedTarget == null || salesMembers.isEmpty) return;

    setState(() => isLoadingMembers = true);

    try {
      // Load all member assigned targets concurrently using Future.wait with timeout
      final futures = salesMembers.map((member) async {
        final memberId = member['user_id'];
        try {
          final assignedTargets =
              await SupabaseService.getAssignedTargetsByUserId(memberId)
                  .timeout(const Duration(
                      seconds: 10)); // 10 second timeout per member
          return {
            'memberId': memberId,
            'assignedTargets': assignedTargets,
          };
        } catch (e) {
          print('Error loading assigned targets for member $memberId: $e');
          return {
            'memberId': memberId,
            'assignedTargets': <Map<String, dynamic>>[],
          };
        }
      });

      final results = await Future.wait(futures, eagerError: false).timeout(
          const Duration(seconds: 30)); // Overall timeout of 30 seconds

      // Populate controllers with existing values
      for (final result in results) {
        final memberId = result['memberId'] as String;
        final assignedTargets =
            result['assignedTargets'] as List<Map<String, dynamic>>;

        // Find the member and controller
        final member = salesMembers.firstWhere(
          (m) => m['user_id'] == memberId,
          orElse: () => <String, dynamic>{},
        );

        if (member.isNotEmpty) {
          final controller = memberControllers[member['member_id']];

          if (controller != null) {
            // Find the assigned target for the selected target year
            final memberAssignedTarget = assignedTargets.firstWhere(
              (target) => target['annual_target_id'] == selectedTarget!['id'],
              orElse: () => <String, dynamic>{},
            );

            // Populate controller with existing assigned amount
            if (memberAssignedTarget.isNotEmpty &&
                memberAssignedTarget['assigned_amount_annual'] != null) {
              controller.text = formatWithCommas(
                  memberAssignedTarget['assigned_amount_annual']);
            } else {
              // Clear controller if no assigned target found
              controller.clear();
            }
          }
        }
      }
    } on TimeoutException {
      print('Timeout loading member assigned targets');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Loading timeout. Please check your connection and try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error loading member assigned targets: $e');
      // Show error to user but don't block the UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Warning: Could not load existing member targets. You can still update them.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingMembers = false);
      }
    }
  }

  // Helper method to format number with commas
  String formatWithCommas(dynamic number) {
    if (number == null) return '0';
    final numValue = number is String ? double.tryParse(number) ?? 0 : number;
    final formatter = NumberFormat('#,##0');
    return formatter.format(numValue);
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

  Future<void> _updateTarget() async {
    if (!_validateForm()) return;

    setState(() => isSubmitting = true);

    try {
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

      // Update target in database
      if (selectedTarget != null) {
        final success = await _updateTargetInDatabase(
          targetId: selectedTarget!['id'],
          newRevenueTarget: revenueTarget,
          memberAssignments: memberAssignments,
        );

        if (success) {
          if (mounted) {
            // Count how many members were updated/created/deleted
            int updatedCount = 0;
            int createdCount = 0;
            int deletedCount = 0;

            for (var member in salesMembers) {
              final memberId = member['user_id'];
              final assignedAmount = memberAssignments[memberId] ?? 0;

              // Check if member had existing assigned target
              final assignedTargets =
                  await SupabaseService.getAssignedTargetsByUserId(memberId);
              final existingAssignedTarget = assignedTargets.firstWhere(
                (target) => target['annual_target_id'] == selectedTarget!['id'],
                orElse: () => <String, dynamic>{},
              );

              if (existingAssignedTarget.isNotEmpty) {
                if (assignedAmount > 0) {
                  updatedCount++;
                } else {
                  deletedCount++;
                }
              } else {
                if (assignedAmount > 0) {
                  createdCount++;
                }
              }
            }

            String message = 'Target updated successfully!';
            if (createdCount > 0) {
              message += ' Created $createdCount new member assignments.';
            }
            if (updatedCount > 0) {
              message += ' Updated $updatedCount existing assignments.';
            }
            if (deletedCount > 0) {
              message += ' Removed $deletedCount assignments.';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('No target selected. Please select a target to update.'),
              backgroundColor: Colors.red,
            ),
          );
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
      print('Starting target update process...');
      print('Target ID: $targetId');
      print('New Revenue Target: $newRevenueTarget');
      print('Member Assignments: $memberAssignments');

      // Update the main target
      final updatedTarget = {
        'amount': newRevenueTarget,
        'annual_amount': newRevenueTarget,
        'monthly_amount': newRevenueTarget / 12,
        'Quater_amount': newRevenueTarget / 4,
      };

      print('Updating main target with: $updatedTarget');
      await SupabaseService.updateTarget(targetId, updatedTarget);
      print('Main target updated successfully');

      // Update assigned targets for each member
      print('Processing ${salesMembers.length} sales members...');
      for (final member in salesMembers) {
        final memberId = member['user_id'];
        final assignedAmount = memberAssignments[memberId] ?? 0;
        final memberName = member['first_name'] ?? 'Unknown';

        print(
            'Processing member: $memberName (ID: $memberId) with amount: $assignedAmount');

        // Always check for existing assigned target, regardless of amount
        print('Looking for existing assigned target for member $memberName...');
        final assignedTargets =
            await SupabaseService.getAssignedTargetsByUserId(memberId);
        print(
            'Found ${assignedTargets.length} assigned targets for member $memberName');

        final existingAssignedTarget = assignedTargets.firstWhere(
          (target) => target['annual_target_id'] == targetId,
          orElse: () => <String, dynamic>{},
        );

        if (existingAssignedTarget.isNotEmpty) {
          // Member has existing assignment
          if (assignedAmount > 0) {
            // Update existing assigned target with new amount
            print(
                'Updating existing assigned target for member $memberName...');
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
            print('✅ Updated existing assigned target for member $memberName');
          } else {
            // Member had assignment but now amount is 0 - delete the assignment
            print(
                'Member $memberName had assignment but amount is now 0. Deleting assignment...');
            try {
              // Delete monthly targets first
              await _deleteMonthlyTargets(existingAssignedTarget['id']);

              // Delete the assigned target
              await Supabase.instance.client
                  .from('assigned_targets')
                  .delete()
                  .eq('id', existingAssignedTarget['id']);

              print('✅ Deleted assigned target for member $memberName');
            } catch (e) {
              print(
                  '❌ Error deleting assigned target for member $memberName: $e');
            }
          }
        } else {
          // Member has no existing assignment
          if (assignedAmount > 0) {
            // Create new assigned target
            print(
                'No existing assigned target found for member $memberName. Creating new one...');
            try {
              final newAssignedTarget = {
                'user_id': memberId,
                'annual_target_id': targetId,
                'assigned_amount_annual': assignedAmount,
                'assigned_amount_q1': assignedAmount / 4,
                'assigned_amount_q2': assignedAmount / 4,
                'assigned_amount_q3': assignedAmount / 4,
                'assigned_amount_q4': assignedAmount / 4,
                'created_at': DateTime.now().toIso8601String(),
              };

              print('Inserting new assigned target: $newAssignedTarget');

              // Insert the new assigned target directly into the database
              final response = await Supabase.instance.client
                  .from('assigned_targets')
                  .insert(newAssignedTarget)
                  .select();

              if (response.isNotEmpty) {
                final newAssignedTargetId = response[0]['id'];
                print(
                    '✅ Successfully created new assigned target for member $memberName with ID: $newAssignedTargetId');

                // Create monthly targets for the new assigned target
                print('Creating monthly targets for new assigned target...');
                await _createMonthlyTargets(
                    newAssignedTargetId, assignedAmount);
                print(
                    '✅ Monthly targets created successfully for member $memberName');
              } else {
                print(
                    '❌ Failed to create assigned target for member $memberName - no response from database');
              }
            } catch (e) {
              print(
                  '❌ Error creating new assigned target for member $memberName: $e');
              // Continue with other members even if one fails
            }
          } else {
            // Member has no assignment and no amount - do nothing
            print(
                'Member $memberName has no assignment and no amount - skipping');
          }
        }
      }

      print('✅ All target updates completed successfully!');
      return true;
    } catch (e) {
      print('❌ Error updating target in database: $e');
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

  // Create monthly targets for a new assigned target
  Future<void> _createMonthlyTargets(
      String assignedTargetId, double annualAmount) async {
    try {
      final monthlyAmount = annualAmount / 12;

      // Create 12 monthly targets (January to December)
      for (int month = 1; month <= 12; month++) {
        final monthlyTarget = {
          'assigned_target_id': assignedTargetId,
          'month': month,
          'target_amount': monthlyAmount,
          'created_at': DateTime.now().toIso8601String(),
        };

        await Supabase.instance.client
            .from('assigned_monthly_targets')
            .insert(monthlyTarget);
      }

      print(
          'Created 12 monthly targets for assigned target: $assignedTargetId');
    } catch (e) {
      print('Error creating monthly targets: $e');
    }
  }

  // Delete monthly targets for an assigned target
  Future<void> _deleteMonthlyTargets(String assignedTargetId) async {
    try {
      // Delete all monthly targets for this assigned target
      await Supabase.instance.client
          .from('assigned_monthly_targets')
          .delete()
          .eq('assigned_target_id', assignedTargetId);

      print('Deleted monthly targets for assigned target: $assignedTargetId');
    } catch (e) {
      print('Error deleting monthly targets: $e');
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
        actions: [
          IconButton(
            onPressed: fetchData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
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
                    // Target Selection
                    const Text(
                      "Select Target to Update",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                                  'Year $year - LKR ${formatWithCommas(target['amount'] ?? 0)}'),
                            );
                          }).toList(),
                          onChanged: (Map<String, dynamic>? newValue) async {
                            setState(() {
                              selectedTarget = newValue;
                              if (newValue != null) {
                                _revenueController.text =
                                    formatWithCommas(newValue['amount'] ?? 0);
                              }
                            });

                            // Clear existing member values and load new ones for selected target
                            if (newValue != null) {
                              // Clear all member controllers first
                              for (var controller in memberControllers.values) {
                                controller.clear();
                              }
                              // Load assigned targets for the new selected target
                              await _loadMemberAssignedTargets();
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

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
                        hintText: "Enter target revenue",
                        prefixText: "LKR ",
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter target revenue';
                        }
                        final amount =
                            double.tryParse(value.replaceAll(',', ''));
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    // Sales Members Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Sales Members",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isLoadingMembers)
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Loading member targets...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                      ],
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
                  '${member['first_name'] ?? ''}',
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
