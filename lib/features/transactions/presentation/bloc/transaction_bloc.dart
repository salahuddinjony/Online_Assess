import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/widgets/celebration_effect.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/sync_transactions.dart';

part 'transaction_event.dart';
part 'transaction_state.dart';

class TransactionListCoordinator {
  final _controller = StreamController<List<Transaction>>.broadcast();

  Stream<List<Transaction>> get stream => _controller.stream;

  void publish(List<Transaction> list) {
    if (!_controller.isClosed) {
      _controller.add(list);
    }
  }

  void dispose() => _controller.close();
}

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc({
    required GetTransactions getTransactions,
    required AddTransaction addTransaction,
    required DeleteTransaction deleteTransaction,
    required SyncTransactions syncTransactions,
    required TransactionListCoordinator coordinator,
  })  : _getTransactions = getTransactions,
        _addTransaction = addTransaction,
        _deleteTransaction = deleteTransaction,
        _syncTransactions = syncTransactions,
        _coordinator = coordinator,
        super(const TransactionState()) {
    on<TransactionsStarted>(_onStarted);
    on<TransactionAdded>(_onAdded);
    on<TransactionDeleted>(_onDeleted);
    on<TransactionSyncRequested>(_onSync);
    on<TransactionParticleDismissed>(_onParticleDismissed);
  }

  final GetTransactions _getTransactions;
  final AddTransaction _addTransaction;
  final DeleteTransaction _deleteTransaction;
  final SyncTransactions _syncTransactions;
  final TransactionListCoordinator _coordinator;

  List<Transaction>? _rollbackSnapshot;

  void _publish(List<Transaction> list) => _coordinator.publish(list);

  Future<void> _onStarted(
    TransactionsStarted event,
    Emitter<TransactionState> emit,
  ) async {
    emit(state.copyWith(status: TransactionStatus.loading, clearError: true));
    final result = await _getTransactions(const NoParams());
    result.fold(
      (f) => emit(
        state.copyWith(
          status: TransactionStatus.failure,
          errorMessage: f.message,
        ),
      ),
      (list) {
        emit(
          state.copyWith(
            status: TransactionStatus.success,
            transactions: list,
            clearError: true,
          ),
        );
        _publish(list);
      },
    );
  }

  Future<void> _onAdded(
    TransactionAdded event,
    Emitter<TransactionState> emit,
  ) async {
    _rollbackSnapshot = List<Transaction>.from(state.transactions);
    final optimistic = [event.transaction, ...state.transactions];
    final celebration = event.transaction.isExpense
        ? CelebrationEffect.expenseConfetti
        : CelebrationEffect.incomeCoins;
    emit(
      state.copyWith(
        transactions: optimistic,
        celebration: celebration,
        clearError: true,
      ),
    );
    _publish(optimistic);

    final result = await _addTransaction(
      AddTransactionParams(event.transaction),
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            transactions: _rollbackSnapshot!,
            status: TransactionStatus.failure,
            errorMessage: failure.message,
            celebration: CelebrationEffect.none,
          ),
        );
        _publish(_rollbackSnapshot!);
        _rollbackSnapshot = null;
      },
      (saved) {
        final updated = [
          saved,
          ...optimistic.where((t) => t.id != event.transaction.id),
        ];
        emit(
          state.copyWith(
            transactions: updated,
            status: TransactionStatus.success,
            clearError: true,
          ),
        );
        _publish(updated);
        _rollbackSnapshot = null;
      },
    );
  }

  Future<void> _onDeleted(
    TransactionDeleted event,
    Emitter<TransactionState> emit,
  ) async {
    _rollbackSnapshot = List<Transaction>.from(state.transactions);
    final optimistic =
        state.transactions.where((t) => t.id != event.id).toList();
    emit(state.copyWith(transactions: optimistic, clearError: true));
    _publish(optimistic);

    final result = await _deleteTransaction(
      DeleteTransactionParams(event.id),
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            transactions: _rollbackSnapshot!,
            errorMessage: failure.message,
            status: TransactionStatus.failure,
          ),
        );
        _publish(_rollbackSnapshot!);
        _rollbackSnapshot = null;
      },
      (_) {
        emit(
          state.copyWith(status: TransactionStatus.success, clearError: true),
        );
        _rollbackSnapshot = null;
      },
    );
  }

  Future<void> _onSync(
    TransactionSyncRequested event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await _syncTransactions(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {},
    );

    if (result.isLeft()) return;

    final refreshed = await _getTransactions(const NoParams());
    refreshed.fold(
      (_) {},
      (list) {
        emit(state.copyWith(transactions: list, clearError: true));
        _publish(list);
      },
    );
  }

  void _onParticleDismissed(
    TransactionParticleDismissed event,
    Emitter<TransactionState> emit,
  ) {
    emit(state.copyWith(celebration: CelebrationEffect.none));
  }
}
