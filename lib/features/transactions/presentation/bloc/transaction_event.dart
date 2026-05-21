part of 'transaction_bloc.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class TransactionsStarted extends TransactionEvent {
  const TransactionsStarted();
}

class TransactionAdded extends TransactionEvent {
  const TransactionAdded(this.transaction);
  final Transaction transaction;

  @override
  List<Object?> get props => [transaction];
}

class TransactionDeleted extends TransactionEvent {
  const TransactionDeleted(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

class TransactionSyncRequested extends TransactionEvent {
  const TransactionSyncRequested();
}

class TransactionParticleDismissed extends TransactionEvent {
  const TransactionParticleDismissed();
}
