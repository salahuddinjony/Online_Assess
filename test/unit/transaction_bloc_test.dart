import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:online_assess/core/error/failures.dart';
import 'package:online_assess/core/usecases/usecase.dart';
import 'package:online_assess/features/transactions/domain/entities/transaction.dart';
import 'package:online_assess/features/transactions/domain/usecases/add_transaction.dart';
import 'package:online_assess/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:online_assess/features/transactions/domain/usecases/get_transactions.dart';
import 'package:online_assess/features/transactions/domain/usecases/sync_transactions.dart';
import 'package:online_assess/core/widgets/celebration_effect.dart';
import 'package:online_assess/features/transactions/presentation/bloc/transaction_bloc.dart';

class MockGetTransactions extends Mock implements GetTransactions {}

class MockAddTransaction extends Mock implements AddTransaction {}

class MockDeleteTransaction extends Mock implements DeleteTransaction {}

class MockSyncTransactions extends Mock implements SyncTransactions {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(AddTransactionParams(
      Transaction(
        id: 'f',
        title: 'f',
        amount: 1,
        category: 'Food',
        date: DateTime(2024),
        type: TransactionType.expense,
      ),
    ));
  });

  late TransactionBloc bloc;
  late MockGetTransactions getTransactions;
  late MockAddTransaction addTransaction;
  late MockDeleteTransaction deleteTransaction;
  late MockSyncTransactions syncTransactions;
  late TransactionListCoordinator coordinator;

  final sample = Transaction(
    id: '1',
    title: 'Test',
    amount: 12,
    category: 'Food',
    date: DateTime(2024, 5, 1),
    type: TransactionType.expense,
  );

  setUp(() {
    getTransactions = MockGetTransactions();
    addTransaction = MockAddTransaction();
    deleteTransaction = MockDeleteTransaction();
    syncTransactions = MockSyncTransactions();
    coordinator = TransactionListCoordinator();
    bloc = TransactionBloc(
      getTransactions: getTransactions,
      addTransaction: addTransaction,
      deleteTransaction: deleteTransaction,
      syncTransactions: syncTransactions,
      coordinator: coordinator,
    );
  });

  tearDown(() {
    bloc.close();
    coordinator.dispose();
  });

  blocTest<TransactionBloc, TransactionState>(
    'rolls back optimistic add on server failure',
    build: () {
      when(() => getTransactions(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => addTransaction(any())).thenAnswer(
        (_) async => const Left(ServerFailure('Push failed')),
      );
      return bloc;
    },
    seed: () => const TransactionState(
      status: TransactionStatus.success,
      transactions: [],
    ),
    act: (b) => b.add(TransactionAdded(sample)),
    expect: () => [
      TransactionState(
        status: TransactionStatus.success,
        transactions: [sample],
        celebration: CelebrationEffect.expenseConfetti,
      ),
      TransactionState(
        status: TransactionStatus.failure,
        transactions: [],
        errorMessage: 'Push failed',
        celebration: CelebrationEffect.none,
      ),
    ],
  );
}
