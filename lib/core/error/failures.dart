import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Remote server error']);
}

class SyncFailure extends Failure {
  const SyncFailure([super.message = 'Sync failed']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
