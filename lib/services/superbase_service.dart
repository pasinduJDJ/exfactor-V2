import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exfactor/models/project_model.dart';
import 'package:exfactor/models/notification_model.dart';
import 'package:exfactor/models/task_model.dart';
import 'package:exfactor/models/task_status_request_model.dart';
import 'dart:io';
import 'package:exfactor/models/target_model.dart';

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
        .select('project_id, title, status')
        .or('status.eq.pending,status.eq.On Progress,status.eq.on progress,status.eq.progress,status.eq.in progress'); // Get projects suitable for task assignment

    return List<Map<String, dynamic>>.from(response);
  }

  // GET PROJECTS FOR TASK ASSIGNMENT (more comprehensive)
  static Future<List<Map<String, dynamic>>>
      getProjectsForTaskAssignment() async {
    try {
      final response = await _client
          .from('project')
          .select('project_id, title, status')
          .or('status.eq.pending,status.eq.On Progress,status.eq.on progress,status.eq.progress,status.eq.in progress')
          .order('title'); // Order by title for better UX

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching projects for task assignment: $e');
      throw Exception(
          'Failed to fetch projects for task assignment: ${e.toString()}');
    }
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

  // GET SUPERVISORS AND ADMINS (users with supervisor or admin role)
  static Future<List<Map<String, dynamic>>> getSupervisorsAndAdmins() async {
    final response = await _client
        .from('user')
        .select('member_id, first_name, last_name, role')
        .or('role.eq.Supervisor,role.eq.Admin');

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

  // Update just the status of a task
  static Future<void> updateTaskStatus(int taskId, String newStatus) async {
    await _client
        .from('task')
        .update({'status': newStatus}).eq('task_id', taskId);
  }

  // DELETE TASK
  static Future<void> deleteTask(int taskId) async {
    await _client.from('task').delete().eq('task_id', taskId);
  }

  // Technical  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // GET TECHNICAL MEMBERS (users with Technical role)
  static Future<List<Map<String, dynamic>>> getTechnicalMembers() async {
    try {
      print('Querying for technical members with role: Technical');
      final response = await _client
          .from('user')
          .select('member_id, first_name, last_name')
          .or('role.eq.Technical');
      print('Technical members query response: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error in getTechnicalMembers: $e');
      rethrow;
    }
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
    final response = await _client
        .from('user')
        .select(
            'email, password, role, member_id, first_name, last_name, mobile, birthday, join_date, designation_date, profile_image, supervisor, emergency_name, emergency_number, emergency_relationship, position')
        .eq('email', email)
        .maybeSingle();
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

  // Target Management ////////////////////////////////////////////////////////////////////////////////////////////////////

  // Insert a new target
  static Future<String> insertTarget(TargetModel target) async {
    final targetData = target.toMap();
    // Remove id if it's null to let database handle auto-increment
    if (targetData['id'] == null) {
      targetData.remove('id');
    }

    final response = await _client.from('targets').insert(targetData).select();
    return response[0]['id']; // Return the created target ID
  }

  // Get all targets
  static Future<List<Map<String, dynamic>>> getAllTargets() async {
    try {
      final response = await _client.from('targets').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching targets: $e');
      throw Exception('Failed to fetch targets: ${e.toString()}');
    }
  }

  // Get target by year
  static Future<Map<String, dynamic>?> getTargetByYear(int year) async {
    try {
      final yearDate = DateTime(year);
      final response = await _client
          .from('targets')
          .select()
          .eq('year', yearDate.toIso8601String().split('T')[0])
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching target by year: $e');
      throw Exception('Failed to fetch target by year: ${e.toString()}');
    }
  }

  // Get target by ID
  static Future<Map<String, dynamic>?> getTargetById(String targetId) async {
    try {
      final response = await _client
          .from('targets')
          .select()
          .eq('id', targetId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching target by ID: $e');
      throw Exception('Failed to fetch target by ID: ${e.toString()}');
    }
  }

  // Insert assigned target
  static Future<String> insertAssignedTarget(
      AssignedTargetModel assignedTarget) async {
    final assignedTargetData = assignedTarget.toMap();
    // Remove id if it's null to let database handle auto-increment
    if (assignedTargetData['id'] == null) {
      assignedTargetData.remove('id');
    }

    final response = await _client
        .from('assigned_targets')
        .insert(assignedTargetData)
        .select();
    return response[0]['id']; // Return the created assigned target ID
  }

  // Get assigned targets by annual target ID
  static Future<List<Map<String, dynamic>>> getAssignedTargetsByAnnualTargetId(
      String annualTargetId) async {
    try {
      final response = await _client
          .from('assigned_targets')
          .select()
          .eq('annual_target_id', annualTargetId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching assigned targets: $e');
      throw Exception('Failed to fetch assigned targets: ${e.toString()}');
    }
  }

  // Insert assigned monthly target
  static Future<void> insertAssignedMonthlyTarget(
      AssignedMonthlyTargetModel monthlyTarget) async {
    final monthlyTargetData = monthlyTarget.toMap();
    // Remove id if it's null to let database handle auto-increment
    if (monthlyTargetData['id'] == null) {
      monthlyTargetData.remove('id');
    }

    await _client.from('assigned_monthly_targets').insert(monthlyTargetData);
  }

  // Get assigned monthly targets by assigned target ID
  static Future<List<Map<String, dynamic>>>
      getAssignedMonthlyTargetsByAssignedTargetId(
          String assignedTargetId) async {
    try {
      final response = await _client
          .from('assigned_monthly_targets')
          .select()
          .eq('assigned_target_id', assignedTargetId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching assigned monthly targets: $e');
      throw Exception(
          'Failed to fetch assigned monthly targets: ${e.toString()}');
    }
  }

  // Get sales team members (users with role 'Sales')
  static Future<List<Map<String, dynamic>>> getSalesTeamMembers() async {
    try {
      final response = await _client
          .from('user')
          .select(
              'user_id, member_id, first_name, last_name, email, position, role')
          .eq('role', 'Sales');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching sales team members: $e');
      throw Exception('Failed to fetch sales team members: ${e.toString()}');
    }
  }

  // Get assigned targets for a specific user
  static Future<List<Map<String, dynamic>>> getAssignedTargetsByUserId(
      String userId) async {
    try {
      print('Querying assigned_targets for user_id: $userId');
      final response =
          await _client.from('assigned_targets').select().eq('user_id', userId);
      print('Assigned targets response: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching assigned targets for user: $e');
      throw Exception('Failed to fetch assigned targets: ${e.toString()}');
    }
  }

  // Get current user's assigned targets with monthly breakdown
  static Future<Map<String, dynamic>?> getCurrentUserAssignedTargets(
      String userId) async {
    try {
      print('Fetching assigned targets for user: $userId');

      // Get assigned targets for the user
      final assignedTargets = await getAssignedTargetsByUserId(userId);
      print('Found ${assignedTargets.length} assigned targets');

      if (assignedTargets.isEmpty) {
        print('No assigned targets found for user: $userId');
        return null;
      }

      // Get the most recent assigned target (assuming one per year)
      final latestAssignedTarget = assignedTargets.first;
      final assignedTargetId = latestAssignedTarget['id'];
      print('Latest assigned target ID: $assignedTargetId');

      // Get monthly targets for this assigned target
      final monthlyTargets =
          await getAssignedMonthlyTargetsByAssignedTargetId(assignedTargetId);
      print('Found ${monthlyTargets.length} monthly targets');

      return {
        'assigned_target': latestAssignedTarget,
        'monthly_targets': monthlyTargets,
      };
    } catch (e) {
      print('Error fetching current user assigned targets: $e');
      throw Exception(
          'Failed to fetch current user assigned targets: ${e.toString()}');
    }
  }

  // Get deals for a specific user
  static Future<List<Map<String, dynamic>>> getDealsByUserId(
      String userId) async {
    try {
      final response =
          await _client.from('deals').select().eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching deals for user: $e');
      throw Exception('Failed to fetch deals: ${e.toString()}');
    }
  }

  // Get deals by assigned target ID
  static Future<List<Map<String, dynamic>>> getDealsByAssignedTargetId(
      String assignedTargetId) async {
    try {
      final response = await _client
          .from('deals')
          .select()
          .eq('assigned_target_id', assignedTargetId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching deals by assigned target ID: $e');
      throw Exception(
          'Failed to fetch deals by assigned target ID: ${e.toString()}');
    }
  }

  // Get all deals (for admin company-wide tracking)
  static Future<List<Map<String, dynamic>>> getAllDeals() async {
    try {
      final response = await _client.from('deals').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching all deals: $e');
      throw Exception('Failed to fetch all deals: ${e.toString()}');
    }
  }

  // Update target
  static Future<void> updateTarget(
      String targetId, Map<String, dynamic> updatedData) async {
    try {
      await _client.from('targets').update(updatedData).eq('id', targetId);
    } catch (e) {
      print('Error updating target: $e');
      throw Exception('Failed to update target: ${e.toString()}');
    }
  }

  // Update assigned target
  static Future<void> updateAssignedTarget(
      String assignedTargetId, Map<String, dynamic> updatedData) async {
    try {
      await _client
          .from('assigned_targets')
          .update(updatedData)
          .eq('id', assignedTargetId);
    } catch (e) {
      print('Error updating assigned target: $e');
      throw Exception('Failed to update assigned target: ${e.toString()}');
    }
  }

  // Update assigned monthly target
  static Future<void> updateAssignedMonthlyTarget(
      String monthlyTargetId, Map<String, dynamic> updatedData) async {
    try {
      await _client
          .from('assigned_monthly_targets')
          .update(updatedData)
          .eq('id', monthlyTargetId);
    } catch (e) {
      print('Error updating assigned monthly target: $e');
      throw Exception(
          'Failed to update assigned monthly target: ${e.toString()}');
    }
  }

  // Calculate achieved sales for a user (negotiation + won deals only)
  static Future<Map<String, double>> calculateUserAchievedSales(
      String userId) async {
    try {
      final deals = await getDealsByUserId(userId);

      double totalAchieved = 0;
      double monthlyAchieved = 0;
      double quarterlyAchieved = 0;
      double annualAchieved = 0;

      final now = DateTime.now();
      final currentMonth = now.month;
      final currentQuarter = ((currentMonth - 1) / 3).floor() + 1;
      final currentYear = now.year;

      for (final deal in deals) {
        final dealAmount = (deal['deal_amount'] ?? 0).toDouble();
        final dealStatus = (deal['deal_status'] ?? '').toString().toLowerCase();

        // Count negotiation + won deals (new achievement logic)
        if (dealStatus == 'negotiation' || dealStatus == 'won') {
          totalAchieved += dealAmount;

          // Check if deal is from current year
          final dealDate = deal['created_at'] != null
              ? DateTime.parse(deal['created_at'])
              : now;

          if (dealDate.year == currentYear) {
            annualAchieved += dealAmount;

            // Check if deal is from current quarter
            final dealQuarter = ((dealDate.month - 1) / 3).floor() + 1;
            if (dealQuarter == currentQuarter) {
              quarterlyAchieved += dealAmount;
            }

            // Check if deal is from current month
            if (dealDate.month == currentMonth) {
              monthlyAchieved += dealAmount;
            }
          }
        }
      }

      return {
        'total': totalAchieved,
        'monthly': monthlyAchieved,
        'quarterly': quarterlyAchieved,
        'annual': annualAchieved,
      };
    } catch (e) {
      print('Error calculating user achieved sales: $e');
      return {
        'total': 0,
        'monthly': 0,
        'quarterly': 0,
        'annual': 0,
      };
    }
  }

  // Deal Management ////////////////////////////////////////////////////////////////////////////////////////////////////

  // Insert a new deal
  static Future<void> insertDeal(Map<String, dynamic> dealData) async {
    try {
      await _client.from('deals').insert(dealData);
      print('Deal inserted successfully');
    } catch (e) {
      print('Error inserting deal: $e');
      throw Exception('Failed to insert deal: ${e.toString()}');
    }
  }

  // Get deal by ID
  static Future<Map<String, dynamic>?> getDealById(String dealId) async {
    try {
      final response =
          await _client.from('deals').select().eq('id', dealId).maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching deal by ID: $e');
      throw Exception('Failed to fetch deal: ${e.toString()}');
    }
  }

  // Update deal
  static Future<void> updateDeal(
      String dealId, Map<String, dynamic> updatedData) async {
    try {
      await _client.from('deals').update(updatedData).eq('id', dealId);
      print('Deal updated successfully');
    } catch (e) {
      print('Error updating deal: $e');
      throw Exception('Failed to update deal: ${e.toString()}');
    }
  }

  // Update deal status
  static Future<void> updateDealStatus(String dealId, String newStatus) async {
    try {
      await _client.from('deals').update({
        'deal_status': newStatus,
      }).eq('id', dealId);
      print('Deal status updated successfully');
    } catch (e) {
      print('Error updating deal status: $e');
      throw Exception('Failed to update deal status: ${e.toString()}');
    }
  }

  // Delete deal
  static Future<void> deleteDeal(String dealId) async {
    try {
      await _client.from('deals').delete().eq('id', dealId);
      print('Deal deleted successfully');
    } catch (e) {
      print('Error deleting deal: $e');
      throw Exception('Failed to delete deal: ${e.toString()}');
    }
  }

  // Update assigned target achieved amount
  static Future<void> updateAssignedTargetAchievedAmount(
      String assignedTargetId, double achievedAmount) async {
    try {
      await _client.from('assigned_targets').update(
          {'achieved_amount': achievedAmount}).eq('id', assignedTargetId);
      print('Assigned target achieved amount updated successfully');
    } catch (e) {
      print('Error updating assigned target achieved amount: $e');
      throw Exception(
          'Failed to update assigned target achieved amount: ${e.toString()}');
    }
  }
}
