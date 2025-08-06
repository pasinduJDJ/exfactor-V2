import 'package:supabase_flutter/supabase_flutter.dart';

class TargetService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get company target for current year
  static Future<Map<String, dynamic>?> getCompanyTarget() async {
    try {
      final currentYear = DateTime.now().year;
      final targets = await _client
          .from('targets')
          .select()
          .eq('year', '$currentYear-01-01') // Format as date
          .single();

      return targets;
    } catch (e) {
      print('Error fetching company target: $e');
      return null;
    }
  }

  // Get total company revenue from all deals
  static Future<double> getTotalCompanyRevenue() async {
    try {
      final deals = await _client
          .from('deals')
          .select('deal_amount')
          .not('deal_amount', 'is', null);

      double totalRevenue = 0.0;
      for (var deal in deals) {
        if (deal['deal_amount'] != null) {
          totalRevenue += (deal['deal_amount'] as num).toDouble();
        }
      }

      return totalRevenue;
    } catch (e) {
      print('Error calculating total revenue: $e');
      return 0.0;
    }
  }

  // Calculate company progress percentage
  static Future<Map<String, dynamic>> calculateCompanyProgress() async {
    try {
      final target = await getCompanyTarget();
      final currentRevenue = await getTotalCompanyRevenue();

      if (target == null) {
        return {
          'hasTarget': false,
          'currentRevenue': currentRevenue,
          'targetAmount': 0.0,
          'progressPercentage': 0.0,
        };
      }

      final targetAmount = (target['annual_amount'] as num?)?.toDouble() ?? 0.0;
      final progressPercentage =
          targetAmount > 0 ? (currentRevenue / targetAmount) : 0.0;

      return {
        'hasTarget': true,
        'currentRevenue': currentRevenue,
        'targetAmount': targetAmount,
        'progressPercentage': progressPercentage,
      };
    } catch (e) {
      print('Error calculating company progress: $e');
      return {
        'hasTarget': false,
        'currentRevenue': 0.0,
        'targetAmount': 0.0,
        'progressPercentage': 0.0,
      };
    }
  }

  // Format currency for display
  static String formatCurrency(double amount) {
    return amount.toStringAsFixed(2);
  }
}
