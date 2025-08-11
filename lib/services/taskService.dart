import 'package:exfactor/services/superbase_service.dart';

class TaskService {
  // Get supervisor user details by supervisor ID
  static Future<Map<String, dynamic>?> getSupervisorById(
      int supervisorId) async {
    try {
      final userData = await SupabaseService.getUserByMemberId(supervisorId);

      if (userData != null) {
        print(
            'Supervisor found: ${userData['first_name']} ${userData['last_name']}');
        return userData;
      } else {
        print('Supervisor not found with ID: $supervisorId');
        return null;
      }
    } catch (e) {
      print('Error getting supervisor by ID: $e');
      return null;
    }
  }
}
