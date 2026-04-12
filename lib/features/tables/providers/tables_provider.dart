// lib/features/tables/providers/tables_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/entry_repository.dart';
import '../../../data/models/encrypted_entry.dart';
import '../../../data/models/table_meta.dart';

// ─── Tables State ─────────────────────────────────

class TablesState {
  final List<TableMeta> tables;
  final bool isLoading;
  final String? error;

  const TablesState({
    this.tables = const [],
    this.isLoading = false,
    this.error,
  });

  TablesState copyWith({
    List<TableMeta>? tables,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TablesState(
      tables: tables ?? this.tables,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TablesNotifier extends StateNotifier<TablesState> {
  final EntryRepository _repo;

  TablesNotifier(this._repo) : super(const TablesState()) {
    loadTables();
  }

  Future<void> loadTables() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tables = await _repo.getAllTables();
      state = state.copyWith(tables: tables, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load tables: $e',
      );
    }
  }

  Future<bool> createTable(String name) async {
    try {
      final success = await _repo.createTable(name);
      if (success) {
        await loadTables();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create table: $e');
      return false;
    }
  }

  Future<bool> renameTable(String oldName, String newName) async {
    try {
      final success = await _repo.renameTable(oldName, newName);
      if (!success) return false;

      await loadTables();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to rename table: $e');
      return false;
    }
  }

  Future<void> deleteTable(String name) async {
    try {
      await _repo.deleteTable(name);
      await loadTables();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete table: $e');
    }
  }
}

// ─── Table Detail State ───────────────────────────

class TableDetailState {
  final String tableName;
  final List<EncryptedEntry> entries;
  final bool isLoading;
  final String? error;

  const TableDetailState({
    required this.tableName,
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  TableDetailState copyWith({
    String? tableName,
    List<EncryptedEntry>? entries,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TableDetailState(
      tableName: tableName ?? this.tableName,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TableDetailNotifier extends StateNotifier<TableDetailState> {
  final EntryRepository _repo;

  TableDetailNotifier(this._repo, String tableName)
      : super(TableDetailState(tableName: tableName)) {
    loadEntries();
  }

  Future<void> loadEntries() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entries = await _repo.getEntriesByTable(state.tableName);
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load entries: $e',
      );
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _repo.deleteEntry(id);
      await loadEntries();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete entry: $e');
    }
  }

  Future<void> updateNote(String id, String note) async {
    try {
      await _repo.updateEntryNote(id, note);
      await loadEntries();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update note: $e');
    }
  }

  Future<void> moveEntry(String entryId, String newTableName) async {
    try {
      await _repo.moveEntry(entryId, newTableName);
      await loadEntries();
    } catch (e) {
      state = state.copyWith(error: 'Failed to move entry: $e');
    }
  }
}

// ─── Providers ────────────────────────────────────

final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  return EntryRepository.instance;
});

final tablesProvider =
    StateNotifierProvider<TablesNotifier, TablesState>((ref) {
  final repo = ref.watch(entryRepositoryProvider);
  return TablesNotifier(repo);
});

final tableDetailProvider = StateNotifierProvider.family<
    TableDetailNotifier, TableDetailState, String>((ref, tableName) {
  final repo = ref.watch(entryRepositoryProvider);
  return TableDetailNotifier(repo, tableName);
});