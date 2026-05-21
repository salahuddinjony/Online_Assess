import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/usecases/get_dashboard_summary.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required GetDashboardSummary getSummary,
    required TransactionListCoordinator coordinator,
  })  : _getSummary = getSummary,
        _coordinator = coordinator,
        super(const DashboardState()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardRefreshRequested>(_onRefresh);
    _subscription = _coordinator.stream.listen(_onTransactionsChanged);
  }

  final GetDashboardSummary _getSummary;
  final TransactionListCoordinator _coordinator;
  late final StreamSubscription<List<Transaction>> _subscription;

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    await _loadSummary(emit);
  }

  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _loadSummary(emit);
  }

  void _onTransactionsChanged(List<Transaction> _) {
    add(const DashboardRefreshRequested());
  }

  Future<void> _loadSummary(Emitter<DashboardState> emit) async {
    emit(state.copyWith(status: DashboardStatus.loading));
    final result = await _getSummary(const NoParams());
    result.fold(
      (f) => emit(
        state.copyWith(
          status: DashboardStatus.failure,
          errorMessage: f.message,
        ),
      ),
      (summary) => emit(
        state.copyWith(
          status: DashboardStatus.success,
          summary: summary,
          clearError: true,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
