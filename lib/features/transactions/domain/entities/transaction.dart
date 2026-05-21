import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    this.synced = true,
    this.pendingDelete = false,
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final TransactionType type;
  final bool synced;
  final bool pendingDelete;

  bool get isExpense => type == TransactionType.expense;

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    TransactionType? type,
    bool? synced,
    bool? pendingDelete,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      type: type ?? this.type,
      synced: synced ?? this.synced,
      pendingDelete: pendingDelete ?? this.pendingDelete,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        category,
        date,
        type,
        synced,
        pendingDelete,
      ];
}
