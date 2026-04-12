// lib/features/tables/screens/tables_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/helpers.dart';
import '../providers/tables_provider.dart';
import '../../../data/models/table_meta.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../widgets/pin_gate_dialog.dart';

class TablesListScreen extends ConsumerStatefulWidget {
  const TablesListScreen({super.key});

  @override
  ConsumerState<TablesListScreen> createState() => _TablesListScreenState();
}

class _TablesListScreenState extends ConsumerState<TablesListScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TableMeta> _filterTables(List<TableMeta> tables) {
    if (_searchQuery.isEmpty) return tables;
    return tables
        .where((t) =>
            t.tableName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tablesState = ref.watch(tablesProvider);
    final filteredTables = _filterTables(tablesState.tables);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search tables...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : const Text('My Tables'),
        automaticallyImplyLeading: false,
        actions: [
          // Search
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
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: 'Refresh',
            onPressed: () => ref.read(tablesProvider.notifier).loadTables(),
          ),
          // New Table
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Table',
            onPressed: () => _showCreateTableDialog(),
          ),
        ],
      ),
      body: tablesState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal))
          : tablesState.tables.isEmpty
              ? _buildEmptyState()
              : filteredTables.isEmpty
                  ? _buildNoResultsState()
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTables.length,
                          itemBuilder: (context, index) {
                            return _buildTableCard(filteredTables[index]);
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
          Icon(Icons.search_off,
              size: 64, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No tables matching "$_searchQuery"',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 16),
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
          Icon(Icons.folder_open,
              size: 64, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No tables yet',
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tables are created when you save encrypted entries',
            style: TextStyle(color: AppColors.textHint, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateTableDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Table'),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(TableMeta table) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openTableDetail(table.tableName),
        onLongPress: () => _showTableOptions(table),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Folder icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder,
                  color: AppColors.tealLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            table.tableName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (table.tableName == AppConstants.defaultTableName)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: AppColors.tealLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${table.entryCount} ${table.entryCount == 1 ? 'entry' : 'entries'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Actions ────────────────────────────────────

  void _openTableDetail(String tableName) async {
    final pinState = ref.read(pinProvider);

    if (pinState.isPinEnabled) {
      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PinGateDialog(),
      );

      if (verified != true) return;
    }

    if (mounted) {
      Navigator.pushNamed(
        context,
        '/table-detail',
        arguments: tableName,
      );
    }
  }

  void _showCreateTableDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.create_new_folder, color: AppColors.teal),
            SizedBox(width: 8),
            Text('New Table'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter table name...',
            prefixIcon: Icon(Icons.folder),
          ),
          onSubmitted: (_) => _createTable(controller, dialogContext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createTable(controller, dialogContext),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createTable(
      TextEditingController controller, BuildContext dialogContext) async {
    final name = controller.text.trim();
    if (name.isEmpty) {
      Helpers.showError(context, 'Please enter a table name');
      return;
    }

    final success =
        await ref.read(tablesProvider.notifier).createTable(name);
    if (dialogContext.mounted) Navigator.pop(dialogContext);
    if (!mounted) return;
    if (success) {
      Helpers.showSuccess(context, 'Table "$name" created');
    } else {
      Helpers.showError(context, 'Table "$name" already exists');
    }
  }

  void _showTableOptions(TableMeta table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              table.tableName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Rename
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.teal),
              title: const Text('Rename',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(sheetContext);
                _showRenameDialog(table);
              },
            ),

            // Delete
            if (table.tableName != AppConstants.defaultTableName)
              ListTile(
                leading:
                    const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showDeleteConfirmation(table);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(TableMeta table) {
    final controller = TextEditingController(text: table.tableName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Table'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'New table name...',
            prefixIcon: Icon(Icons.edit),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == table.tableName) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                return;
              }
              final success = await ref
                  .read(tablesProvider.notifier)
                  .renameTable(table.tableName, newName);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (!mounted) return;
              if (success) {
                Helpers.showSuccess(
                    context, 'Table renamed to "$newName"');
              } else {
                Helpers.showError(
                    context, 'Name already exists or cannot rename');
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(TableMeta table) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete Table'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${table.tableName}" and all its ${table.entryCount} entries?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'This cannot be undone.',
              style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(dialogContext);
              Future.microtask(() async {
                if (!mounted) return;
                await ref
                    .read(tablesProvider.notifier)
                    .deleteTable(table.tableName);
                if (!mounted) return;
                Helpers.showSuccess(context, 'Table deleted');
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}