import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:online_assess/core/error/failures.dart';
import 'package:online_assess/core/usecases/usecase.dart';
import 'package:online_assess/features/transactions/domain/entities/transaction.dart';
import 'package:online_assess/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:online_assess/features/transactions/domain/usecases/get_transactions.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late GetTransactions useCase;
  late MockTransactionRepository repository;

  setUp(() {
    repository = MockTransactionRepository();
    useCase = GetTransactions(repository);
  });

  test('returns transaction list from repository', () async {
    final txs = [
      Transaction(
        id: 'a',
        title: 'Coffee',
        amount: 3,
        category: 'Food',
        date: DateTime(2024),
        type: TransactionType.expense,
      ),
    ];
    when(() => repository.getTransactions()).thenAnswer((_) async => Right(txs));

    final result = await useCase(const NoParams());

    expect(result, Right(txs));
    verify(() => repository.getTransactions()).called(1);
  });

  test('forwards cache failure', () async {
    when(() => repository.getTransactions())
        .thenAnswer((_) async => const Left(CacheFailure('disk')));

    final result = await useCase(const NoParams());

    expect(result, const Left(CacheFailure('disk')));
  });
}
