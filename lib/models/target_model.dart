class TargetModel {
  final String? id;
  final double amount;
  final double? annualAmount;
  final double? monthlyAmount;
  final double? quarterAmount;
  final DateTime year;

  TargetModel({
    this.id,
    required this.amount,
    this.annualAmount,
    this.monthlyAmount,
    this.quarterAmount,
    required this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'annual_amount': annualAmount,
      'monthly_amount': monthlyAmount,
      'Quater_amount': quarterAmount, // Note: keeping the typo as per DB schema
      'year': year.toIso8601String().split('T')[0], // Format as date only
    };
  }

  factory TargetModel.fromMap(Map<String, dynamic> map) {
    return TargetModel(
      id: map['id'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      annualAmount: (map['annual_amount'] ?? 0.0).toDouble(),
      monthlyAmount: (map['monthly_amount'] ?? 0.0).toDouble(),
      quarterAmount: (map['Quater_amount'] ?? 0.0).toDouble(),
      year: DateTime.parse(map['year']),
    );
  }
}

class AssignedTargetModel {
  final String? id;
  final String annualTargetId;
  final String userId;
  final double? assignedAmountAnnual;
  final double? assignedAmountQ1;
  final double? assignedAmountQ2;
  final double? assignedAmountQ3;
  final double? assignedAmountQ4;
  final DateTime? createdAt;

  AssignedTargetModel({
    this.id,
    required this.annualTargetId,
    required this.userId,
    this.assignedAmountAnnual,
    this.assignedAmountQ1,
    this.assignedAmountQ2,
    this.assignedAmountQ3,
    this.assignedAmountQ4,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'annual_target_id': annualTargetId,
      'user_id': userId,
      'assigned_amount_annual': assignedAmountAnnual,
      'assigned_amount_q1': assignedAmountQ1,
      'assigned_amount_q2': assignedAmountQ2,
      'assigned_amount_q3': assignedAmountQ3,
      'assigned_amount_q4': assignedAmountQ4,
      if (createdAt != null)
        'created_at': createdAt!.toIso8601String().split('T')[0],
    };
  }

  factory AssignedTargetModel.fromMap(Map<String, dynamic> map) {
    return AssignedTargetModel(
      id: map['id'],
      annualTargetId: map['annual_target_id'],
      userId: map['user_id'],
      assignedAmountAnnual: (map['assigned_amount_annual'] ?? 0.0).toDouble(),
      assignedAmountQ1: (map['assigned_amount_q1'] ?? 0.0).toDouble(),
      assignedAmountQ2: (map['assigned_amount_q2'] ?? 0.0).toDouble(),
      assignedAmountQ3: (map['assigned_amount_q3'] ?? 0.0).toDouble(),
      assignedAmountQ4: (map['assigned_amount_q4'] ?? 0.0).toDouble(),
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}

class AssignedMonthlyTargetModel {
  final String? id;
  final String assignedTargetId;
  final int? month;
  final double? targetAmount;

  AssignedMonthlyTargetModel({
    this.id,
    required this.assignedTargetId,
    this.month,
    this.targetAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'assigned_target_id': assignedTargetId,
      'month': month,
      'target_amount': targetAmount,
    };
  }

  factory AssignedMonthlyTargetModel.fromMap(Map<String, dynamic> map) {
    return AssignedMonthlyTargetModel(
      id: map['id'],
      assignedTargetId: map['assigned_target_id'],
      month: map['month'],
      targetAmount: (map['target_amount'] ?? 0.0).toDouble(),
    );
  }
}
