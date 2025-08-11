import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';
import 'admin/admin_single_task_screen.dart';

class TaskScreen extends StatefulWidget {
  final String categoryTitle;
  final List<Map<String, dynamic>> taskList;

  const TaskScreen({
    Key? key,
    required this.categoryTitle,
    required this.taskList,
  }) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.categoryTitle,
        ),
        centerTitle: true,
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: widget.taskList.isEmpty
          ? const Center(child: Text('No tasks available.'))
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 10),
              itemCount: widget.taskList.length,
              itemBuilder: (context, index) {
                final task = widget.taskList[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(task['title'] ?? 'No Title'),
                    subtitle: Text('Start Date: ${task['start_date'] ?? '-'}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminSingleTaskScreen(
                            taskId: task['task_id']?.toString() ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
