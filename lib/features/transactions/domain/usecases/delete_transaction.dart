import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/transaction_repository.dart';

class DeleteTransactionParams {
  const DeleteTransactionParams(this.id);
  final String id;
}

class DeleteTransaction implements UseCase<void, DeleteTransactionParams> {
  DeleteTransaction(this.repository);

  final TransactionRepository repository;

  @override
  Future<Either<Failure, void>> call(DeleteTransactionParams params) {
    return repository.deleteTransaction(params.id);
  }
}
