import 'dart:async';

import '../../../../core/error/exceptions.dart';
import '../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> fetchAll();
  Future<TransactionModel> push(TransactionModel item);
  Future<void> removeRemote(String id);
}

/// Simulated REST backend with intentional latency.
class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final Map<String, TransactionModel> _store = {};
  bool simulateFailure = false;

  @override
  Future<List<TransactionModel>> fetchAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (simulateFailure) throw const ServerException('Network unavailable');
    return _store.values.toList();
  }

  @override
  Future<TransactionModel> push(TransactionModel item) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (simulateFailure) throw const ServerException('Push failed');
    final synced = item.copyWithSynced(true);
    _store[item.id] = synced;
    return synced;
  }

  @override
  Future<void> removeRemote(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (simulateFailure) throw const ServerException('Delete failed');
    _store.remove(id);
  }

  void seedIfEmpty(List<TransactionModel> seed) {
    if (_store.isEmpty) {
      for (final s in seed) {
        _store[s.id] = s.copyWithSynced(true);
      }
    }
  }
}

extension on TransactionModel {
  TransactionModel copyWithSynced(bool value) {
    return TransactionModel(
      id: id,
      title: title,
      amount: amount,
      category: category,
      dateMs: dateMs,
      typeName: typeName,
      synced: value,
      pendingDelete: pendingDelete,
    );
  }
}
