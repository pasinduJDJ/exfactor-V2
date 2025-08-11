import 'package:flutter/material.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/colors.dart';
import '../../services/superbase_service.dart';
import '../../models/task_model.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdminAddTaskScreen extends StatefulWidget {
  const AdminAddTaskScreen({Key? key}) : super(key: key);

  @override
  State<AdminAddTaskScreen> createState() => _AdminAddTaskScreenState();
}

class _AdminAddTaskScreenState extends State<AdminAddTaskScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _taskTitleController = TextEditingController();
  String? _selectedProject;
  DateTime? _commencementDate;
  DateTime? _deliveryDate;
  String? _selectedMember;
  bool _isLoading = false;

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _availableMembers =
      []; // Changed from _technicalMembers to include both Technical and Supervisor

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProjects();
    _loadAvailableMembers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _refreshData();
    }
  }

  // Method to refresh data when navigating back to this screen
  void _onScreenResume() {
    print('Screen resumed, refreshing projects...');
    _loadProjects();
  }

  // Test database connection
  Future<void> _testDatabaseConnection() async {
    try {
      print('Testing database connection...');
      final projects = await SupabaseService.getAllProjects();
      print(
          'Database connection successful. Total projects: ${projects.length}');
      _showToast('Database connection successful!');
    } catch (e) {
      print('Database connection failed: $e');
      _showToast('Database connection failed: ${e.toString()}');
    }
  }

  // Refresh all data
  Future<void> _refreshData() async {
    print('Refreshing all data...');
    await Future.wait([
      _loadProjects(),
      _loadAvailableMembers(),
    ]);
  }

  // Load projects from database
  Future<void> _loadProjects() async {
    try {
      print('Loading all projects for task assignment...');
      final projects = await SupabaseService.getAllProjects();
      print('Projects loaded: ${projects.length}');
      print('Projects data: $projects');

      // Validate project data structure
      if (projects.isNotEmpty) {
        final firstProject = projects.first;
        print('First project structure: $firstProject');
        print('Project title: ${firstProject['title']}');
        print('Project ID: ${firstProject['project_id']}');
        print('Project status: ${firstProject['status']}');

        // Log all unique project statuses
        final statuses =
            projects.map((p) => p['status'] ?? 'Unknown').toSet().toList();
        print('Available project statuses: $statuses');
      }

      setState(() {
        _projects = projects;
      });

      if (projects.isEmpty) {
        print('Warning: No projects found in database');
        _showToast('No projects found. Please create projects first.');
      }
    } catch (e) {
      print('Error loading projects: $e');
      setState(() {
        _projects = []; // Clear projects on error
      });
      _showToast('Error loading projects: ${e.toString()}');
    }
  }

  // Load both technical and supervisor members from database
  Future<void> _loadAvailableMembers() async {
    try {
      print('Loading available members (Technical + Supervisor)...');

      // Get technical members
      final technicalMembers = await SupabaseService.getTechnicalMembers();
      print('Technical members loaded: ${technicalMembers.length}');

      // Get supervisor members
      final supervisors = await SupabaseService.getSupervisors();
      print('Supervisor members loaded: ${supervisors.length}');

      // Combine both lists
      final allMembers = <Map<String, dynamic>>[];
      allMembers.addAll(technicalMembers);
      allMembers.addAll(supervisors);

      print('Total available members: ${allMembers.length}');
      print('Available members data: $allMembers');

      setState(() {
        _availableMembers = allMembers;
      });

      if (allMembers.isEmpty) {
        print('Warning: No members found in database');
        _showToast(
            'No members found. Please add technical members or supervisors first.');
      }
    } catch (e) {
      print('Error loading available members: $e');
      setState(() {
        _availableMembers = []; // Clear members on error
      });
      _showToast('Error loading members: ${e.toString()}');
    }
  }

  // Handle task creation
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      _showToast('Please fill all required fields.');
      return;
    }
    if (_commencementDate == null || _deliveryDate == null) {
      _showToast('Please select both commencement and delivery dates.');
      return;
    }
    if (_selectedProject == null) {
      _showToast('Please select a project.');
      return;
    }
    if (_selectedMember == null) {
      _showToast('Please select a member.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Find the selected project ID
      final selectedProject = _projects.firstWhere(
        (project) =>
            '${project['title']} (ID: ${project['project_id']})' ==
            _selectedProject,
      );
      final projectId = selectedProject['project_id'];

      final task = TaskModel(
        title: _taskTitleController.text.trim(),
        startDate: _commencementDate!.toIso8601String(),
        endDate: _deliveryDate!.toIso8601String(),
        members: _selectedMember!, // Store as single member ID
        status: 'pending',
        pId: projectId,
        // supervisorId will be auto-assigned in SupabaseService
      );

      await SupabaseService.insertTask(task);
      _showToast('Task created successfully!');
      Navigator.of(context).pop('task_added');
    } catch (e) {
      _showToast('Error creating task: ${e.toString()}');
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

  Future<void> _pickDate(BuildContext context, bool isCommencement) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isCommencement) {
          _commencementDate = picked;
        } else {
          _deliveryDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Add New Tasks',
            style: TextStyle(fontWeight: FontWeight.bold)),
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                _buildTextField(_taskTitleController, 'Enter Task Title'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildProjectDropdown(
                          'Select Project',
                          _projects,
                          _selectedProject,
                          (val) => setState(() => _selectedProject = val)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _loadProjects,
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Refresh Projects',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ),
                // Debug info for projects
                if (_projects.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_projects.length} projects available (all statuses)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'No projects found',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _loadProjects,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry Loading Projects'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton.icon(
                        onPressed: _testDatabaseConnection,
                        icon: const Icon(Icons.bug_report, size: 16),
                        label: const Text('Test Database'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                _buildDateField('Task Commencement Date', _commencementDate,
                    () => _pickDate(context, true)),
                const SizedBox(height: 8),
                _buildDateField('Task Expected Delivery Date', _deliveryDate,
                    () => _pickDate(context, false)),
                const SizedBox(height: 8),
                _buildMemberDropdown(
                    'Select Member',
                    _availableMembers,
                    _selectedMember,
                    (val) => setState(() => _selectedMember = val)),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Submit',
                  backgroundColor: kPrimaryColor,
                  onPressed: _handleSubmit,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController? controller, String hint,
      {bool enabled = true, Widget? suffix}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint),
        TextFormField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            suffixIcon: suffix,
          ),
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        )
      ],
    );
  }

  Widget _buildProjectDropdown(String hint, List<Map<String, dynamic>> items,
      String? value, ValueChanged<String?> onChanged) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint),
        DropdownButtonFormField<String>(
          value: value,
          items: items.isEmpty
              ? [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No projects available'),
                  )
                ]
              : items
                  .map((e) => DropdownMenuItem(
                      value: '${e['title']} (ID: ${e['project_id']})',
                      child:
                          Text('${e['title']} (${e['status'] ?? 'Unknown'})')))
                  .toList(),
          onChanged: items.isEmpty ? null : onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: items.isEmpty ? Colors.grey[200] : Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            hintText: items.isEmpty
                ? 'Create projects first'
                : 'Select any project (all statuses)',
          ),
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        )
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        GestureDetector(
          onTap: onTap,
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
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildMemberDropdown(String hint, List<Map<String, dynamic>> items,
      String? value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item['member_id'].toString(),
                    child: Text('${item['first_name']} ${item['last_name']}'),
                  ))
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
