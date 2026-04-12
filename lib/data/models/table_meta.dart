// lib/data/models/table_meta.dart

class TableMeta {
  final String tableName;
  final int entryCount;
  final DateTime createdAt;

  TableMeta({
    required this.tableName,
    this.entryCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'table_name': tableName,
      'entry_count': entryCount,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory TableMeta.fromMap(Map<String, dynamic> map) {
    return TableMeta(
      tableName: map['table_name'] as String,
      entryCount: (map['entry_count'] as int?) ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  TableMeta copyWith({
    String? tableName,
    int? entryCount,
    DateTime? createdAt,
  }) {
    return TableMeta(
      tableName: tableName ?? this.tableName,
      entryCount: entryCount ?? this.entryCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}