// lib/data/models/encrypted_entry.dart

class EncryptedEntry {
  final String id;
  final String tableName;
  final String encryptedText;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  EncryptedEntry({
    required this.id,
    required this.tableName,
    required this.encryptedText,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_name': tableName,
      'encrypted_text': encryptedText,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory EncryptedEntry.fromMap(Map<String, dynamic> map) {
    return EncryptedEntry(
      id: map['id'] as String,
      tableName: map['table_name'] as String,
      encryptedText: map['encrypted_text'] as String,
      note: (map['note'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  EncryptedEntry copyWith({
    String? id,
    String? tableName,
    String? encryptedText,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EncryptedEntry(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      encryptedText: encryptedText ?? this.encryptedText,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}