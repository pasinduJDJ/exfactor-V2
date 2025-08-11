import 'package:flutter/material.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/colors.dart';
import '../../services/superbase_service.dart';
import '../../models/task_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:exfactor/services/projectService.dart';
import 'package:exfactor/services/taskService.dart';

class AdminUpdateTaskScreen extends StatefulWidget {
  final String taskId;
  const AdminUpdateTaskScreen({Key? key, required this.taskId})
      : super(key: key);

  @override
  State<AdminUpdateTaskScreen> createState() => _AdminUpdateTaskScreenState();
}

class _AdminUpdateTaskScreenState extends State<AdminUpdateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _membersController = TextEditingController();
  String? _selectedStatus;
  int? _selectedProjectId;
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _users = [];
  List<int> _selectedMemberIds = [];
  String? _supervisorName; // Keep this for displaying supervisor name
  bool _isLoadingSupervisor = false; // Keep this for loading state
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  TaskModel? _task; // Add back the missing _task variable

  static const List<String> _statusOptions = [
    'Pending',
    'In Progress',
    'Completed',
    'Archived',
  ];

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadUsers();
    _loadTask();
  }

  Future<void> _loadProjects() async {
    final projects = await SupabaseService.getAllProjects();
    setState(() {
      _projects = projects;
    });
  }

  Future<void> _loadUsers() async {
    final users = await SupabaseService.getAllUsers();
    setState(() {
      _users = users;
    });
  }

  Future<void> _loadTask() async {
    final allTasks = await SupabaseService.getAllTasks();
    final t = allTasks.firstWhere(
      (t) => t['task_id'].toString() == widget.taskId,
      orElse: () => {},
    );
    if (t.isEmpty) {
      _showToast('Task not found.');
      Navigator.of(context).pop();
      return;
    }
    _task = TaskModel.fromMap(t);
    _titleController.text = _task!.title;
    _startDate = DateTime.tryParse(_task!.startDate);
    _endDate = DateTime.tryParse(_task!.endDate);
    _startDateController.text = _task!.startDate;
    _endDateController.text = _task!.endDate;
    // Parse members as int list
    _selectedMemberIds = _task!.members
        .split(',')
        .where((id) => id.trim().isNotEmpty)
        .map((id) => int.tryParse(id.trim()) ?? 0)
        .where((id) => id != 0)
        .toList();
    _membersController.text = _selectedMemberIds.map((id) {
      final user =
          _users.firstWhere((u) => u['member_id'] == id, orElse: () => {});
      if (user.isNotEmpty) {
        return '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}';
      }
      return id.toString();
    }).join(', ');
    _selectedStatus = _statusOptions.firstWhere(
      (s) => s.toLowerCase() == _task!.status.toLowerCase(),
      orElse: () => _statusOptions.first,
    );
    _selectedProjectId = _task!.pId;
    // Set supervisor name from cached users if present
    if (_task!.supervisorId != null) {
      final sup = _users.firstWhere(
          (s) => s['member_id'] == _task!.supervisorId,
          orElse: () => {});
      if (sup.isNotEmpty) {
        _supervisorName = '${sup['first_name']} ${sup['last_name']}';
      }
    }
    setState(() {});
    // Ensure we also load via project to handle cases where supervisor comes via project
    await _loadSupervisorInfo();
  }

  // Load supervisor information for the project
  Future<void> _loadSupervisorInfo() async {
    if (_task?.pId == null) {
      print('No project ID available for supervisor lookup');
      return;
    }

    setState(() {
      _isLoadingSupervisor = true;
    });

    try {
      print('Loading supervisor info for project ID: ${_task!.pId}');

      // Get project details including supervisor ID
      final project = await ProjectService.getProjectById(_task!.pId);

      if (project != null && project['supervisor_id'] != null) {
        final dynamic rawSupervisorId = project['supervisor_id'];
        final int? supervisorId = rawSupervisorId is int
            ? rawSupervisorId
            : int.tryParse(rawSupervisorId.toString());
        if (supervisorId == null) {
          setState(() {
            _supervisorName = 'Supervisor not assigned';
          });
        } else {
          print('Project supervisor ID: $supervisorId');

          // Get supervisor user details
          final supervisor = await TaskService.getSupervisorById(supervisorId);

          if (supervisor != null) {
            final firstName = supervisor['first_name'] ?? '';
            final lastName = supervisor['last_name'] ?? '';
            final fullName = '$firstName $lastName'.trim();

            setState(() {
              _supervisorName =
                  fullName.isEmpty ? 'Supervisor not assigned' : fullName;
            });
            print('Supervisor name loaded: $_supervisorName');
          } else {
            setState(() {
              _supervisorName = 'Supervisor not assigned';
            });
            print('Supervisor not found, setting fallback message');
          }
        }
      } else {
        setState(() {
          _supervisorName = 'Supervisor not assigned';
        });
        print('Project has no supervisor assigned');
      }
    } catch (e) {
      print('Error loading supervisor info: $e');
      setState(() {
        _supervisorName = 'Supervisor not assigned';
      });
    } finally {
      setState(() {
        _isLoadingSupervisor = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      _showToast('Please fill all required fields.');
      return;
    }
    if (_startDate == null || _endDate == null) {
      _showToast('Please select both start and end dates.');
      return;
    }
    if (_selectedProjectId == null) {
      _showToast('Please select a project.');
      return;
    }
    if (_selectedMemberIds.isEmpty) {
      _showToast('Please select at least one member.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final updatedTask = TaskModel(
        taskId: int.tryParse(widget.taskId),
        title: _titleController.text.trim(),
        startDate: _startDate!.toIso8601String(),
        endDate: _endDate!.toIso8601String(),
        members: _selectedMemberIds.join(','),
        status: _selectedStatus!,
        pId: _selectedProjectId!,
        supervisorId: _task!.supervisorId,
      );
      await SupabaseService.updateTask(updatedTask);
      _showToast('Task updated successfully!');
      Navigator.of(context).pop();
    } catch (e) {
      // Error handling for production
      _showToast('Error updating task: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: message.toLowerCase().contains('error') ||
              message.toLowerCase().contains('failed') ||
              message.toLowerCase().contains('please')
          ? Colors.red
          : Colors.green,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Update Task',
            style: TextStyle(fontWeight: FontWeight.bold)),
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: _task == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 15),
                    _buildTextField(_titleController, 'Enter Task Title'),
                    const SizedBox(height: 10),
                    _buildDateField('Select Start Date', _startDate,
                        (pickedDate) {
                      setState(() {
                        _startDate = pickedDate;
                        _startDateController.text =
                            _startDate!.toIso8601String();
                      });
                    }),
                    const SizedBox(height: 10),
                    _buildDateField('Select End Date', _endDate, (pickedDate) {
                      setState(() {
                        _endDate = pickedDate;
                        _endDateController.text = _endDate!.toIso8601String();
                      });
                    }),
                    const SizedBox(height: 10),
                    const Text('Select Technical Members'), // Updated label
                    GestureDetector(
                      onTap: () async {
                        final selected = await showDialog<List<int>>(
                          context: context,
                          builder: (context) {
                            final tempSelected =
                                List<int>.from(_selectedMemberIds);
                            // Filter users to show only Technical members
                            final filteredUsers = _users.where((user) {
                              final role =
                                  (user['role'] ?? '').toString().toLowerCase();
                              return role ==
                                  'technical'; // Only show Technical members
                            }).toList();
                            return StatefulBuilder(
                              builder: (context, setStateDialog) {
                                return AlertDialog(
                                  title: const Text(
                                      'Select Technical Members'), // Updated title
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: ListView(
                                      shrinkWrap: true,
                                      children: filteredUsers.map((user) {
                                        final id = user['member_id'] as int;
                                        final name =
                                            '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}';
                                        return CheckboxListTile(
                                          value: tempSelected.contains(id),
                                          title: Text(name),
                                          onChanged: (checked) {
                                            setStateDialog(() {
                                              if (checked == true) {
                                                tempSelected.add(id);
                                              } else {
                                                tempSelected.remove(id);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(
                                          context, _selectedMemberIds),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, tempSelected),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                        if (selected != null) {
                          setState(() {
                            _selectedMemberIds = selected;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedMemberIds.isEmpty
                              ? 'Tap to select Technical members' // Updated placeholder
                              : _users
                                  .where((u) =>
                                      _selectedMemberIds
                                          .contains(u['member_id']) &&
                                      (u['role'] ?? '')
                                              .toString()
                                              .toLowerCase() ==
                                          'technical') // Only show Technical members
                                  .map((u) =>
                                      '${u['first_name']} ${u['last_name']}')
                                  .join(', '),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Select Project'),
                    DropdownButtonFormField<int>(
                      onChanged: null,
                      value: _selectedProjectId,
                      items: _projects
                          .map((proj) => DropdownMenuItem<int>(
                                value: proj['project_id'] is int
                                    ? proj['project_id']
                                    : int.tryParse(
                                        proj['project_id'].toString()),
                                child: Text(proj['title'] ?? ''),
                              ))
                          .toList(),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                      ),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    // Supervisor field (converted from dropdown to text field)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Supervisor'),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _isLoadingSupervisor
                              ? const Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Loading supervisor...'),
                                  ],
                                )
                              : Text(
                                  _supervisorName ?? 'Supervisor not assigned',
                                  style: TextStyle(
                                    color: (_supervisorName == null ||
                                            _supervisorName ==
                                                'Supervisor not assigned')
                                        ? Colors.grey[600]
                                        : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Select Status'),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      items: _statusOptions
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: null, // disables the dropdown
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                      ),
                      disabledHint: Text(_selectedStatus ?? ''),
                    ),
                    const SizedBox(height: 15),
                    CustomButton(
                      text: 'Update Task',
                      backgroundColor: kPrimaryColor,
                      onPressed: _handleSubmit,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
          validator: validator,
        )
      ],
    );
  }

  Widget _buildDateField(
      String label, DateTime? date, Function(DateTime) onDateSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                suffixIcon: const Icon(Icons.calendar_today, size: 20),
              ),
              controller: TextEditingController(
                  text: date == null
                      ? ''
                      : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
              // No validator here; validation is handled in _handleSubmit
            ),
          ),
        )
      ],
    );
  }
}
