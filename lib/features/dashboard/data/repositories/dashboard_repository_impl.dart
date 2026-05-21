import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../transactions/data/datasources/transaction_local_datasource.dart';
import '../../../transactions/domain/entities/transaction.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this.localDataSource);

  final TransactionLocalDataSource localDataSource;

  static const double budgetLimit = 3000;

  @override
  Future<Either<Failure, DashboardSummary>> getSummary() async {
    try {
      final models = await localDataSource.getAll();
      final txs = models.map((m) => m.toEntity()).toList();

      double income = 0;
      double expense = 0;
      final now = DateTime.now();
      final daily = List<double>.filled(7, 0);

      for (final t in txs) {
        if (t.type == TransactionType.income) {
          income += t.amount;
        } else {
          expense += t.amount;
          final diff = now.difference(t.date).inDays;
          if (diff >= 0 && diff < 7) {
            daily[6 - diff] += t.amount;
          }
        }
      }

      return Right(
        DashboardSummary(
          balance: income - expense,
          totalIncome: income,
          totalExpense: expense,
          budgetLimit: budgetLimit,
          dailySpending: daily,
        ),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
