import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardSummary implements UseCase<DashboardSummary, NoParams> {
  GetDashboardSummary(this.repository);

  final DashboardRepository repository;

  @override
  Future<Either<Failure, DashboardSummary>> call(NoParams params) {
    return repository.getSummary();
  }
}
