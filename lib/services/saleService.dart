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

  // Get current user's achieved sales (negotiation + won deals only)
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

      // Get achieved sales for current user (negotiation + won deals only)
      final achievedSales =
          await SupabaseService.calculateUserAchievedSales(currentUserId);

      return achievedSales;
    } catch (e) {
      return _getDefaultAchievedSales();
    }
  }

  // Get current user's pipeline deals (all deals except lost)
  static Future<Map<String, double>> getCurrentUserPipelineDeals() async {
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

      double totalPipeline = 0;
      double monthlyPipeline = 0;
      double quarterlyPipeline = 0;
      double annualPipeline = 0;

      final now = DateTime.now();
      final currentMonth = now.month;
      final currentQuarter = ((currentMonth - 1) / 3).floor() + 1;
      final currentYear = now.year;

      for (final deal in deals) {
        final dealAmount = (deal['deal_amount'] ?? 0).toDouble();
        final dealDate = deal['created_at'] != null
            ? DateTime.parse(deal['created_at'])
            : now;
        final dealStatus = (deal['deal_status'] ?? '').toString().toLowerCase();

        // Count all deals EXCEPT lost deals (pipeline deals)
        if (dealStatus != 'won' || dealStatus != 'lost') {
          totalPipeline += dealAmount;

          // Check if deal is from current year
          if (dealDate.year == currentYear) {
            annualPipeline += dealAmount;

            // Check if deal is from current quarter
            final dealQuarter = ((dealDate.month - 1) / 3).floor() + 1;
            if (dealQuarter == currentQuarter) {
              quarterlyPipeline += dealAmount;
            }

            // Check if deal is from current month
            if (dealDate.month == currentMonth) {
              monthlyPipeline += dealAmount;
            }
          }
        }
      }

      final result = {
        'total': totalPipeline,
        'monthly': monthlyPipeline,
        'quarterly': quarterlyPipeline,
        'annual': annualPipeline,
      };

      print('Pipeline deals (all except lost): $result');
      return result;
    } catch (e) {
      print('Error loading user pipeline deals: $e');
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

    // Monthly targets can sometimes come with 'month' as String or int.
    final monthlyTargets =
        (userAssignedTargets['monthly_targets'] as List?) ?? const [];
    final currentMonth = DateTime.now().month;

    Map<String, dynamic>? match;
    for (final t in monthlyTargets) {
      final raw = t['month'];
      final monthAsInt = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
      if (monthAsInt == currentMonth) {
        match = Map<String, dynamic>.from(t);
        break;
      }
    }

    final fromMonthly =
        (match != null ? (match['target_amount'] ?? 0) : 0).toDouble();
    if (fromMonthly > 0) return fromMonthly;

    // Fallback 1: derive from quarterly assignment for current quarter
    final assignedTarget = userAssignedTargets['assigned_target'] ?? {};
    final q = ((DateTime.now().month - 1) / 3).floor() + 1;
    double fromQuarter = 0;
    switch (q) {
      case 1:
        fromQuarter =
            (assignedTarget['assigned_amount_q1'] ?? 0).toDouble() / 3;
        break;
      case 2:
        fromQuarter =
            (assignedTarget['assigned_amount_q2'] ?? 0).toDouble() / 3;
        break;
      case 3:
        fromQuarter =
            (assignedTarget['assigned_amount_q3'] ?? 0).toDouble() / 3;
        break;
      case 4:
        fromQuarter =
            (assignedTarget['assigned_amount_q4'] ?? 0).toDouble() / 3;
        break;
      default:
        fromQuarter = 0;
    }
    if (fromQuarter > 0) return fromQuarter;

    // Fallback 2: derive from annual assignment
    final fromAnnual =
        (assignedTarget['assigned_amount_annual'] ?? 0).toDouble() / 12;
    return fromAnnual;
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

  // ===== ADMIN COMPANY-WIDE SALES TRACKING METHODS =====

  // Get company targets for current year
  static Future<Map<String, double>> getCompanyTargets() async {
    try {
      final currentYear = DateTime.now().year;
      final targets = await SupabaseService.getAllTargets();

      // Find target for current year
      Map<String, dynamic>? currentYearTarget;
      for (final target in targets) {
        final targetYear = DateTime.parse(target['year']).year;
        if (targetYear == currentYear) {
          currentYearTarget = target;
          break;
        }
      }

      if (currentYearTarget == null) {
        print('No target found for current year: $currentYear');
        return _getDefaultCompanyTargets();
      }

      final annualTarget = (currentYearTarget['amount'] ?? 0).toDouble();
      final quarterlyTarget = annualTarget / 4;
      final monthlyTarget = annualTarget / 12;

      return {
        'annual': annualTarget,
        'quarterly': quarterlyTarget,
        'monthly': monthlyTarget,
      };
    } catch (e) {
      print('Error getting company targets: $e');
      return _getDefaultCompanyTargets();
    }
  }

  // Get company achieved sales (all deals from all users)
  static Future<Map<String, double>> getCompanyAchievedSales() async {
    try {
      final currentYear = DateTime.now().year;
      final currentMonth = DateTime.now().month;
      final currentQuarter = ((currentMonth - 1) / 3).floor() + 1;

      // Get all deals from database
      final allDeals = await SupabaseService.getAllDeals();

      double annualAchieved = 0;
      double quarterlyAchieved = 0;
      double monthlyAchieved = 0;

      for (final deal in allDeals) {
        final dealAmount = (deal['deal_amount'] ?? 0).toDouble();
        final dealDate = deal['created_at'] != null
            ? DateTime.parse(deal['created_at'])
            : DateTime.now();

        // Check if deal is from current year
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

      return {
        'annual': annualAchieved,
        'quarterly': quarterlyAchieved,
        'monthly': monthlyAchieved,
      };
    } catch (e) {
      print('Error getting company achieved sales: $e');
      return _getDefaultCompanyAchievedSales();
    }
  }

  // Get company sales progress (targets vs achieved)
  static Future<Map<String, dynamic>> getCompanySalesProgress() async {
    try {
      final targets = await getCompanyTargets();
      final achieved = await getCompanyAchievedSales();

      final annualProgress =
          calculateProgress(achieved['annual'] ?? 0, targets['annual'] ?? 0);
      final quarterlyProgress = calculateProgress(
          achieved['quarterly'] ?? 0, targets['quarterly'] ?? 0);
      final monthlyProgress =
          calculateProgress(achieved['monthly'] ?? 0, targets['monthly'] ?? 0);

      return {
        'targets': targets,
        'achieved': achieved,
        'progress': {
          'annual': annualProgress,
          'quarterly': quarterlyProgress,
          'monthly': monthlyProgress,
        },
      };
    } catch (e) {
      print('Error getting company sales progress: $e');
      return {
        'targets': _getDefaultCompanyTargets(),
        'achieved': _getDefaultCompanyAchievedSales(),
        'progress': {
          'annual': 0.0,
          'quarterly': 0.0,
          'monthly': 0.0,
        },
      };
    }
  }

  // Get default company targets (when no data available)
  static Map<String, double> _getDefaultCompanyTargets() {
    return {
      'annual': 0,
      'quarterly': 0,
      'monthly': 0,
    };
  }

  // Get default company achieved sales (when no data available)
  static Map<String, double> _getDefaultCompanyAchievedSales() {
    return {
      'annual': 0,
      'quarterly': 0,
      'monthly': 0,
    };
  }

  // ===== MEMBER-SPECIFIC SALES TRACKING METHODS =====

  // Get specific member's assigned targets
  static Future<Map<String, dynamic>?> getMemberAssignedTargets(
      String memberId) async {
    try {
      // Get member's UUID - handle memberId as string properly
      int memberIdInt;
      try {
        memberIdInt = int.parse(memberId);
      } catch (e) {
        print('Invalid member ID format: $memberId');
        return null;
      }

      final userData = await SupabaseService.getUserByMemberId(memberIdInt);
      if (userData == null) {
        print('No user data found for member ID: $memberId');
        return null;
      }

      final userId = userData['user_id'];
      print('Member UUID: $userId');

      // Get assigned targets for this member
      final assignedTargets =
          await SupabaseService.getCurrentUserAssignedTargets(userId);
      print('Member assigned targets: $assignedTargets');

      return assignedTargets;
    } catch (e) {
      print('Error loading member assigned targets: $e');
      return null;
    }
  }

  // Get specific member's achieved sales (negotiation + won deals only)
  static Future<Map<String, double>> getMemberAchievedSales(
      String memberId) async {
    try {
      // Get member's UUID - handle memberId as string properly
      int memberIdInt;
      try {
        memberIdInt = int.parse(memberId);
      } catch (e) {
        print('Invalid member ID format: $memberId');
        return _getDefaultAchievedSales();
      }

      final userData = await SupabaseService.getUserByMemberId(memberIdInt);
      if (userData == null) {
        print('No user data found for member ID: $memberId');
        return _getDefaultAchievedSales();
      }

      final userId = userData['user_id'];
      print('Member UUID: $userId');

      // Get all deals for this member
      final deals = await SupabaseService.getDealsByUserId(userId);
      print('All deals for member: ${deals.length}');

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
        final dealDate = deal['created_at'] != null
            ? DateTime.parse(deal['created_at'])
            : now;

        // Only count deals with status 'negotiation' or 'won'
        if (dealStatus == 'won') {
          totalAchieved += dealAmount;

          // Check if deal is from current year
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

      final result = {
        'total': totalAchieved,
        'monthly': monthlyAchieved,
        'quarterly': quarterlyAchieved,
        'annual': annualAchieved,
      };

      print('Member achieved sales (negotiation + won): $result');
      return result;
    } catch (e) {
      print('Error loading member achieved sales: $e');
      return _getDefaultAchievedSales();
    }
  }

  // Get specific member's CurrentPipeline sales (without won and lost)
  static Future<Map<String, double>> currentPipelineSales(
      String memberId) async {
    try {
      int memberIdInt;
      try {
        memberIdInt = int.parse(memberId);
      } catch (e) {
        print('Invalid member ID format: $memberId');
        return _getDefaultAchievedSales();
      }

      final userData = await SupabaseService.getUserByMemberId(memberIdInt);
      if (userData == null) {
        print('No user data found for member ID: $memberId');
        return _getDefaultAchievedSales();
      }

      final userId = userData['user_id'];
      print('Member UUID: $userId');

      final deals = await SupabaseService.getDealsByUserId(userId);
      print('All deals for member: ${deals.length}');

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
        final dealDate = deal['created_at'] != null
            ? DateTime.parse(deal['created_at'])
            : now;

        // Only count deals with status 'negotiation' or 'won'
        if (dealStatus == 'interested' ||
            dealStatus == 'ready_for_demo' ||
            dealStatus == 'proposal' ||
            dealStatus == 'negotiation') {
          totalAchieved += dealAmount;

          // Check if deal is from current year
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

      final result = {
        'total': totalAchieved,
        'monthly': monthlyAchieved,
        'quarterly': quarterlyAchieved,
        'annual': annualAchieved,
      };

      print('Member achieved sales (negotiation + won): $result');
      return result;
    } catch (e) {
      print('Error loading member achieved sales: $e');
      return _getDefaultAchievedSales();
    }
  }

  // Get specific member's deals categorized by period
  static Future<Map<String, List<Map<String, dynamic>>>> getMemberDealsByPeriod(
      String memberId) async {
    try {
      // Get member's UUID
      final userData =
          await SupabaseService.getUserByMemberId(int.parse(memberId));
      if (userData == null) {
        print('No user data found for member ID: $memberId');
        return _getDefaultDealsByPeriod();
      }

      final userId = userData['user_id'];
      print('Member UUID: $userId');

      // Get all deals for this member
      final deals = await SupabaseService.getDealsByUserId(userId);
      print('All deals for member: ${deals.length}');

      // Categorize deals by period
      return _categorizeDealsByPeriod(deals);
    } catch (e) {
      print('Error loading member deals by period: $e');
      return _getDefaultDealsByPeriod();
    }
  }

  // Categorize deals by time period
  static Map<String, List<Map<String, dynamic>>> _categorizeDealsByPeriod(
    List<Map<String, dynamic>> deals,
  ) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final currentQuarter = ((currentMonth - 1) / 3).floor() + 1;

    List<Map<String, dynamic>> thisMonthDeals = [];
    List<Map<String, dynamic>> thisQuarterDeals = [];
    List<Map<String, dynamic>> thisYearDeals = [];

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
      }
    }

    return {
      'monthly': thisMonthDeals,
      'quarterly': thisQuarterDeals,
      'annual': thisYearDeals,
    };
  }

  // Get default deals by period (when no data available)
  static Map<String, List<Map<String, dynamic>>> _getDefaultDealsByPeriod() {
    return {
      'monthly': [],
      'quarterly': [],
      'annual': [],
    };
  }
}
