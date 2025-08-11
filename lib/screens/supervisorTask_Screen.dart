import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';
import 'supervisor/supervisor_single_task.dart';

class SupervisorTaskScreen extends StatelessWidget {
  final String categoryTitle;
  final List<Map<String, dynamic>> taskList;

  const SupervisorTaskScreen({
    Key? key,
    required this.categoryTitle,
    required this.taskList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          categoryTitle,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: taskList.isEmpty
          ? const Center(child: Text('No tasks available.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 5),
              itemCount: taskList.length,
              itemBuilder: (context, index) {
                final task = taskList[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: ListTile(
                    title: Text(task['title'] ?? 'No Title'),
                    subtitle: Text('Start Date: ${task['start_date'] ?? '-'}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SupervisorSingleTask(
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
