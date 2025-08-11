import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupervisorSingleTask extends StatefulWidget {
  final String taskId;
  const SupervisorSingleTask({super.key, required this.taskId});

  @override
  State<SupervisorSingleTask> createState() => _SupervisorSingleTaskState();
}

class _SupervisorSingleTaskState extends State<SupervisorSingleTask> {
  Map<String, dynamic>? task;
  Map<String, dynamic>? project;
  Map<String, dynamic>? supervisor;
  bool isLoading = true;
  int? _memberId;

  @override
  void initState() {
    super.initState();
    _initMemberIdAndFetchTask();
  }

  Future<void> _initMemberIdAndFetchTask() async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getInt('member_id');
    if (memberId != null) {
      setState(() {
        _memberId = memberId;
      });
      await fetchTask();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchTask() async {
    try {
      final taskIdInt = int.tryParse(widget.taskId);
      if (taskIdInt == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      final data = await SupabaseService.getAllTasks();
      final t = data.firstWhere((t) => t['task_id'].toString() == widget.taskId,
          orElse: () => {});
      if (t.isEmpty) {
        setState(() {
          task = null;
          isLoading = false;
        });
        return;
      }
      // Fetch project and supervisor
      final projectId =
          t['p_id'] is int ? t['p_id'] : int.tryParse(t['p_id'].toString());
      Map<String, dynamic>? proj;
      Map<String, dynamic>? sup;
      if (projectId != null) {
        proj = await SupabaseService.getProjectById(projectId);
        if (proj != null && proj['supervisor_id'] != null) {
          final supervisorId = proj['supervisor_id'] is int
              ? proj['supervisor_id']
              : int.tryParse(proj['supervisor_id'].toString());
          if (supervisorId != null) {
            sup = await SupabaseService.getUserByMemberId(supervisorId);
          }
        }
      }
      setState(() {
        task = t;
        project = proj;
        supervisor = sup;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KbgColor,
      appBar: AppBar(
        title: const Text('Single Task',
            style: TextStyle(fontWeight: FontWeight.bold)),
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : task == null
              ? const Center(child: Text('Task not found'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                color: kWhite,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              child: Text(
                                project != null && project!['title'] != null
                                    ? project!['title']
                                    : 'Project',
                                style: const TextStyle(
                                    fontSize: 20,
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _infoRow('Task Title',
                                      task!['title']?.toString() ?? ''),
                                  const Divider(thickness: 1),
                                  _infoRow('Commencement Date',
                                      task!['start_date'] ?? ''),
                                  const Divider(thickness: 1),
                                  _infoRow('Expected Delivery Date',
                                      task!['end_date'] ?? ''),
                                  const Divider(thickness: 1),
                                  _infoRow(
                                      'Supervisor name',
                                      supervisor != null
                                          ? '${supervisor!['first_name'] ?? ''} ${supervisor!['last_name'] ?? ''}'
                                          : 'N/A'),
                                  const Divider(thickness: 1),
                                  _infoRow('Status', task!['status'] ?? ''),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      CustomButton(
                        text: "Request Status Update",
                        width: double.infinity,
                        backgroundColor: kPrimaryColor,
                        onPressed: () => _showStatusRequestDialog(context),
                      ),
                    ],
                  ),
                ),
    );
  }

  void _showStatusRequestDialog(BuildContext context) async {
    String? selectedStatus;
    final statuses = ['On Progress', 'Hold', 'Complete'];
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Request Status Change'),
          content: DropdownButtonFormField<String>(
            value: selectedStatus,
            items: statuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) {
              selectedStatus = val;
            },
            decoration: const InputDecoration(
              labelText: 'Select new status',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedStatus == null) return;
                Navigator.of(ctx).pop();
                await _submitStatusRequest(selectedStatus!);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitStatusRequest(String status) async {
    try {
      if (_memberId == null) {
        throw Exception('Technician ID not found in session');
      }
      final taskId = int.tryParse(task!['task_id'].toString());
      if (taskId == null) throw Exception('Task ID not found');
      await SupabaseService.insertStatusRequest(taskId, _memberId!, status);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status change request submitted!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label : ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
