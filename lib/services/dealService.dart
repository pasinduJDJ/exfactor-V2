import 'package:exfactor/services/superbase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DealService {
  // Singleton pattern for better performance
  static final DealService _instance = DealService._internal();
  factory DealService() => _instance;
  DealService._internal();

  // Create a new deal
  static Future<bool> createDeal({
    required String prospectName,
    required double dealSize,
    required String product,
    required String city,
    required String country,
    required String phone,
    required String mobile,
    required String email,
    required String website,
    required String currentSolution,
    String? dealStatus,
  }) async {
    try {
      // Get current user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final memberId = prefs.getInt('member_id');

      if (memberId == null) {
        print('No member ID found in SharedPreferences');
        return false;
      }

      // Get current user's UUID
      final userData = await SupabaseService.getUserByMemberId(memberId);
      if (userData == null) {
        print('No user data found for member ID: $memberId');
        return false;
      }

      final currentUserId = userData['user_id'];
      print('Current user UUID: $currentUserId');

      // Step 1: Validate user has assigned target for current year
      final currentYear = DateTime.now().year;
      final assignedTarget =
          await _getUserAssignedTargetForYear(currentUserId, currentYear);

      if (assignedTarget == null) {
        print(
            'No assigned target found for user $currentUserId in year $currentYear');
        return false;
      }

      print('Found assigned target: ${assignedTarget['id']}');

      // Step 2: Prepare deal data with target association
      final dealData = {
        'user_id': currentUserId,
        'assigned_target_id': assignedTarget['id'], // Link to assigned target
        'prospect_name': prospectName,
        'deal_amount': dealSize,
        'product': product,
        'city': city,
        'country': country,
        'phone_number': phone,
        'mobile_number': mobile,
        'email': email,
        'website': website,
        'current_solution': currentSolution,
        'deal_status': dealStatus ?? 'active',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Step 3: Insert deal into database
      await SupabaseService.insertDeal(dealData);
      print('Deal created successfully for user: $currentUserId');

      // Step 4: Update achieved amount in assigned target
      await _updateAssignedTargetAchievedAmount(assignedTarget['id']);

      return true;
    } catch (e) {
      print('Error creating deal: $e');
      return false;
    }
  }

  // Get user's assigned target for a specific year
  static Future<Map<String, dynamic>?> _getUserAssignedTargetForYear(
      String userId, int year) async {
    try {
      final assignedTargets =
          await SupabaseService.getAssignedTargetsByUserId(userId);

      for (final target in assignedTargets) {
        // Get the annual target to check the year
        final annualTargetId = target['annual_target_id'];
        final annualTarget =
            await SupabaseService.getTargetById(annualTargetId);

        if (annualTarget != null) {
          final targetYear = DateTime.parse(annualTarget['year']).year;
          if (targetYear == year) {
            return target;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting user assigned target for year: $e');
      return null;
    }
  }

  // Update achieved amount in assigned target
  static Future<void> _updateAssignedTargetAchievedAmount(
      String assignedTargetId) async {
    try {
      // Get all deals for this assigned target
      final deals =
          await SupabaseService.getDealsByAssignedTargetId(assignedTargetId);

      // Calculate total achieved amount (only closed/won deals)
      double totalAchieved = 0;
      for (final deal in deals) {
        final status = (deal['deal_status'] ?? '').toString().toLowerCase();
        if (status == 'closed' || status == 'won' || status == 'completed') {
          totalAchieved += (deal['deal_amount'] ?? 0).toDouble();
        }
      }

      // Update the assigned target with new achieved amount
      await SupabaseService.updateAssignedTargetAchievedAmount(
          assignedTargetId, totalAchieved);
      print(
          'Updated achieved amount for target $assignedTargetId: $totalAchieved');
    } catch (e) {
      print('Error updating achieved amount: $e');
    }
  }

  // Get all deals for current user
  static Future<List<Map<String, dynamic>>> getCurrentUserDeals() async {
    try {
      // Get current user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final memberId = prefs.getInt('member_id');

      if (memberId == null) {
        print('No member ID found in SharedPreferences');
        return [];
      }

      // Get current user's UUID
      final userData = await SupabaseService.getUserByMemberId(memberId);
      if (userData == null) {
        print('No user data found for member ID: $memberId');
        return [];
      }

      final currentUserId = userData['user_id'];
      print('Current user UUID: $currentUserId');

      // Get deals for current user
      final deals = await SupabaseService.getDealsByUserId(currentUserId);
      print('Found ${deals.length} deals for user');

      return deals;
    } catch (e) {
      print('Error fetching user deals: $e');
      return [];
    }
  }

  // Categorize deals by time period
  static Map<String, List<Map<String, dynamic>>> categorizeDealsByPeriod(
    List<Map<String, dynamic>> deals,
  ) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final currentQuarter = ((currentMonth - 1) / 3).floor() + 1;

    List<Map<String, dynamic>> thisMonthDeals = [];
    List<Map<String, dynamic>> thisQuarterDeals = [];
    List<Map<String, dynamic>> thisYearDeals = [];
    List<Map<String, dynamic>> pastDeals = [];

    for (final deal in deals) {
      final createdAt =
          deal['created_at'] != null ? DateTime.parse(deal['created_at']) : now;

      if (createdAt.year == currentYear) {
        thisYearDeals.add(deal);

        if (createdAt.month == currentMonth) {
          thisMonthDeals.add(deal);
        }

        final dealQuarter = ((createdAt.month - 1) / 3).floor() + 1;
        if (dealQuarter == currentQuarter) {
          thisQuarterDeals.add(deal);
        }
      } else {
        pastDeals.add(deal);
      }
    }

    return {
      'this_month': thisMonthDeals,
      'this_quarter': thisQuarterDeals,
      'this_year': thisYearDeals,
      'past': pastDeals,
    };
  }

  // Calculate deal statistics
  static Map<String, double> calculateDealStatistics(
    List<Map<String, dynamic>> deals,
  ) {
    double totalAmount = 0;
    double closedAmount = 0;
    double pendingAmount = 0;
    int totalDeals = deals.length;
    int closedDeals = 0;
    int pendingDeals = 0;

    for (final deal in deals) {
      final amount = (deal['deal_amount'] ?? 0).toDouble();
      final status = (deal['deal_status'] ?? '').toString().toLowerCase();

      totalAmount += amount;

      if (status == 'closed' || status == 'won' || status == 'completed') {
        closedAmount += amount;
        closedDeals++;
      } else {
        pendingAmount += amount;
        pendingDeals++;
      }
    }

    return {
      'total_amount': totalAmount,
      'closed_amount': closedAmount,
      'pending_amount': pendingAmount,
      'total_deals': totalDeals.toDouble(),
      'closed_deals': closedDeals.toDouble(),
      'pending_deals': pendingDeals.toDouble(),
      'success_rate': totalDeals > 0 ? (closedDeals / totalDeals) * 100 : 0,
    };
  }

  // Get deal statistics for current user
  static Future<Map<String, double>> getCurrentUserDealStatistics() async {
    try {
      final deals = await getCurrentUserDeals();
      return calculateDealStatistics(deals);
    } catch (e) {
      print('Error calculating deal statistics: $e');
      return {
        'total_amount': 0,
        'closed_amount': 0,
        'pending_amount': 0,
        'total_deals': 0,
        'closed_deals': 0,
        'pending_deals': 0,
        'success_rate': 0,
      };
    }
  }

  // Update deal
  static Future<bool> updateDeal({
    required String dealId,
    required String prospectName,
    required double dealSize,
    required String product,
    required String city,
    required String country,
    required String phone,
    required String mobile,
    required String email,
    required String website,
    required String currentSolution,
    required String dealStatus,
  }) async {
    try {
      // Prepare updated deal data
      final updatedDealData = {
        'prospect_name': prospectName,
        'deal_amount': dealSize,
        'product': product,
        'city': city,
        'country': country,
        'phone_number': phone,
        'mobile_number': mobile,
        'email': email,
        'website': website,
        'current_solution': currentSolution,
        'deal_status': dealStatus,
      };

      // Update deal in database
      await SupabaseService.updateDeal(dealId, updatedDealData);
      print('Deal updated successfully: $dealId');

      return true;
    } catch (e) {
      print('Error updating deal: $e');
      return false;
    }
  }

  // Update deal status
  static Future<bool> updateDealStatus(String dealId, String newStatus) async {
    try {
      await SupabaseService.updateDealStatus(dealId, newStatus);
      return true;
    } catch (e) {
      print('Error updating deal status: $e');
      return false;
    }
  }

  // Delete deal
  static Future<bool> deleteDeal(String dealId) async {
    try {
      await SupabaseService.deleteDeal(dealId);
      return true;
    } catch (e) {
      print('Error deleting deal: $e');
      return false;
    }
  }

  // Get deal by ID
  static Future<Map<String, dynamic>?> getDealById(String dealId) async {
    try {
      return await SupabaseService.getDealById(dealId);
    } catch (e) {
      print('Error fetching deal by ID: $e');
      return null;
    }
  }

  // Validate if user has assigned target for current year
  static Future<bool> validateUserHasAssignedTarget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memberId = prefs.getInt('member_id');

      if (memberId == null) {
        return false;
      }

      final userData = await SupabaseService.getUserByMemberId(memberId);
      if (userData == null) {
        return false;
      }

      final currentUserId = userData['user_id'];
      final currentYear = DateTime.now().year;
      final assignedTarget =
          await _getUserAssignedTargetForYear(currentUserId, currentYear);

      return assignedTarget != null;
    } catch (e) {
      print('Error validating user assigned target: $e');
      return false;
    }
  }

  // Validate deal data
  static Map<String, String?> validateDealData({
    required String prospectName,
    required String dealSize,
    required String product,
    required String city,
    required String country,
    required String phone,
    required String mobile,
    required String email,
    required String website,
    required String currentSolution,
  }) {
    Map<String, String?> errors = {};

    // Validate prospect name
    if (prospectName.trim().isEmpty) {
      errors['prospectName'] = 'Prospect name is required';
    }

    // Validate deal size
    final amount = double.tryParse(dealSize);
    if (amount == null || amount <= 0) {
      errors['dealSize'] = 'Please enter a valid deal amount';
    }

    // Validate product
    if (product.trim().isEmpty) {
      errors['product'] = 'Product is required';
    }

    // Validate city
    if (city.trim().isEmpty) {
      errors['city'] = 'City is required';
    }

    // Validate country
    if (country.trim().isEmpty) {
      errors['country'] = 'Country is required';
    }

    // Validate phone (optional but if provided, should be valid)
    if (phone.trim().isNotEmpty && phone.length < 10) {
      errors['phone'] = 'Please enter a valid phone number';
    }

    // Validate mobile (optional but if provided, should be valid)
    if (mobile.trim().isNotEmpty && mobile.length < 10) {
      errors['mobile'] = 'Please enter a valid mobile number';
    }

    // Validate email (optional but if provided, should be valid email)
    if (email.trim().isNotEmpty && !_isValidEmail(email)) {
      errors['email'] = 'Please enter a valid email address';
    }

    // Validate website (optional but if provided, should be valid URL)
    if (website.trim().isNotEmpty && !_isValidUrl(website)) {
      errors['website'] = 'Please enter a valid website URL';
    }

    // Validate current solution (optional but if provided, should not be empty)
    if (currentSolution.trim().isNotEmpty &&
        currentSolution.trim().length < 3) {
      errors['currentSolution'] =
          'Current solution should be at least 3 characters';
    }

    return errors;
  }

  // Helper method to validate URL
  static bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper method to validate email
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Get deal status options
  static List<String> getDealStatusOptions() {
    return [
      'active',
      'won',
      'closed',
    ];
  }

  // Get deal status display names
  static Map<String, String> getDealStatusDisplayNames() {
    return {
      'active': 'Active',
      'won': 'Won',
      'closed': 'Closed',
    };
  }

  // Get total closed deals count (for admin dashboard)
  static Future<int> getTotalClosedDealsCount() async {
    try {
      final allDeals = await SupabaseService.getAllDeals();

      int closedDealsCount = 0;
      for (final deal in allDeals) {
        final status = (deal['deal_status'] ?? '').toString().toLowerCase();
        if (status == 'closed' || status == 'won' || status == 'completed') {
          closedDealsCount++;
        }
      }

      return closedDealsCount;
    } catch (e) {
      print('Error getting total closed deals count: $e');
      return 0;
    }
  }
}
