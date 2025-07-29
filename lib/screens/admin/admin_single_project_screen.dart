import 'package:exfactor/screens/admin/admin_single_task_screen.dart';
import 'package:exfactor/widgets/common/custom_app_bar_with_icon.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/widgets/utils_widget.dart';
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:flutter/services.dart';
import 'package:exfactor/screens/admin/admin_update_project_screen.dart';

class AdminSingleProjectScreen extends StatefulWidget {
  final String projectId;
  const AdminSingleProjectScreen({Key? key, required this.projectId})
      : super(key: key);

  @override
  State<AdminSingleProjectScreen> createState() =>
      _AdminSingleProjectScreenState();
}

class _AdminSingleProjectScreenState extends State<AdminSingleProjectScreen> {
  Map<String, dynamic>? project;
  bool isLoading = true;
  List<Map<String, dynamic>> projectTasks = [];
  bool isLoadingTasks = true;
  String? selectedStatus;
  final List<String> statusOptions = [
    'Pending',
    'In Progress',
    'Completed',
    'Archived',
  ];
  List<Map<String, dynamic>> archivedProjects = [];
  bool showProjectArchived = false;
  String? supervisorName;

  @override
  void initState() {
    super.initState();
    fetchProject();
    fetchTasks();
  }

  Future<void> fetchProject() async {
    try {
      final projectIdInt = int.tryParse(widget.projectId);
      if (projectIdInt == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      final data = await SupabaseService.getAllProjects();
      final proj = data.firstWhere(
          (p) => p['project_id'].toString() == widget.projectId,
          orElse: () => {});
      String? supName;
      if (proj.isNotEmpty && proj['supervisor_id'] != null) {
        final sup = await SupabaseService.getUserByMemberId(
          proj['supervisor_id'] is int
              ? proj['supervisor_id']
              : int.tryParse(proj['supervisor_id'].toString()) ?? 0,
        );
        if (sup != null) {
          supName = ((sup['first_name'] ?? '') + ' ' + (sup['last_name'] ?? ''))
              .trim();
        }
      }
      setState(() {
        project = proj.isNotEmpty ? proj : null;
        supervisorName = supName;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchTasks() async {
    setState(() {
      isLoadingTasks = true;
    });
    final projectIdInt = int.tryParse(widget.projectId);
    if (projectIdInt == null) {
      setState(() {
        isLoadingTasks = false;
      });
      return;
    }
    final tasks = await SupabaseService.getTasksForProject(projectIdInt);
    setState(() {
      projectTasks = tasks;
      isLoadingTasks = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: KbgColor,
        appBar: AppBar(
          title: Text(
            isLoading
                ? "Loading..."
                : (project == null
                    ? "Project Not Found"
                    : "${project!['title']} Project Details"),
          ),
        ),
        // appBar: CustomAppBarWithIcon(
        //   icon: Icons.task,
        //   title: isLoading
        //       ? "Loading..."
        //       : (project == null
        //           ? "Project Not Found"
        //           : "${project!['title']} Project Details"),
        // ),
        body: ListView(
          children: [
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : project == null
                    ? const Center(child: Text('Project not found'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  "Project Details",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _infoRow('Project Title',
                                        project!['title'] ?? ''),
                                    const Divider(thickness: 1),
                                    _infoRow('Project Message',
                                        project!['description'] ?? ''),
                                    const Divider(thickness: 1),
                                    _infoRow(
                                        'Supervisor', supervisorName ?? ''),
                                    const Divider(thickness: 1),
                                    _infoRow('Commencement Date',
                                        project!['start_date'] ?? ''),
                                    const Divider(thickness: 1),
                                    _infoRow('Expected Delivery Date',
                                        project!['end_date'] ?? ''),
                                    const Divider(thickness: 1),
                                    _infoRow('Current Status ',
                                        project!['status'] ?? ''),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                Text(
                                  "Client Details",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _infoRow('Client Name or Company',
                                        project!['client_name'] ?? ''),
                                    const Divider(thickness: 1),
                                    _infoRow('Primary Contact Person',
                                        project!['contact_person'] ?? ''),
                                    const Divider(thickness: 1),
                                    _infoRow('Contact email',
                                        project!['contact_email'] ?? '',
                                        copy: true),
                                    const Divider(thickness: 1),
                                    _infoRow('Contact number',
                                        project!['contact_mobile'] ?? '',
                                        copy: true),
                                    const Divider(thickness: 1),
                                    _infoRow('Client Country',
                                        project!['client_country'] ?? ''),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            CustomButton(
                              text: "In Archive Project",
                              onPressed: () => _archiveProject(context),
                              backgroundColor: cardDarkRed,
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            CustomButton(
                              text: "Update Project",
                              backgroundColor: cardGreen,
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AdminUpdateProjectScreen(
                                            projectId: widget.projectId),
                                  ),
                                );
                                fetchProject();
                              },
                            ),
                            const SizedBox(height: 16),
                            UserUtils.buildExpandableGroup(
                              title: "${project!['title']} ",
                              color: kPrimaryColor,
                              expanded: isLoadingTasks,
                              onToggle: () => setState(
                                  () => isLoadingTasks = !isLoadingTasks),
                              groupList: projectTasks,
                              onSeeMore: (task) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminSingleTaskScreen(
                                        taskId:
                                            task['task_id']?.toString() ?? ''),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
          ],
        ));
  }

  Widget _infoRow(String label, String value, {bool copy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label : ',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(child: Text(value)),
          if (copy)
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label copied!')),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String? tempStatus = project != null ? project!["status"] : null;
        if (tempStatus == null || !statusOptions.contains(tempStatus)) {
          tempStatus = statusOptions.first;
        }
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Project Status'),
              content: DropdownButton<String>(
                isExpanded: true,
                value: tempStatus,
                items: statusOptions
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    tempStatus = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (tempStatus != null && project != null) {
                      Navigator.pop(context);
                      await _updateProjectStatus(tempStatus!);
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateProjectStatus(String newStatus) async {
    try {
      final projectIdInt = int.tryParse(widget.projectId);
      if (projectIdInt == null) return;
      await SupabaseService.updateProjectStatus(projectIdInt, newStatus);
      await fetchProject();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project status updated to "$newStatus"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  void _archiveProject(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Project'),
        content: const Text('Are you sure you want to archive this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateProjectStatus('Archived');
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}
