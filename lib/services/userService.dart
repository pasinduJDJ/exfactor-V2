import 'package:exfactor/services/superbase_service.dart';

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
}
