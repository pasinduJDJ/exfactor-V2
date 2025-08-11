import 'package:exfactor/services/superbase_service.dart';

class ProjectService {
  // Get total live projects count (for admin dashboard)
  static Future<int> getTotalLiveProjectsCount() async {
    try {
      final allProjects = await SupabaseService.getAllProjects();

      int liveProjectsCount = 0;
      print('Total projects found: ${allProjects.length}');
      for (final project in allProjects) {
        final status = (project['status'] ?? '').toString().toLowerCase();
        print('Project: ${project['title']} - Status: $status');
        if (status == 'On Progress' ||
            status == 'Progress' ||
            status == 'In Progress') {
          liveProjectsCount++;
          print('✅ Counted as live project: ${project['title']}');
        }
      }
      print('Total live projects count: $liveProjectsCount');

      return liveProjectsCount;
    } catch (e) {
      print('Error getting total live projects count: $e');
      return 0;
    }
  }

  // Get projects by status
  static Future<List<Map<String, dynamic>>> getProjectsByStatus(
      String status) async {
    try {
      final allProjects = await SupabaseService.getAllProjects();

      return allProjects.where((project) {
        final projectStatus =
            (project['status'] ?? '').toString().toLowerCase();
        return projectStatus == status.toLowerCase();
      }).toList();
    } catch (e) {
      print('Error getting projects by status: $e');
      return [];
    }
  }

  // Get project statistics
  static Future<Map<String, int>> getProjectStatistics() async {
    try {
      final allProjects = await SupabaseService.getAllProjects();

      int totalProjects = allProjects.length;
      int liveProjects = 0;
      int completedProjects = 0;
      int pendingProjects = 0;

      for (final project in allProjects) {
        final status = (project['status'] ?? '').toString().toLowerCase();

        if (status == 'On Progress' ||
            status == 'progress' ||
            status == 'in progress') {
          liveProjects++;
        } else if (status == 'completed' || status == 'done') {
          completedProjects++;
        } else if (status == 'pending') {
          pendingProjects++;
        }
      }

      return {
        'total': totalProjects,
        'On Progress': liveProjects,
        'Completed': completedProjects,
        'Pending': pendingProjects,
      };
    } catch (e) {
      print('Error getting project statistics: $e');
      return {
        'total': 0,
        'On Progress': 0,
        'Completed': 0,
        'Pending': 0,
      };
    }
  }

  // Get project by ID with supervisor information
  static Future<Map<String, dynamic>?> getProjectById(int projectId) async {
    try {
      final allProjects = await SupabaseService.getAllProjects();

      final project = allProjects.firstWhere(
        (p) =>
            p['project_id'] != null &&
            p['project_id'].toString() == projectId.toString(),
        orElse: () => {},
      );

      if (project.isNotEmpty) {
        print(
            'Project found: ${project['title']} - Supervisor ID: ${project['supervisor_id']}');
        return project;
      } else {
        print('Project not found with ID: $projectId');
        return null;
      }
    } catch (e) {
      print('Error getting project by ID: $e');
      return null;
    }
  }
}
