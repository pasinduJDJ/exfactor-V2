import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';
import 'admin/admin_single_project_screen.dart';

class ProjectScreen extends StatefulWidget {
  final String categoryTitle;
  final List<Map<String, dynamic>> projectList;

  const ProjectScreen({
    Key? key,
    required this.categoryTitle,
    required this.projectList,
  }) : super(key: key);

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
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
      body: widget.projectList.isEmpty
          ? const Center(child: Text('No projects available.'))
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 10),
              itemCount: widget.projectList.length,
              itemBuilder: (context, index) {
                final project = widget.projectList[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(project['title'] ?? 'No Title'),
                    subtitle:
                        Text('Start Date: ${project['start_date'] ?? '-'}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminSingleProjectScreen(
                            projectId: project['project_id']?.toString() ?? '',
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
