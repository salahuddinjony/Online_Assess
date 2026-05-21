part of 'transaction_bloc.dart';

enum TransactionStatus { initial, loading, success, failure }

class TransactionState extends Equatable {
  const TransactionState({
    this.status = TransactionStatus.initial,
    this.transactions = const [],
    this.errorMessage,
    this.celebration = CelebrationEffect.none,
  });

  final TransactionStatus status;
  final List<Transaction> transactions;
  final String? errorMessage;
  final CelebrationEffect celebration;

  TransactionState copyWith({
    TransactionStatus? status,
    List<Transaction>? transactions,
    String? errorMessage,
    CelebrationEffect? celebration,
    bool clearError = false,
  }) {
    return TransactionState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      celebration: celebration ?? this.celebration,
    );
  }

  @override
  List<Object?> get props => [status, transactions, errorMessage, celebration];
}
