import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/transaction.dart' show Transaction, TransactionType;
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_datasource.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';
import '../sync/sync_diff.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final TransactionLocalDataSource localDataSource;
  final TransactionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  final _controller = StreamController<List<Transaction>>.broadcast();

  TransactionLocalDataSourceImpl get _local =>
      localDataSource as TransactionLocalDataSourceImpl;

  void _notify() async {
    final list = await localDataSource.getAll();
    _controller.add(list.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<List<Transaction>> watchTransactions() {
    _local.watchAll().listen((models) {
      _controller.add(models.map((m) => m.toEntity()).toList());
    });
    return _controller.stream;
  }

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions() async {
    try {
      final local = await localDataSource.getAll();
      final entities = local.map((m) => m.toEntity()).toList();
      unawaited(_backgroundSync());
      return Right(entities);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  Future<void> _backgroundSync() async {
    if (!await networkInfo.isConnected) return;
    await syncPending();
  }

  @override
  Future<Either<Failure, Transaction>> addTransaction(
    Transaction transaction,
  ) async {
    try {
      final model = TransactionModel.fromEntity(
        transaction.copyWith(synced: false),
      );
      await localDataSource.upsert(model);
      await _local.enqueue(model);
      _notify();

      if (await networkInfo.isConnected) {
        final result = await _flushOne(model);
        return result;
      }
      return Right(transaction.copyWith(synced: false));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  Future<Either<Failure, Transaction>> _flushOne(
    TransactionModel model,
  ) async {
    try {
      final remote = await remoteDataSource.push(model);
      await localDataSource.upsert(remote);
      await _local.dequeue(model.id);
      _notify();
      return Right(remote.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await localDataSource.remove(id);
      _notify();

      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.removeRemote(id);
        } on ServerException catch (e) {
          return Left(ServerFailure(e.message));
        }
      } else {
        await _local.enqueue(
          TransactionModel(
            id: id,
            title: '',
            amount: 0,
            category: '',
            dateMs: 0,
            typeName: TransactionType.expense.name,
            synced: false,
            pendingDelete: true,
          ),
        );
      }
      await _local.dequeue(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> syncPending() async {
    if (!await networkInfo.isConnected) {
      return const Left(SyncFailure('Offline'));
    }
    try {
      final local = await localDataSource.getAll();
      final remote = await remoteDataSource.fetchAll();

      final mergedMaps = await compute(
        computeSyncDiff,
        SyncDiffPayload(
          localJson: encodeTransactions(local),
          remoteJson: encodeTransactions(remote),
        ),
      );

      final merged =
          mergedMaps.map((m) => TransactionModel.fromJson(m)).toList();
      await localDataSource.saveAll(merged);

      final queue = await _local.getPendingQueue();
      for (final item in queue) {
        if (item.pendingDelete) {
          await remoteDataSource.removeRemote(item.id);
          await _local.dequeue(item.id);
        } else {
          final pushed = await remoteDataSource.push(item);
          await localDataSource.upsert(pushed);
          await _local.dequeue(item.id);
        }
      }

      _notify();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
