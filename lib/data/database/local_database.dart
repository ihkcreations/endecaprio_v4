// lib/data/database/local_database.dart

import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' as mobile_sqflite;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/constants/app_constants.dart';
import '../models/encrypted_entry.dart';
import '../models/table_meta.dart';

class LocalDatabase {
  static LocalDatabase? _instance;
  Database? _database;

  LocalDatabase._();

  static LocalDatabase get instance {
    _instance ??= LocalDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Directory appDir = await getApplicationSupportDirectory();
    final String dbPath = join(appDir.path, AppConstants.dbName);

    return await openDatabase(
      dbPath,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS entries (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        encrypted_text TEXT NOT NULL,
        note TEXT DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tables_meta (
        table_name TEXT PRIMARY KEY,
        entry_count INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create default table
    await db.insert('tables_meta', {
      'table_name': AppConstants.defaultTableName,
      'entry_count': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    // Create indexes for faster queries
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_entries_table ON entries(table_name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_entries_created ON entries(created_at DESC)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
  }

  // ═══════════════════════════════════════════════════
  // ENTRIES CRUD
  // ═══════════════════════════════════════════════════

  /// Insert a new encrypted entry
  Future<void> insertEntry(EncryptedEntry entry) async {
    final db = await database;
    await db.insert(
      'entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Update entry count
    await _updateEntryCount(entry.tableName);
  }

  /// Get all entries for a specific table
  Future<List<EncryptedEntry>> getEntriesByTable(String tableName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      where: 'table_name = ?',
      whereArgs: [tableName],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => EncryptedEntry.fromMap(map)).toList();
  }

  /// Get all entries across all tables
  Future<List<EncryptedEntry>> getAllEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => EncryptedEntry.fromMap(map)).toList();
  }

  /// Get a single entry by ID
  Future<EncryptedEntry?> getEntryById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return EncryptedEntry.fromMap(maps.first);
  }

  /// Update an entry
  Future<void> updateEntry(EncryptedEntry entry) async {
    final db = await database;
    await db.update(
      'entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Delete an entry
  Future<void> deleteEntry(String id) async {
    final db = await database;

    // Get the table name before deleting
    final entry = await getEntryById(id);

    await db.delete(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Update entry count
    if (entry != null) {
      await _updateEntryCount(entry.tableName);
    }
  }

  /// Delete all entries in a table
  Future<void> deleteEntriesByTable(String tableName) async {
    final db = await database;
    await db.delete(
      'entries',
      where: 'table_name = ?',
      whereArgs: [tableName],
    );
    await _updateEntryCount(tableName);
  }

  /// Move an entry to a different table
  Future<void> moveEntry(String entryId, String newTableName) async {
    final db = await database;
    final entry = await getEntryById(entryId);
    if (entry == null) return;

    final oldTableName = entry.tableName;

    await db.update(
      'entries',
      {
        'table_name': newTableName,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );

    await _updateEntryCount(oldTableName);
    await _updateEntryCount(newTableName);
  }

  /// Search entries by note
  Future<List<EncryptedEntry>> searchEntries(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      where: 'note LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => EncryptedEntry.fromMap(map)).toList();
  }

  /// Get entry count for a table
  Future<int> getEntryCount(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM entries WHERE table_name = ?',
      [tableName],
    );
    return result.first['count'] as int;
  }

  // ═══════════════════════════════════════════════════
  // TABLES CRUD
  // ═══════════════════════════════════════════════════

  /// Create a new table
  Future<void> createTable(String tableName) async {
    final db = await database;
    await db.insert(
      'tables_meta',
      {
        'table_name': tableName,
        'entry_count': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Get all tables
  Future<List<TableMeta>> getAllTables() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tables_meta',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => TableMeta.fromMap(map)).toList();
  }

  /// Get a single table by name
  Future<TableMeta?> getTable(String tableName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tables_meta',
      where: 'table_name = ?',
      whereArgs: [tableName],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TableMeta.fromMap(maps.first);
  }

  /// Rename a table
  Future<void> renameTable(String oldName, String newName) async {
    final db = await database;

    // Update table meta
    final table = await getTable(oldName);
    if (table == null) return;

    await db.insert('tables_meta', {
      'table_name': newName,
      'entry_count': table.entryCount,
      'created_at': table.createdAt.millisecondsSinceEpoch,
    });

    // Update all entries
    await db.update(
      'entries',
      {'table_name': newName},
      where: 'table_name = ?',
      whereArgs: [oldName],
    );

    // Delete old table meta
    await db.delete(
      'tables_meta',
      where: 'table_name = ?',
      whereArgs: [oldName],
    );
  }

  /// Delete a table and all its entries
  Future<void> deleteTable(String tableName) async {
    if (tableName == AppConstants.defaultTableName) {
      // Don't delete default table, just clear its entries
      await deleteEntriesByTable(tableName);
      return;
    }

    final db = await database;
    await db.delete(
      'entries',
      where: 'table_name = ?',
      whereArgs: [tableName],
    );
    await db.delete(
      'tables_meta',
      where: 'table_name = ?',
      whereArgs: [tableName],
    );
  }

  /// Check if a table name already exists
  Future<bool> tableExists(String tableName) async {
    final table = await getTable(tableName);
    return table != null;
  }

  // ═══════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════

  /// Update the entry count for a table
  Future<void> _updateEntryCount(String tableName) async {
    final db = await database;
    final count = await getEntryCount(tableName);
    await db.update(
      'tables_meta',
      {'entry_count': count},
      where: 'table_name = ?',
      whereArgs: [tableName],
    );
  }

  /// Delete everything - nuclear reset
  Future<void> resetAll() async {
    final db = await database;
    await db.delete('entries');
    await db.delete('tables_meta');

    // Recreate default table
    await db.insert('tables_meta', {
      'table_name': AppConstants.defaultTableName,
      'entry_count': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}