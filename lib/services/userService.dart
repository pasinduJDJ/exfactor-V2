import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // Get all sales team members (users with role == 'sales')
  static Future<List<Map<String, dynamic>>> getSalesTeamMembers() async {
    try {
      final allUsers = await SupabaseService.getAllUsers();

      // Filter users with sales role
      final salesMembers = allUsers.where((user) {
        final role = (user['role'] ?? '').toString().toLowerCase();
        return role == 'sales' ||
            role == 'salesperson' ||
            role == 'sales representative';
      }).toList();

      return salesMembers;
    } catch (e) {
      print('Error fetching sales team members: $e');
      return [];
    }
  }

  // Get user by ID
  static Future<Map<String, dynamic>?> getUserById(int userId) async {
    try {
      final users = await SupabaseService.getAllUsers();
      return users.firstWhere(
        (user) => user['member_id'] == userId,
        orElse: () => {},
      );
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  // Get users by role
  static Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final allUsers = await SupabaseService.getAllUsers();

      final filteredUsers = allUsers.where((user) {
        final userRole = (user['role'] ?? '').toString().toLowerCase();
        return userRole == role.toLowerCase();
      }).toList();

      return filteredUsers;
    } catch (e) {
      print('Error fetching users by role: $e');
      return [];
    }
  }

  // Get current user by member_id from SharedPreferences
  static Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memberId = prefs.getInt('member_id');

      if (memberId == null) return null;

      final userData = await SupabaseService.getUserByMemberId(memberId);
      if (userData == null) return null;

      return UserModel.fromMap(userData);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Update user profile with enhanced error handling
  static Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    try {
      // Validate required fields
      if (data['member_id'] == null) {
        print('Error: member_id is required for profile update');
        return false;
      }

      // Validate email format if provided
      if (data['email'] != null && data['email'].toString().isNotEmpty) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(data['email'])) {
          print('Error: Invalid email format');
          return false;
        }
      }

      // Validate mobile number format if provided
      if (data['mobile'] != null && data['mobile'].toString().isNotEmpty) {
        final mobileRegex = RegExp(r'^[0-9]{10}$');
        if (!mobileRegex.hasMatch(data['mobile'])) {
          print('Error: Invalid mobile number format');
          return false;
        }
      }

      await SupabaseService.updateUserProfile(data);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Upload profile image
  static Future<String?> uploadProfileImage(
      int memberId, String imagePath) async {
    try {
      final uploadedUrl = await SupabaseService.uploadProfileImage(
          memberId.toString(), imagePath);
      if (uploadedUrl != null) {
        // Update user profile with new image URL
        await SupabaseService.updateUserProfileImage(memberId, uploadedUrl);
        return uploadedUrl;
      }
      return null;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Reset password with enhanced validation
  static Future<bool> resetPassword(
      String currentPassword, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memberId = prefs.getInt('member_id');

      if (memberId == null) return false;

      // Validate password requirements
      if (newPassword.length < 6) {
        print('Error: Password must be at least 6 characters long');
        return false;
      }

      // Get current user to verify current password
      final userData = await SupabaseService.getUserByMemberId(memberId);
      if (userData == null) return false;

      // Verify current password
      final storedPassword = userData['password'] ?? '';
      if (currentPassword != storedPassword) {
        print('Error: Current password is incorrect');
        return false;
      }

      // Update password
      await SupabaseService.updateUserProfile({
        'member_id': memberId,
        'password': newPassword,
      });

      return true;
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }

  // Get supervisor name with enhanced error handling
  static Future<String?> getSupervisorName(String? supervisorId) async {
    try {
      if (supervisorId == null || supervisorId.isEmpty) return null;

      final allUsers = await SupabaseService.getAllUsers();
      final supervisor = allUsers.firstWhere(
        (user) => user['member_id'].toString() == supervisorId,
        orElse: () => {},
      );

      if (supervisor.isEmpty) return null;

      return '${supervisor['first_name'] ?? ''} ${supervisor['last_name'] ?? ''}'
          .trim();
    } catch (e) {
      print('Error getting supervisor name: $e');
      return null;
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validate mobile number format
  static bool isValidMobile(String mobile) {
    final mobileRegex = RegExp(r'^[0-9]{10}$');
    return mobileRegex.hasMatch(mobile);
  }

  // Validate required field
  static bool isValidRequired(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
