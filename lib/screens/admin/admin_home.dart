import 'package:exfactor/screens/admin/admin_add_task_screen.dart';
import 'package:exfactor/screens/admin/admin_single_profile.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/common/custom_button.dart';
import 'package:exfactor/widgets/utils_widget.dart';
import 'package:flutter/material.dart';
import 'package:exfactor/screens/admin/admin_single_project_screen.dart';
import 'package:exfactor/screens/admin/admin_single_task_screen.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/screens/task_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  bool showLiveProject = false;
  bool showPending = false;
  bool showProgress = false;
  bool showOverdue = false;
  bool showComplete = false;
  bool showOverDueTask = false;
  bool showPendingTask = false;

  int liveProjectCount = 0;
  int overdueTaskCount = 0;
  int pendingTaskCount = 0;
  int onProgressTaskCount = 0;
  int completeTaskCount = 0;
  bool isLoadingSummary = true;

  List<Map<String, dynamic>> liveProjects = [];
  List<Map<String, dynamic>> onProgressTask = [];
  List<Map<String, dynamic>> teamMembers = [];
  List<Map<String, dynamic>> overDueTask = [];
  List<Map<String, dynamic>> pendingTask = [];
  List<Map<String, dynamic>> completeTask = [];

  @override
  void initState() {
    super.initState();
    fetchSummaryCounts();
    fetchTeamMembers();
  }

  Future<void> fetchSummaryCounts() async {
    setState(() => isLoadingSummary = true);

    final projects = await SupabaseService.getAllProjects();
    final tasks = await SupabaseService.getAllTasks();
    final now = DateTime.now();

    liveProjectCount = projects.where((p) {
      final status = (p['status'] ?? '').toString().toLowerCase();
      return status == 'on progress' || status == 'progress';
    }).length;

    // Reset lists
    pendingTask = [];
    onProgressTask = [];
    overDueTask = [];
    completeTask = [];

    // Categorize tasks and update lists
    for (final t in tasks) {
      final status = (t['status'] ?? '').toString().toLowerCase();
      final endDateStr = t['end_date'] ?? t['project_end_date'] ?? '';
      DateTime? endDate;
      try {
        endDate = endDateStr != '' ? DateTime.parse(endDateStr) : null;
      } catch (_) {
        endDate = null;
      }

      if (status == 'pending') {
        pendingTask.add(t);
      } else if (status == 'complete') {
        completeTask.add(t);
      } else if (status == 'on progress' || status == 'progress') {
        if (endDate != null && endDate.isBefore(now)) {
          overDueTask.add(t);
        } else {
          onProgressTask.add(t);
        }
      }
    }

    // Update counts from lists
    pendingTaskCount = pendingTask.length;
    onProgressTaskCount = onProgressTask.length;
    overdueTaskCount = overDueTask.length;
    completeTaskCount = completeTask.length;

    setState(() => isLoadingSummary = false);
  }

  Future<void> fetchTeamMembers() async {
    final users = await SupabaseService.getAllUsers();
    // Display all users, no role filtering
    teamMembers = users;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> statusItems = [
      {'label': 'PENDING', 'count': pendingTaskCount, 'color': cardYellow},
      {
        'label': 'ON PROGRESS',
        'count': onProgressTaskCount,
        'color': cardGreen
      },
      {'label': 'OVER DUE', 'count': overdueTaskCount, 'color': cardRed},
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(children: [
        const SizedBox(height: 30),
        isLoadingSummary
            ? const Center(child: CircularProgressIndicator())
            : UserUtils.buildStatusSummaryCard(
                statusItems,
                onTap: (index) {
                  // 0: Pending, 1: On Progress, 2: Over Due
                  String categoryTitle = statusItems[index]['label'];
                  List<Map<String, dynamic>> taskList;
                  if (index == 0) {
                    taskList = pendingTask;
                  } else if (index == 1) {
                    taskList = onProgressTask;
                  } else {
                    taskList = overDueTask;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskScreen(
                        categoryTitle: categoryTitle,
                        taskList: taskList,
                      ),
                    ),
                  );
                },
              ),
        const SizedBox(height: 30),
        const Row(
          children: [
            Text(
              "Current On going Project",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            )
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        UserUtils.buildExpandableGroup(
          title: "Live Project",
          color: kPrimaryColor,
          expanded: showLiveProject,
          onToggle: () => setState(() => showLiveProject = !showLiveProject),
          groupList: liveProjects,
          onSeeMore: (project) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminSingleProjectScreen(
                    projectId: project['project_id']?.toString() ?? ''),
              ),
            );
          },
        ),
        const SizedBox(
          height: 20,
        ),
        const Row(
          children: [
            Text(
              "Manage Task Profile",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            )
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        UserUtils.buildExpandableGroup(
          title: "OverDue Task",
          color: cardDarkRed,
          expanded: showOverDueTask,
          onToggle: () => setState(() => showOverDueTask = !showOverDueTask),
          groupList: overDueTask,
          onSeeMore: (task) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminSingleProjectScreen(
                    projectId: task['task_id']?.toString() ?? ''),
              ),
            );
          },
        ),
        const SizedBox(
          height: 10,
        ),
        UserUtils.buildExpandableGroup(
          title: "In Progress Task",
          color: cardGreen,
          expanded: showProgress,
          onToggle: () => setState(() => showProgress = !showProgress),
          groupList: onProgressTask,
          onSeeMore: (task) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminSingleTaskScreen(
                    taskId: task['task_id']?.toString() ?? ''),
              ),
            );
          },
        ),
        const SizedBox(
          height: 10,
        ),
        UserUtils.buildExpandableGroup(
          title: "Pending Task",
          color: cardYellow,
          expanded: showPending,
          onToggle: () => setState(() => showPending = !showPending),
          groupList: pendingTask,
          onSeeMore: (task) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminSingleTaskScreen(
                    taskId: task['task_id']?.toString() ?? ''),
              ),
            );
          },
        ),
        const SizedBox(
          height: 10,
        ),
        CustomButton(
          text: "Add Task",
          onPressed: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => AdminAddTaskScreen()));

            if (result == 'task_added') {
              // Refresh all data
              await fetchSummaryCounts();
              await fetchTeamMembers();
            }
          },
          backgroundColor: kPrimaryColor,
          width: double.infinity,
          height: 48,
          icon: Icon(Icons.assignment_turned_in_outlined),
        ),
        const SizedBox(
          height: 20,
        ),
      ]),
    );
  }
}
