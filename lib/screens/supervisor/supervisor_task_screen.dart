import 'package:exfactor/screens/admin/admin_add_task_screen.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/common/custom_button.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupervisorTaskScreen extends StatefulWidget {
  const SupervisorTaskScreen({Key? key}) : super(key: key);

  @override
  State<SupervisorTaskScreen> createState() => _SupervisorTaskScreenState();
}

class _SupervisorTaskScreenState extends State<SupervisorTaskScreen> {
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _loading = true;
  int? _memberId;

  @override
  void initState() {
    super.initState();
    _initMemberIdAndFetchRequests();
  }

  Future<void> _initMemberIdAndFetchRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getInt('member_id');
    if (memberId != null) {
      setState(() {
        _memberId = memberId;
      });
      await _fetchRequests();
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchRequests() async {
    if (_memberId == null) return;
    setState(() => _loading = true);
    final requests = await SupabaseService.getPendingStatusRequests(_memberId!);
    setState(() {
      _pendingRequests = requests;
      _loading = false;
    });
  }

  Future<String> _getTaskTitle(int taskId) async {
    final tasks = await SupabaseService.getAllTasks();
    final task =
        tasks.firstWhere((t) => t['task_id'] == taskId, orElse: () => {});
    return task['title']?.toString() ?? 'Unknown';
  }

  Future<String> _getTechnicianName(int technicianId) async {
    final users = await SupabaseService.getAllUsers();
    final user = users.firstWhere((u) => u['member_id'] == technicianId,
        orElse: () => {});
    return user.isNotEmpty
        ? '${user['first_name']} ${user['last_name']}'
        : 'Unknown';
  }

  void _approveRequest(int requestId) async {
    await SupabaseService.approveStatusRequest(requestId);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Request approved!')));
    await _fetchRequests();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          CustomButton(
            text: "Assign New Tasks",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminAddTaskScreen()),
              );
            },
            width: double.infinity,
            backgroundColor: kPrimaryColor,
            icon: const Icon(Icons.task),
          ),
          const SizedBox(height: 30),
          const Text(
            "Status Update Request",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _loading
              ? const CircularProgressIndicator()
              : _pendingRequests.isEmpty
                  ? const Text('No pending status requests.')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pendingRequests.length,
                      itemBuilder: (context, index) {
                        final req = _pendingRequests[index];
                        return FutureBuilder<List<String>>(
                          future: Future.wait([
                            _getTaskTitle(req['task_id']),
                            _getTechnicianName(req['technician_id']),
                          ]),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const ListTile(title: Text('Loading...'));
                            }
                            final taskTitle = snapshot.data![0];
                            final techName = snapshot.data![1];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text('Task: $taskTitle'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Technician: $techName'),
                                    Text(
                                        'Requested Status: ${req['requested_status']}'),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () =>
                                      _approveRequest(req['request_id']),
                                  child: const Text('Approve'),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
        ],
      ),
    );
  }
}

class supervisorTaskCard extends StatelessWidget {
  const supervisorTaskCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: kblack,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Task Name : ABC Mobile App Project",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              "Current Status: On Progress",
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Request : Complete",
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: cardGreen.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      "Approve",
                      style: TextStyle(color: cardGreen),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
