import 'package:uuid/uuid.dart';

import '../models/transaction_model.dart';
import '../../domain/entities/transaction.dart';

List<TransactionModel> buildSeedTransactions() {
  const uuid = Uuid();
  final now = DateTime.now();

  TransactionModel mk({
    required String title,
    required double amount,
    required String category,
    required int daysAgo,
    required TransactionType type,
  }) {
    return TransactionModel(
      id: uuid.v4(),
      title: title,
      amount: amount,
      category: category,
      dateMs: now.subtract(Duration(days: daysAgo)).millisecondsSinceEpoch,
      typeName: type.name,
      synced: true,
    );
  }

  return [
    mk(title: 'Salary', amount: 4200, category: 'Income', daysAgo: 2, type: TransactionType.income),
    mk(title: 'Groceries', amount: 86.5, category: 'Food', daysAgo: 0, type: TransactionType.expense),
    mk(title: 'Coffee', amount: 5.5, category: 'Food', daysAgo: 0, type: TransactionType.expense),
    mk(title: 'Gym', amount: 45, category: 'Health', daysAgo: 1, type: TransactionType.expense),
    mk(title: 'Uber', amount: 18, category: 'Transport', daysAgo: 3, type: TransactionType.expense),
    mk(title: 'Netflix', amount: 15.99, category: 'Entertainment', daysAgo: 4, type: TransactionType.expense),
    mk(title: 'Freelance', amount: 600, category: 'Income', daysAgo: 5, type: TransactionType.income),
  ];
}
