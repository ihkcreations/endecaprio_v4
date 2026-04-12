// lib/features/encrypt_decrypt/widgets/save_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/entry_repository.dart';
import '../../tables/providers/tables_provider.dart';

class SaveDialog extends ConsumerStatefulWidget {
  final String encryptedText;

  const SaveDialog({super.key, required this.encryptedText});

  @override
  ConsumerState<SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends ConsumerState<SaveDialog> {
  final _noteController = TextEditingController();
  final _newTableController = TextEditingController();
  String _selectedTable = AppConstants.defaultTableName;
  bool _isCreatingNewTable = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    _newTableController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      String tableName = _selectedTable;

      if (_isCreatingNewTable) {
        final newName = _newTableController.text.trim();
        if (newName.isEmpty) {
          _showError('Please enter a table name');
          setState(() => _isSaving = false);
          return;
        }
        tableName = newName;
        await ref.read(tablesProvider.notifier).createTable(newName);
      }

      // Save entry locally
      final repo = ref.read(entryRepositoryProvider);
      await repo.saveEntry(
        encryptedText: widget.encryptedText,
        tableName: tableName,
        note: _noteController.text.trim(),
      );

      // Refresh tables list
      ref.read(tablesProvider.notifier).loadTables();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Failed to save: $e');
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tablesState = ref.watch(tablesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Row(
                  children: [
                    Icon(Icons.save, color: AppColors.teal, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Save Encrypted Entry',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Table Selection
                const Text(
                  'Select Table',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                if (!_isCreatingNewTable) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: tablesState.tables
                                .any((t) => t.tableName == _selectedTable)
                            ? _selectedTable
                            : (tablesState.tables.isNotEmpty
                                ? tablesState.tables.first.tableName
                                : AppConstants.defaultTableName),
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: AppColors.textSecondary),
                        items: tablesState.tables.map((table) {
                          return DropdownMenuItem(
                            value: table.tableName,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.folder,
                                  color: AppColors.teal,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(table.tableName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedTable = value);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _isCreatingNewTable = true),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create New Table'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.tealLight,
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _newTableController,
                    autofocus: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter new table name...',
                      prefixIcon: const Icon(Icons.create_new_folder),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _isCreatingNewTable = false;
                            _newTableController.clear();
                          });
                        },
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Note
                const Text(
                  'Add a Note',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'What was this about? e.g., "Bank password"',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),

                const SizedBox(height: 20),

                // Preview
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock,
                          color: AppColors.textHint, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.encryptedText.length > 50
                              ? '${widget.encryptedText.substring(0, 50)}...'
                              : widget.encryptedText,
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSaving ? null : () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check, size: 18),
                                  SizedBox(width: 6),
                                  Text('Save'),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}