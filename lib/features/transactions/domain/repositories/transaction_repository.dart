import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<Transaction>>> getTransactions();
  Future<Either<Failure, Transaction>> addTransaction(Transaction transaction);
  Future<Either<Failure, void>> deleteTransaction(String id);
  Future<Either<Failure, void>> syncPending();
  Stream<List<Transaction>> watchTransactions();
}
