import 'package:exfactor/services/superbase_service.dart';
import 'package:exfactor/models/target_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SaleService {
  // Singleton pattern for better performance
  static final SaleService _instance = SaleService._internal();
  factory SaleService() => _instance;
  SaleService._internal();

  // Get current user's assigned targets with monthly breakdown
  static Future<Map<String, dynamic>?> getCurrentUserAssignedTargets() async {
    try {
      // Get current user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final memberId = prefs.getInt('member_id');

      if (memberId == null) {
        print('No member ID found in SharedPreferences');
        return null;
      }

      // Get current user's UUID
      final userData = await SupabaseService.getUserByMemberId(memberId);
      if (userData == null) {
        print('No user data found for member ID: $memberId');
        return null;
      }

      final currentUserId = userData['user_id'];
      print('Current user UUID: $currentUserId');

      // Get assigned targets for current user
      final assignedTargets =
          await SupabaseService.getCurrentUserAssignedTargets(currentUserId);
      print('Assigned targets: $assignedTargets');

      return assignedTargets;
    } catch (e) {
      print('Error loading user assigned targets: $e');
      return null;
    }
  }

  // Get current user's achieved sales (closed/won deals only)
  static Future<Map<String, double>> getCurrentUserAchievedSales() async {
    try {
      // Get current user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final memberId = prefs.getInt('member_id');

      if (memberId == null) {
        print('No member ID found in SharedPreferences');
        return _getDefaultAchievedSales();
      }

      // Get current user's UUID
      final userData = await SupabaseService.getUserByMemberId(memberId);
      if (userData == null) {
        print('No user data found for member ID: $memberId');
        return _getDefaultAchievedSales();
      }

      final currentUserId = userData['user_id'];
      print('Current user UUID: $currentUserId');

      // Get achieved sales for current user (closed/won deals only)
      final achievedSales =
          await SupabaseService.calculateUserAchievedSales(currentUserId);
      print('Achieved sales (closed/won): $achievedSales');

      return achievedSales;
    } catch (e) {
      print('Error loading user achieved sales: $e');
      return _getDefaultAchievedSales();
    }
  }

  // Get current user's all registered sales (ALL deals regardless of status)
  static Future<Map<String, double>> getCurrentUserAllRegisteredSales() async {
    try {
      // Get current user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final memberId = prefs.getInt('member_id');

      if (memberId == null) {
        print('No member ID found in SharedPreferences');
        return _getDefaultAchievedSales();
      }

      // Get current user's UUID
      final userData = await SupabaseService.getUserByMemberId(memberId);
      if (userData == null) {
        print('No user data found for member ID: $memberId');
        return _getDefaultAchievedSales();
      }

      final currentUserId = userData['user_id'];
      print('Current user UUID: $currentUserId');

      // Get all deals for current user
      final deals = await SupabaseService.getDealsByUserId(currentUserId);
      print('All deals for user: ${deals.length}');

      double totalRegistered = 0;
      double monthlyRegistered = 0;
      double quarterlyRegistered = 0;
      double annualRegistered = 0;

      final now = DateTime.now();
      final currentMonth = now.month;
      final currentQuarter = ((currentMonth - 1) / 3).floor() + 1;
      final currentYear = now.year;

      for (final deal in deals) {
        final dealAmount = (deal['deal_amount'] ?? 0).toDouble();
        final dealDate = deal['created_at'] != null
            ? DateTime.parse(deal['created_at'])
            : now;

        // Count ALL deals regardless of status
        totalRegistered += dealAmount;

        // Check if deal is from current year
        if (dealDate.year == currentYear) {
          annualRegistered += dealAmount;

          // Check if deal is from current quarter
          final dealQuarter = ((dealDate.month - 1) / 3).floor() + 1;
          if (dealQuarter == currentQuarter) {
            quarterlyRegistered += dealAmount;
          }

          // Check if deal is from current month
          if (dealDate.month == currentMonth) {
            monthlyRegistered += dealAmount;
          }
        }
      }

      final result = {
        'total': totalRegistered,
        'monthly': monthlyRegistered,
        'quarterly': quarterlyRegistered,
        'annual': annualRegistered,
      };

      print('All registered sales: $result');
      return result;
    } catch (e) {
      print('Error loading user all registered sales: $e');
      return _getDefaultAchievedSales();
    }
  }

  // Calculate progress percentage
  static double calculateProgress(double achieved, double target) {
    if (target == 0) return 0;
    return (achieved / target) * 100;
  }

  // Get current month's target from assigned targets
  static double getCurrentMonthTarget(
      Map<String, dynamic>? userAssignedTargets) {
    if (userAssignedTargets == null) return 0;

    final monthlyTargets = userAssignedTargets['monthly_targets'] as List;
    final currentMonth = DateTime.now().month;

    final currentMonthTarget = monthlyTargets.firstWhere(
      (target) => target['month'] == currentMonth,
      orElse: () => {'target_amount': 0},
    );

    return (currentMonthTarget['target_amount'] ?? 0).toDouble();
  }

  // Get current quarter's target from assigned targets
  static double getCurrentQuarterTarget(
      Map<String, dynamic>? userAssignedTargets) {
    if (userAssignedTargets == null) return 0;

    final assignedTarget = userAssignedTargets['assigned_target'];
    final currentQuarter = ((DateTime.now().month - 1) / 3).floor() + 1;

    switch (currentQuarter) {
      case 1:
        return (assignedTarget['assigned_amount_q1'] ?? 0).toDouble();
      case 2:
        return (assignedTarget['assigned_amount_q2'] ?? 0).toDouble();
      case 3:
        return (assignedTarget['assigned_amount_q3'] ?? 0).toDouble();
      case 4:
        return (assignedTarget['assigned_amount_q4'] ?? 0).toDouble();
      default:
        return 0;
    }
  }

  // Get annual target from assigned targets
  static double getAnnualTarget(Map<String, dynamic>? userAssignedTargets) {
    if (userAssignedTargets == null) return 0;

    final assignedTarget = userAssignedTargets['assigned_target'];
    return (assignedTarget['assigned_amount_annual'] ?? 0).toDouble();
  }

  // Calculate monthly sales analysis
  static Map<String, double> calculateMonthlySalesAnalysis(
      Map<String, dynamic>? userAssignedTargets) {
    final monthlyTarget = getCurrentMonthTarget(userAssignedTargets);
    final monthlyAchieved =
        monthlyTarget * 0.88; // Demo value - replace with actual achieved
    final remainingSales = monthlyTarget - monthlyAchieved;

    return {
      'target': monthlyTarget,
      'achieved': monthlyAchieved,
      'remaining': remainingSales,
    };
  }

  // Create and assign targets (Admin functionality)
  static Future<bool> createAndAssignTargets({
    required int year,
    required double revenueTarget,
    required Map<String, double> memberAssignments,
  }) async {
    try {
      // Calculate monthly and quarterly targets
      final calculatedTargets = _calculateTargetBreakdown(revenueTarget);

      // Create main target
      final target = TargetModel(
        amount: revenueTarget,
        annualAmount: calculatedTargets['annual'],
        monthlyAmount: calculatedTargets['monthly'],
        quarterAmount: calculatedTargets['quarterly'],
        year: DateTime(year),
      );

      // Insert target and get target ID
      final targetId = await SupabaseService.insertTarget(target);

      // Get sales team members
      final members = await SupabaseService.getSalesTeamMembers();

      // Validate total assigned amount
      double totalAssigned = 0;
      for (final member in members) {
        final memberId = member['user_id'];
        totalAssigned += memberAssignments[memberId] ?? 0;
      }

      if (totalAssigned > revenueTarget) {
        throw Exception(
            'Total assigned amount ($totalAssigned) cannot exceed target revenue ($revenueTarget)');
      }

      // Assign targets to each member
      for (final member in members) {
        final memberId = member['user_id'];
        final assignedAmount = memberAssignments[memberId] ?? 0;

        if (assignedAmount > 0) {
          // Calculate quarterly breakdown for this member
          final memberQuarterlyAmount = assignedAmount / 4;

          // Create assigned target for this member
          final assignedTarget = AssignedTargetModel(
            annualTargetId: targetId,
            userId: memberId,
            assignedAmountAnnual: assignedAmount,
            assignedAmountQ1: memberQuarterlyAmount,
            assignedAmountQ2: memberQuarterlyAmount,
            assignedAmountQ3: memberQuarterlyAmount,
            assignedAmountQ4: memberQuarterlyAmount,
            createdAt: DateTime.now(),
          );

          // Insert assigned target
          final assignedTargetId =
              await SupabaseService.insertAssignedTarget(assignedTarget);

          // Create monthly targets for this member
          final monthlyAmount = assignedAmount / 12;
          for (int month = 1; month <= 12; month++) {
            final monthlyTarget = AssignedMonthlyTargetModel(
              assignedTargetId: assignedTargetId,
              month: month,
              targetAmount: monthlyAmount,
            );

            await SupabaseService.insertAssignedMonthlyTarget(monthlyTarget);
          }
        }
      }

      return true;
    } catch (e) {
      print('Error creating and assigning targets: $e');
      return false;
    }
  }

  // Calculate target breakdown (annual, monthly, quarterly)
  static Map<String, double> _calculateTargetBreakdown(double revenueTarget) {
    return {
      'annual': revenueTarget,
      'monthly': revenueTarget / 12,
      'quarterly': revenueTarget / 4,
    };
  }

  // Get default achieved sales (when no data available)
  static Map<String, double> _getDefaultAchievedSales() {
    return {
      'total': 0,
      'monthly': 0,
      'quarterly': 0,
      'annual': 0,
    };
  }

  // Get sales team members for admin
  static Future<List<Map<String, dynamic>>> getSalesTeamMembers() async {
    try {
      return await SupabaseService.getSalesTeamMembers();
    } catch (e) {
      print('Error fetching sales team members: $e');
      return [];
    }
  }

  // Validate target assignment
  static bool validateTargetAssignment(
      double totalAssigned, double targetRevenue) {
    return totalAssigned <= targetRevenue;
  }

  // Get target statistics for admin dashboard
  static Future<Map<String, dynamic>> getTargetStatistics() async {
    try {
      final targets = await SupabaseService.getAllTargets();
      final salesMembers = await getSalesTeamMembers();

      double totalTargetRevenue = 0;
      double totalAssignedRevenue = 0;

      for (final target in targets) {
        totalTargetRevenue += (target['amount'] ?? 0).toDouble();
      }

      // Calculate total assigned revenue (this would need to be calculated from assigned_targets table)
      // For now, returning basic statistics

      return {
        'totalTargetRevenue': totalTargetRevenue,
        'totalAssignedRevenue': totalAssignedRevenue,
        'salesMembersCount': salesMembers.length,
        'targetsCount': targets.length,
      };
    } catch (e) {
      print('Error getting target statistics: $e');
      return {
        'totalTargetRevenue': 0,
        'totalAssignedRevenue': 0,
        'salesMembersCount': 0,
        'targetsCount': 0,
      };
    }
  }
}
