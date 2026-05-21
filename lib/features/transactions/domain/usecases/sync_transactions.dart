import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/transaction_repository.dart';

class SyncTransactions implements UseCase<void, NoParams> {
  SyncTransactions(this.repository);

  final TransactionRepository repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.syncPending();
  }
}
