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
      appBar: AppBar(
        title: Text(
          categoryTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: taskList.isEmpty
          ? const Center(child: Text('No tasks available.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: taskList.length,
              itemBuilder: (context, index) {
                final task = taskList[index];
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
