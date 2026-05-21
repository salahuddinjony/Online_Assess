import 'package:flutter_test/flutter_test.dart';
import 'package:online_assess/features/transactions/data/models/transaction_model.dart';
import 'package:online_assess/features/transactions/data/sync/sync_diff.dart';
import 'package:online_assess/features/transactions/domain/entities/transaction.dart';

void main() {
  test('computeSyncDiff merges remote and keeps unsynced local rows', () {
    final local = [
      TransactionModel(
        id: '1',
        title: 'Local only',
        amount: 10,
        category: 'Food',
        dateMs: 1,
        typeName: TransactionType.expense.name,
        synced: false,
      ),
      TransactionModel(
        id: '2',
        title: 'Synced',
        amount: 20,
        category: 'Food',
        dateMs: 2,
        typeName: TransactionType.expense.name,
        synced: true,
      ),
    ];
    final remote = [
      TransactionModel(
        id: '3',
        title: 'Remote',
        amount: 30,
        category: 'Food',
        dateMs: 3,
        typeName: TransactionType.expense.name,
        synced: true,
      ),
    ];

    final result = computeSyncDiff(
      SyncDiffPayload(
        localJson: encodeTransactions(local),
        remoteJson: encodeTransactions(remote),
      ),
    );

    final ids = result.map((m) => m['id'] as String).toSet();
    expect(ids, containsAll(['1', '3']));
  });
}
