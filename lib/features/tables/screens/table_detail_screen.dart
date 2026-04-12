// lib/features/tables/screens/table_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/encrypted_entry.dart';
import '../providers/tables_provider.dart';
import '../widgets/decrypt_dialog.dart';

class TableDetailScreen extends ConsumerStatefulWidget {
  final String tableName;

  const TableDetailScreen({super.key, required this.tableName});

  @override
  ConsumerState<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends ConsumerState<TableDetailScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EncryptedEntry> _filterEntries(List<EncryptedEntry> entries) {
    if (_searchQuery.isEmpty) return entries;
    return entries
        .where((e) =>
            e.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            e.encryptedText.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableDetailProvider(widget.tableName));
    final filteredEntries = _filterEntries(state.entries);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search by note...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Text(widget.tableName),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, size: 22),
            tooltip: _isSearching ? 'Close search' : 'Search',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: 'Refresh',
            onPressed: () => ref
                .read(tableDetailProvider(widget.tableName).notifier)
                .loadEntries(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal))
          : state.entries.isEmpty
              ? _buildEmptyState()
              : filteredEntries.isEmpty
                  ? _buildNoResultsState()
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredEntries.length,
                          itemBuilder: (context, index) {
                            return _buildEntryTile(filteredEntries[index]);
                          },
                        ),
                      ),
                    ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64,
              color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No entries matching "$_searchQuery"',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outlined,
            size: 64,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No entries yet',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Encrypt some text and save it to this table',
            style: TextStyle(color: AppColors.textHint, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(EncryptedEntry entry) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _confirmDelete(entry),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: AppColors.error),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock, color: AppColors.tealLight, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.note.isNotEmpty ? entry.note : 'No note',
                          style: TextStyle(
                            color: entry.note.isNotEmpty
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            fontStyle: entry.note.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Helpers.formatDate(entry.createdAt),
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Encrypted preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  Helpers.truncateText(entry.encryptedText, maxLength: 80),
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: Icons.edit_note,
                    label: 'Note',
                    onTap: () => _showEditNoteDialog(entry),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.copy,
                    label: 'Copy',
                    onTap: () =>
                        Helpers.copyToClipboard(context, entry.encryptedText),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.lock_open,
                    label: 'Decrypt',
                    isPrimary: true,
                    onTap: () => _showDecryptDialog(entry),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColors.teal.withOpacity(0.15)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPrimary
                  ? AppColors.teal.withOpacity(0.3)
                  : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16,
                  color: isPrimary
                      ? AppColors.tealLight
                      : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? AppColors.tealLight
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(EncryptedEntry entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete Entry'),
          ],
        ),
        content: Text(
          'Delete "${entry.note.isNotEmpty ? entry.note : 'this entry'}"?\n\nThis cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      ref
          .read(tableDetailProvider(widget.tableName).notifier)
          .deleteEntry(entry.id);
      ref.read(tablesProvider.notifier).loadTables();
      if (mounted) Helpers.showSuccess(context, 'Entry deleted');
    }
    return false;
  }

  void _showEditNoteDialog(EncryptedEntry entry) {
    final controller = TextEditingController(text: entry.note);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.teal),
            SizedBox(width: 8),
            Text('Edit Note'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'What was this about?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(tableDetailProvider(widget.tableName).notifier)
                  .updateNote(entry.id, controller.text.trim());
              Navigator.pop(dialogContext);
              Helpers.showSuccess(context, 'Note updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDecryptDialog(EncryptedEntry entry) {
    showDialog(
      context: context,
      builder: (context) => DecryptDialog(entry: entry),
    );
  }
}