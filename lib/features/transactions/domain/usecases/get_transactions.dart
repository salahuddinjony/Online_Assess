import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class GetTransactions implements UseCase<List<Transaction>, NoParams> {
  GetTransactions(this.repository);

  final TransactionRepository repository;

  @override
  Future<Either<Failure, List<Transaction>>> call(NoParams params) {
    return repository.getTransactions();
  }
}
