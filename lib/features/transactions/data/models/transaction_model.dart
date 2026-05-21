import '../../domain/entities/transaction.dart';

class TransactionModel {
  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.dateMs,
    required this.typeName,
    this.synced = true,
    this.pendingDelete = false,
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final int dateMs;
  final String typeName;
  final bool synced;
  final bool pendingDelete;

  factory TransactionModel.fromEntity(Transaction t) {
    return TransactionModel(
      id: t.id,
      title: t.title,
      amount: t.amount,
      category: t.category,
      dateMs: t.date.millisecondsSinceEpoch,
      typeName: t.type.name,
      synced: t.synced,
      pendingDelete: t.pendingDelete,
    );
  }

  Transaction toEntity() {
    return Transaction(
      id: id,
      title: title,
      amount: amount,
      category: category,
      date: DateTime.fromMillisecondsSinceEpoch(dateMs),
      type: TransactionType.values.byName(typeName),
      synced: synced,
      pendingDelete: pendingDelete,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'dateMs': dateMs,
        'typeName': typeName,
        'synced': synced,
        'pendingDelete': pendingDelete,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: _readString(json, 'id'),
      title: _readString(json, 'title'),
      amount: _readDouble(json, 'amount'),
      category: _readString(json, 'category'),
      dateMs: _readInt(json, 'dateMs'),
      typeName: _readString(json, 'typeName', fallback: TransactionType.expense.name),
      synced: json['synced'] as bool? ?? true,
      pendingDelete: json['pendingDelete'] as bool? ?? false,
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    String key, {
    String fallback = '',
  }) {
    final value = json[key];
    if (value == null) return fallback;
    return value.toString();
  }

  static double _readDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
