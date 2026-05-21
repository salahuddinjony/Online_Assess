import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getAll();
  Future<void> saveAll(List<TransactionModel> items);
  Future<void> upsert(TransactionModel item);
  Future<void> remove(String id);
  Future<List<TransactionModel>> getPendingQueue();
  Stream<List<TransactionModel>> watchAll();
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  TransactionLocalDataSourceImpl();

  static const _boxName = 'transactions_box';
  static const _queueKey = '__pending_queue__';

  Box<Map>? _box;

  Future<Box<Map>> get box async {
    _box ??= await Hive.openBox<Map>(_boxName);
    return _box!;
  }

  List<TransactionModel> _parseTransactionMaps(Iterable<Map> maps) {
    return maps
        .map((m) => TransactionModel.fromJson(Map<String, dynamic>.from(m)))
        .where((t) => !t.pendingDelete)
        .toList()
      ..sort((a, b) => b.dateMs.compareTo(a.dateMs));
  }

  @override
  Future<List<TransactionModel>> getAll() async {
    try {
      final b = await box;
      final maps = b.keys
          .where((key) => key != _queueKey)
          .map((key) => b.get(key))
          .whereType<Map>();
      return _parseTransactionMaps(maps);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Stream<List<TransactionModel>> watchAll() async* {
    final b = await box;
    yield await getAll();
    await for (final _ in b.watch()) {
      yield await getAll();
    }
  }

  @override
  Future<void> saveAll(List<TransactionModel> items) async {
    final b = await box;
    final keys = b.keys.where((k) => k != _queueKey).toList();
    await b.deleteAll(keys);
    for (final item in items) {
      await b.put(item.id, item.toJson());
    }
  }

  @override
  Future<void> upsert(TransactionModel item) async {
    final b = await box;
    await b.put(item.id, item.toJson());
  }

  @override
  Future<void> remove(String id) async {
    final b = await box;
    await b.delete(id);
  }

  @override
  Future<List<TransactionModel>> getPendingQueue() async {
    try {
      final b = await box;
      final raw = b.get(_queueKey);
      if (raw == null) return [];
      final list = raw['items'] as List<dynamic>? ?? [];
      return list
          .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  Future<void> setPendingQueue(List<TransactionModel> queue) async {
    final b = await box;
    await b.put(_queueKey, {
      'items': queue.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> enqueue(TransactionModel item) async {
    final queue = await getPendingQueue();
    queue.removeWhere((q) => q.id == item.id);
    queue.add(item);
    await setPendingQueue(queue);
  }

  Future<void> dequeue(String id) async {
    final queue = await getPendingQueue();
    queue.removeWhere((q) => q.id == id);
    await setPendingQueue(queue);
  }
}
