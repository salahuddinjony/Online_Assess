import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class AddTransactionParams {
  const AddTransactionParams(this.transaction);
  final Transaction transaction;
}

class AddTransaction implements UseCase<Transaction, AddTransactionParams> {
  AddTransaction(this.repository);

  final TransactionRepository repository;

  @override
  Future<Either<Failure, Transaction>> call(AddTransactionParams params) {
    return repository.addTransaction(params.transaction);
  }
}
