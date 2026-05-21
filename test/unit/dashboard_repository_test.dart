import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:online_assess/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:online_assess/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:online_assess/features/transactions/data/models/transaction_model.dart';
import 'package:online_assess/features/transactions/domain/entities/transaction.dart';

class MockLocalDataSource extends Mock implements TransactionLocalDataSource {}

void main() {
  test('getSummary calculates balance from income and expenses', () async {
    final local = MockLocalDataSource();
    when(() => local.getAll()).thenAnswer(
      (_) async => [
        TransactionModel(
          id: '1',
          title: 'Pay',
          amount: 1000,
          category: 'Income',
          dateMs: DateTime.now().millisecondsSinceEpoch,
          typeName: TransactionType.income.name,
        ),
        TransactionModel(
          id: '2',
          title: 'Food',
          amount: 200,
          category: 'Food',
          dateMs: DateTime.now().millisecondsSinceEpoch,
          typeName: TransactionType.expense.name,
        ),
      ],
    );

    final repo = DashboardRepositoryImpl(local);
    final result = await repo.getSummary();

    result.fold(
      (_) => fail('expected success'),
      (summary) {
        expect(summary.balance, 800);
        expect(summary.totalIncome, 1000);
        expect(summary.totalExpense, 200);
      },
    );
  });
}
