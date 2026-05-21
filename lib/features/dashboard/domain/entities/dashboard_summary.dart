import 'package:equatable/equatable.dart';

class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.budgetLimit,
    required this.dailySpending,
  });

  final double balance;
  final double totalIncome;
  final double totalExpense;
  final double budgetLimit;
  final List<double> dailySpending;

  double get budgetUsedRatio =>
      budgetLimit <= 0 ? 0 : (totalExpense / budgetLimit).clamp(0.0, 1.0);

  @override
  List<Object?> get props =>
      [balance, totalIncome, totalExpense, budgetLimit, dailySpending];
}
