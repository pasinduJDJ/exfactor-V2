import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exfactor/models/project_model.dart';
import 'package:exfactor/models/notification_model.dart';
import 'package:exfactor/models/task_model.dart';
import 'package:exfactor/models/task_status_request_model.dart';
import 'dart:io';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Project Management ////////////////////////////////////////////////////////////////////////////////////////////////////
  // INSERT PROJECT
  static Future<void> insertProject(ProjectModel project) async {
    final projectData = project.toMap();
    // Remove project_id if it's null to let database handle auto-increment
    if (projectData['project_id'] == null) {
      projectData.remove('project_id');
    }
    await _client.from('project').insert(projectData);
  }

  // GET PROJECTS (for task assignment)
  static Future<List<Map<String, dynamic>>> getProjects() async {
    final response = await _client
        .from('project')
        .select('project_id, title')
        .eq('status', 'pending'); // Only get active/pending projects

    return List<Map<String, dynamic>>.from(response);
  }

  // GET ALL PROJECTS
  static Future<List<Map<String, dynamic>>> getAllProjects() async {
    try {
      final response = await _client.from('project').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching projects: $e');
      if (e.toString().contains('Connection reset by peer') ||
          e.toString().contains('SocketException')) {
        throw Exception(
            'Network connection error. Please check your internet connection and try again.');
      } else if (e.toString().contains('JWT')) {
        throw Exception('Authentication error. Please log in again.');
      } else {
        throw Exception('Failed to fetch projects: ${e.toString()}');
      }
    }
  }

  // Update a project by project_id
  static Future<void> updateProject(ProjectModel project) async {
    if (project.projectId == null) {
      throw Exception('projectId is required for project update');
    }
    final data = project.toMap();
    data.remove('project_id'); // Don't update the project_id itself
    await _client
        .from('project')
        .update(data)
        .eq('project_id', project.projectId!);
  }

  // Supervisor ////////////////////////////////////////////////////////////////////////////////////////////////////
  // GET SUPERVISORS (users with supervisor role)
  static Future<List<Map<String, dynamic>>> getSupervisors() async {
    final response = await _client
        .from('user')
        .select('member_id, first_name, last_name')
        .eq('role', 'Supervisor');

    return List<Map<String, dynamic>>.from(response);
  }

  // Notification Management  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // INSERT NOTIFICATION
  static Future<void> insertNotification(NotificationModel notification) async {
    final notificationData = notification.toMap();
    // Remove notification_id if it's null to let database handle auto-increment
    if (notificationData['notification_id'] == null) {
      notificationData.remove('notification_id');
    }
    await _client.from('notification').insert(notificationData);
  }

  // UPDATE NOTIFICATION
  static Future<void> updateNotification(NotificationModel notification) async {
    if (notification.notification_id == null) {
      throw Exception('notification_id is required for notification update');
    }
    final data = notification.toMap();
    data.remove('notification_id'); // Don't update the notification_id itself
    await _client
        .from('notification')
        .update(data)
        .eq('notification_id', notification.notification_id!);
  }

  // GET ALL NOTIFICATIONS
  static Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final response = await _client.from('notification').select();
    return List<Map<String, dynamic>>.from(response);
  }

  // DELETE NOTIFICATION
  static Future<void> deleteNotification(int notificationId) async {
    await _client
        .from('notification')
        .delete()
        .eq('notification_id', notificationId);
  }

  // Task Management  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // GET SUPERVISOR FOR PROJECT
  static Future<int?> getSupervisorForProject(int projectId) async {
    final response = await _client
        .from('project')
        .select('supervisor_id')
        .eq('project_id', projectId)
        .maybeSingle();
    if (response == null) return null;
    return response['supervisor_id'] is int
        ? response['supervisor_id']
        : int.tryParse(response['supervisor_id'].toString());
  }

  // INSERT TASK (auto-assign supervisor_id from project)
  static Future<void> insertTask(TaskModel task) async {
    final taskData = task.toMap();
    // Remove task_id if it's null to let database handle auto-increment
    if (taskData['task_id'] == null) {
      taskData.remove('task_id');
    }
    // Fetch supervisor_id from project if not provided
    int? supervisorId = task.supervisorId;
    if (supervisorId == null) {
      supervisorId = await getSupervisorForProject(task.pId);
      if (supervisorId != null) {
        taskData['supervisor_id'] = supervisorId;
      }
    }
    await _client.from('task').insert(taskData);
  }

  // GET ALL TASKS
  static Future<List<Map<String, dynamic>>> getAllTasks() async {
    try {
      final response = await _client.from('task').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching tasks: $e');
      if (e.toString().contains('Connection reset by peer') ||
          e.toString().contains('SocketException')) {
        throw Exception(
            'Network connection error. Please check your internet connection and try again.');
      } else if (e.toString().contains('JWT')) {
        throw Exception('Authentication error. Please log in again.');
      } else {
        throw Exception('Failed to fetch tasks: ${e.toString()}');
      }
    }
  }

  // GET TASKS FOR A PROJECT
  static Future<List<Map<String, dynamic>>> getTasksForProject(
      int projectId) async {
    final response = await _client.from('task').select().eq('p_id', projectId);
    return List<Map<String, dynamic>>.from(response);
  }

  // Update a task by task_id
  static Future<void> updateTask(TaskModel task) async {
    if (task.taskId == null) {
      throw Exception('taskId is required for task update');
    }
    final data = task.toMap();
    data.remove('task_id'); // Don't update the task_id itself
    await _client.from('task').update(data).eq('task_id', task.taskId!);
  }

  // DELETE TASK
  static Future<void> deleteTask(int taskId) async {
    await _client.from('task').delete().eq('task_id', taskId);
  }

  // Technical  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // GET TECHNICAL MEMBERS (users with technician role)
  static Future<List<Map<String, dynamic>>> getTechnicalMembers() async {
    final response = await _client
        .from('user')
        .select('member_id, first_name, last_name')
        .eq('role', 'Technician');

    return List<Map<String, dynamic>>.from(response);
  }

  // Users Management ////////////////////////////////////////////////////////////////////////////////////////////////////
  // GET ALL USERS
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _client.from('user').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching users: $e');
      if (e.toString().contains('Connection reset by peer') ||
          e.toString().contains('SocketException')) {
        throw Exception(
            'Network connection error. Please check your internet connection and try again.');
      } else if (e.toString().contains('JWT')) {
        throw Exception('Authentication error. Please log in again.');
      } else {
        throw Exception('Failed to fetch users: ${e.toString()}');
      }
    }
  }

  // DELETE USER
  static Future<void> deleteUser(int userId) async {
    await _client.from('user').delete().eq('member_id', userId);
  }

  // DELETE EMERGENCY CONTACTS BY USER ID
  static Future<void> deleteEmergencyContactsByUserId(int userId) async {
    await _client.from('emergency_contact').delete().eq('u_id', userId);
  }

  // GET USER BY EMAIL
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final response =
        await _client.from('user').select().eq('email', email).maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  // GET USER PROFILE
  static Future<PostgrestMap?> getUserProfile(int userId) async {
    return await _client.from('user').select().eq('id', userId).maybeSingle();
  }

  // INSERT USER METADATA AFTER SIGN UP
  static Future<void> insertUserMetaData(Map<String, dynamic> userData) async {
    await _client.from('user').insert(userData);
  }

  // Insert a new status change request
  static Future<void> insertStatusRequest(
      int taskId, int technicianId, String requestedStatus) async {
    final request = TaskStatusRequestModel(
      taskId: taskId,
      technicianId: technicianId,
      requestedStatus: requestedStatus,
      approved: false,
      createdAt: DateTime.now(),
    );
    await _client.from('task_status_request').insert(request.toMap());
  }

  // Get all pending status requests for a supervisor's tasks
  static Future<List<Map<String, dynamic>>> getPendingStatusRequests(
      int supervisorId) async {
    // Get all tasks for this supervisor
    final tasks = await _client
        .from('task')
        .select('task_id')
        .eq('supervisor_id', supervisorId);
    final taskIds = List<int>.from(tasks.map((t) => t['task_id']));
    if (taskIds.isEmpty) return [];
    // Get all unapproved requests for these tasks
    final requests = await _client
        .from('task_status_request')
        .select()
        .inFilter('task_id', taskIds)
        .eq('approved', false);
    return List<Map<String, dynamic>>.from(requests);
  }

  // Approve a status request and update the task's status
  static Future<void> approveStatusRequest(int requestId) async {
    // Get the request
    final request = await _client
        .from('task_status_request')
        .select()
        .eq('request_id', requestId)
        .maybeSingle();
    if (request == null) return;
    final taskId = request['task_id'];
    final requestedStatus = request['requested_status'];
    // Update the request as approved
    await _client
        .from('task_status_request')
        .update({'approved': true}).eq('request_id', requestId);
    // Update the task's status
    await _client
        .from('task')
        .update({'status': requestedStatus}).eq('task_id', taskId);
  }

  // Get a project by project_id
  static Future<Map<String, dynamic>?> getProjectById(int projectId) async {
    final response = await _client
        .from('project')
        .select()
        .eq('project_id', projectId)
        .maybeSingle();
    return response;
  }

  // Get a user by member_id
  static Future<Map<String, dynamic>?> getUserByMemberId(int memberId) async {
    final response = await _client
        .from('user')
        .select()
        .eq('member_id', memberId)
        .maybeSingle();
    return response;
  }

  // Minimal user registration for admin
  static Future<void> insertUser(Map<String, dynamic> userData) async {
    // Ensure all required fields are present
    if (userData['member_id'] == null ||
        userData['first_name'] == null ||
        userData['email'] == null ||
        userData['password'] == null) {
      throw Exception('Missing required user fields');
    }
    final data = {
      'member_id': userData['member_id'],
      'first_name': userData['first_name'],
      'email': userData['email'],
      'password': userData['password'],
      'last_name': userData['last_name'] ?? '',
      'mobile': '',
      'birthday': null,
      'join_date': null,
      'designation_date': null,
      'role': userData['role'] ?? '',
      'supervisor': null,
      'emergency_name': '',
      'emergency_number': '',
      'emergency_relationship': '',
      'position': userData['position'] ?? '',
    };
    await _client.from('user').insert(data);
  }

  // Update user profile by member_id (int)
  static Future<void> updateUserProfile(
      Map<String, dynamic> updatedData) async {
    if (updatedData['member_id'] == null) {
      throw Exception('member_id is required for profile update');
    }
    final data = Map<String, dynamic>.from(updatedData);
    data.remove('user_id'); // Don't update the uuid
    data.remove('member_id'); // Don't update memberId
    await _client
        .from('user')
        .update(data)
        .eq('member_id', updatedData['member_id']);
  }

  // Get user by user_id (uuid)
  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    final response =
        await _client.from('user').select().eq('id', userId).maybeSingle();
    return response;
  }

  // Update project status by projectId
  static Future<void> updateProjectStatus(
      int projectId, String newStatus) async {
    await _client
        .from('project')
        .update({'status': newStatus}).eq('project_id', projectId);
  }

  static Future<int> getTodaysNotificationCount(int userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final response = await _client
        .from('notification')
        .select()
        .eq('user_id', userId)
        .gte('schedule_date', today.toIso8601String())
        .lt('schedule_date', tomorrow.toIso8601String());
    return (response as List).length;
  }

  // Profile Image Upload and Update ////////////////////////////////////////////////////////////////////////////////////////////////////
  // Uploads a profile image to Supabase Storage and returns the public URL
  static Future<String?> uploadProfileImage(
      String userId, String filePath) async {
    try {
      print('Starting upload for user: $userId, file: $filePath');

      final fileName =
          'profile_$userId${filePath.substring(filePath.lastIndexOf("."))}';
      print('Generated filename: $fileName');

      print('Attempting to upload to profileimages bucket...');
      await _client.storage.from('profileimages').upload(
          fileName, File(filePath),
          fileOptions: const FileOptions(upsert: true));
      print('Upload completed successfully');

      // Get public URL
      final publicUrl =
          _client.storage.from('profileimages').getPublicUrl(fileName);
      print('Public URL: $publicUrl');
      return publicUrl;
    } catch (e, stack) {
      // Error handling for production
      print('Error uploading profile image: $e');
      print('Stack trace: $stack');
      print('Error type: ${e.runtimeType}');
      return null;
    }
  }

  // Updates the user's profile_image field in the user table
  static Future<void> updateUserProfileImage(
      int memberId, String imageUrl) async {
    await _client
        .from('user')
        .update({'profile_image': imageUrl}).eq('member_id', memberId);
  }
}
