import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:online_assess/core/error/failures.dart';
import 'package:online_assess/features/transactions/domain/entities/transaction.dart';
import 'package:online_assess/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:online_assess/features/transactions/domain/usecases/add_transaction.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  test('AddTransaction delegates to repository', () async {
    final repo = MockTransactionRepository();
    final useCase = AddTransaction(repo);
    final tx = Transaction(
      id: 'x',
      title: 'Snack',
      amount: 4,
      category: 'Food',
      date: DateTime.now(),
      type: TransactionType.expense,
    );

    when(() => repo.addTransaction(tx)).thenAnswer((_) async => Right(tx));

    final result = await useCase(AddTransactionParams(tx));

    expect(result, Right(tx));
  });

  test('AddTransaction returns validation failure from repo', () async {
    final repo = MockTransactionRepository();
    final useCase = AddTransaction(repo);
    final tx = Transaction(
      id: 'x',
      title: 'Snack',
      amount: 4,
      category: 'Food',
      date: DateTime.now(),
      type: TransactionType.expense,
    );

    when(() => repo.addTransaction(tx)).thenAnswer(
      (_) async => const Left(ValidationFailure('Invalid amount')),
    );

    final result = await useCase(AddTransactionParams(tx));

    expect(result, const Left(ValidationFailure('Invalid amount')));
  });
}
