import 'dart:convert';

import '../models/transaction_model.dart';

/// Payload for isolate — plain maps only.
class SyncDiffPayload {
  const SyncDiffPayload({
    required this.localJson,
    required this.remoteJson,
  });

  final String localJson;
  final String remoteJson;
}

/// Runs in isolate: merges remote with local, preserving unsynced local rows.
List<Map<String, dynamic>> computeSyncDiff(SyncDiffPayload payload) {
  final localList = (jsonDecode(payload.localJson) as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final remoteList = (jsonDecode(payload.remoteJson) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  final local = localList.map(TransactionModel.fromJson).toList();
  final remote = remoteList.map(TransactionModel.fromJson).toList();

  final remoteById = {for (final r in remote) r.id: r};
  final merged = <TransactionModel>[];

  for (final r in remote) {
    merged.add(r);
  }

  for (final l in local) {
    if (!l.synced) {
      merged.add(l);
    } else if (!remoteById.containsKey(l.id)) {
      merged.add(l);
    }
  }

  final seen = <String>{};
  final unique = <TransactionModel>[];
  for (final m in merged) {
    if (seen.add(m.id)) unique.add(m);
  }

  unique.sort((a, b) => b.dateMs.compareTo(a.dateMs));
  return unique.map((e) => e.toJson()).toList();
}

String encodeTransactions(List<TransactionModel> list) {
  return jsonEncode(list.map((e) => e.toJson()).toList());
}
