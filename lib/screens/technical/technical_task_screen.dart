import 'package:exfactor/models/user_model.dart';
import 'package:exfactor/screens/technical/technical_single_task.dart';
import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/utils/colors.dart';
import 'package:exfactor/widgets/utils_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../userTask_Screen.dart';

class TaskTrackingBody extends StatefulWidget {
  const TaskTrackingBody({super.key});

  @override
  State<TaskTrackingBody> createState() => _TaskTrackingBodyState();
}

class _TaskTrackingBodyState extends State<TaskTrackingBody> {
  bool showPending = false;
  bool showProgress = true;
  bool showOverdue = false;
  bool showComplete = false;

  int overdueCount = 0;
  int pendingCount = 0;
  int progressCount = 0;
  int completeCount = 0;
  bool isLoading = true;

  List<Map<String, dynamic>> inProgressTasks = [];
  List<Map<String, dynamic>> inProgress = [];
  List<Map<String, dynamic>> overdueTasks = [];
  List<Map<String, dynamic>> isoverdue = [];
  List<Map<String, dynamic>> pendingTasks = [];
  List<Map<String, dynamic>> ispending = [];
  List<Map<String, dynamic>> completeTasks = [];
  List<Map<String, dynamic>> iscomplete = [];
  bool showInProgress = true;

  int? _memberId;

  @override
  void initState() {
    super.initState();
    _initMemberIdAndFetchTasks();
  }

  Future<void> _initMemberIdAndFetchTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getInt('member_id');
    if (memberId != null) {
      setState(() {
        _memberId = memberId;
      });
      await fetchAndProcessTasks();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchAndProcessTasks() async {
    if (_memberId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final allTasks = await SupabaseService.getAllTasks();
      final userId = _memberId.toString();
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;
      int overdue = 0, pending = 0, progress = 0, complete = 0;
      // Reset lists
      inProgressTasks = [];
      completeTasks = [];
      overdueTasks = [];
      pendingTasks = [];
      for (final task in allTasks) {
        final members = (task['members'] ?? '').toString().split(',');
        if (!members.contains(userId)) continue;
        final status = (task['status'] ?? '').toString().toLowerCase();
        final endDateStr =
            (task['end_date'] ?? task['project_end_date'] ?? '').toString();
        DateTime? endDate;
        try {
          endDate = endDateStr != '' ? DateTime.parse(endDateStr) : null;
        } catch (_) {
          endDate = null;
        }
        if (endDate == null ||
            endDate.month != currentMonth ||
            endDate.year != currentYear) {
          continue;
        }
        if (status == 'pending') {
          pending++;
          pendingTasks.add(task);
        } else if (status == 'complete') {
          complete++;
          completeTasks.add(task);
        } else if (status == 'on progress' || status == 'progress') {
          if (endDate != null && endDate.isBefore(now)) {
            overdue++;
            overdueTasks.add(task);
          } else {
            progress++;
            inProgressTasks.add(task);
          }
        } else if (endDate != null && endDate.isBefore(now)) {
          overdue++;
          overdueTasks.add(task);
        }
      }
      setState(() {
        overdueCount = overdue;
        pendingCount = pending;
        progressCount = progress;
        completeCount = complete;
        // Lists already updated above
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
    List<Map<String, dynamic>> statusItems = [
      {'label': 'PENDING', 'count': pendingCount, 'color': kWhite},
      {'label': 'On Progress', 'count': progressCount, 'color': kWhite},
      {'label': 'COMPLETE', 'count': completeCount, 'color': kWhite},
      {'label': 'OVER DUE', 'count': overdueCount, 'color': cardRed},
    ];
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(children: [
          SizedBox(height: 20),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : UserUtils.buildStatusSummaryCard(
                  statusItems,
                  onTap: (index) {
                    String categoryTitle = statusItems[index]['label'];
                    List<Map<String, dynamic>> taskList;
                    if (index == 0) {
                      taskList = pendingTasks;
                    } else if (index == 1) {
                      taskList = inProgressTasks;
                    } else if (index == 2) {
                      taskList = completeTasks;
                    } else {
                      taskList = overdueTasks;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserTaskScreen(
                          categoryTitle: categoryTitle,
                          taskList: taskList,
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 30),
          UserUtils.buildExpandableGroup(
            title: 'On Progress Task',
            color: cardGreen,
            expanded: showInProgress,
            onToggle: () {
              setState(() {
                showInProgress = !showInProgress;
              });
            },
            groupList: inProgressTasks,
            onSeeMore: (task) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TechnicalSingleTask(
                      taskId: task['task_id']?.toString() ?? ''),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          UserUtils.buildExpandableGroup(
            title: 'Pending Task',
            color: cardDarkYellow,
            expanded: showPending,
            onToggle: () {
              setState(() {
                showPending = !showPending;
              });
            },
            groupList: pendingTasks,
            onSeeMore: (task) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TechnicalSingleTask(
                      taskId: task['task_id']?.toString() ?? ''),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          UserUtils.buildExpandableGroup(
            title: 'Over Due Task',
            color: cardDarkRed,
            expanded: showOverdue,
            onToggle: () {
              setState(() {
                showOverdue = !showOverdue;
              });
            },
            groupList: overdueTasks,
            onSeeMore: (task) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TechnicalSingleTask(
                      taskId: task['task_id']?.toString() ?? ''),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          UserUtils.buildExpandableGroup(
            title: 'Complete Task',
            color: cardLightBlue,
            expanded: showComplete,
            onToggle: () {
              setState(() {
                showComplete = !showComplete;
              });
            },
            groupList: completeTasks,
            onSeeMore: (task) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TechnicalSingleTask(
                      taskId: task['task_id']?.toString() ?? ''),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}
