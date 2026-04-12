// lib/data/repositories/entry_repository.dart

import 'package:uuid/uuid.dart';
import '../database/local_database.dart';
import '../models/encrypted_entry.dart';
import '../models/table_meta.dart';
import '../../core/constants/app_constants.dart';

class EntryRepository {
  static EntryRepository? _instance;
  final LocalDatabase _db;
  final Uuid _uuid;

  EntryRepository._()
      : _db = LocalDatabase.instance,
        _uuid = const Uuid();

  static EntryRepository get instance {
    _instance ??= EntryRepository._();
    return _instance!;
  }

  // ═══════════════════════════════════════════════════
  // ENTRIES
  // ═══════════════════════════════════════════════════

  /// Save a new encrypted entry
  Future<EncryptedEntry> saveEntry({
    required String encryptedText,
    required String tableName,
    String note = '',
  }) async {
    // Ensure table exists
    final tableExists = await _db.tableExists(tableName);
    if (!tableExists) {
      await _db.createTable(tableName);
    }

    final now = DateTime.now();
    final entry = EncryptedEntry(
      id: _uuid.v4(),
      tableName: tableName,
      encryptedText: encryptedText,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    await _db.insertEntry(entry);
    return entry;
  }

  /// Get entries for a table
  Future<List<EncryptedEntry>> getEntriesByTable(String tableName) async {
    return await _db.getEntriesByTable(tableName);
  }

  /// Get all entries
  Future<List<EncryptedEntry>> getAllEntries() async {
    return await _db.getAllEntries();
  }

  /// Get single entry
  Future<EncryptedEntry?> getEntry(String id) async {
    return await _db.getEntryById(id);
  }

  /// Update entry note
  Future<void> updateEntryNote(String id, String note) async {
    final entry = await _db.getEntryById(id);
    if (entry == null) return;

    final updated = entry.copyWith(
      note: note,
      updatedAt: DateTime.now(),
    );
    await _db.updateEntry(updated);
  }

  /// Delete entry
  Future<void> deleteEntry(String id) async {
    await _db.deleteEntry(id);
  }

  /// Move entry to different table
  Future<void> moveEntry(String entryId, String newTableName) async {
    final tableExists = await _db.tableExists(newTableName);
    if (!tableExists) {
      await _db.createTable(newTableName);
    }
    await _db.moveEntry(entryId, newTableName);
  }

  /// Search entries
  Future<List<EncryptedEntry>> searchEntries(String query) async {
    return await _db.searchEntries(query);
  }

  // ═══════════════════════════════════════════════════
  // TABLES
  // ═══════════════════════════════════════════════════

  /// Get all tables
  Future<List<TableMeta>> getAllTables() async {
    return await _db.getAllTables();
  }

  /// Create a new table
  Future<bool> createTable(String tableName) async {
    final exists = await _db.tableExists(tableName);
    if (exists) return false;

    await _db.createTable(tableName);
    return true;
  }

  /// Rename table
  Future<bool> renameTable(String oldName, String newName) async {
    if (oldName == AppConstants.defaultTableName) return false;

    final exists = await _db.tableExists(newName);
    if (exists) return false;

    await _db.renameTable(oldName, newName);
    return true;
  }

  /// Delete table
  Future<void> deleteTable(String tableName) async {
    await _db.deleteTable(tableName);
  }

  /// Get single table
  Future<TableMeta?> getTable(String tableName) async {
    return await _db.getTable(tableName);
  }

  // ═══════════════════════════════════════════════════
  // RESET
  // ═══════════════════════════════════════════════════

  Future<void> resetAll() async {
    await _db.resetAll();
  }
}