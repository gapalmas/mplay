import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/backup_service.dart';
import '../blocs/app_settings/app_settings_cubit.dart';
import '../blocs/library/library_cubit.dart';
import '../localization/app_strings.dart';
import '../widgets/player_mini_player_bar.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final BackupService _backupService = BackupService();

  bool playlists = true;
  bool settings = true;
  bool _isBusy = true;
  List<BackupEntry> _backups = const [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    await _backupService.initialize();
    final backups = await _backupService.listBackups();
    if (!mounted) return;

    setState(() {
      _backups = backups;
      _isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.backupAndRestore)),
      body: _isBusy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  strings.export,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Card(
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: playlists,
                        onChanged: (value) =>
                            setState(() => playlists = value ?? false),
                        title: Text(strings.includePlaylists),
                      ),
                      CheckboxListTile(
                        value: settings,
                        onChanged: (value) =>
                            setState(() => settings = value ?? false),
                        title: Text(strings.includeSettings),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: FilledButton.icon(
                          onPressed: (!playlists && !settings)
                              ? null
                              : () => _createBackup(context),
                          icon: const Icon(Icons.upload_rounded),
                          label: Text(strings.exportBackup),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.import,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '⚠ ${strings.restoreWarning}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.history,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Card(
                  child: _backups.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(strings.noBackups),
                        )
                      : Column(
                          children: _backups
                              .map(
                                (backup) => ListTile(
                                  leading: const Icon(Icons.save_rounded),
                                  title: Text(backup.fileName),
                                  subtitle: Text(
                                    '${_formatDateTime(backup.exportedAt)} • '
                                    '${backup.contents.join(', ')} • '
                                    '${backup.fileSizeBytes} ${strings.bytesLabel}',
                                  ),
                                  trailing: Wrap(
                                    spacing: 4,
                                    children: [
                                      IconButton(
                                        tooltip: strings.restoreBackup,
                                        onPressed: () =>
                                            _restoreBackup(context, backup),
                                        icon:
                                            const Icon(Icons.restore_rounded),
                                      ),
                                      IconButton(
                                        tooltip: strings.deleteBackup,
                                        onPressed: () =>
                                            _deleteBackup(context, backup),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
      bottomNavigationBar: const PlayerMiniPlayerBar(),
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    final backup = await _backupService.createBackup(
      includePlaylists: playlists,
      includeSettings: settings,
    );

    await _loadBackups();
    if (!mounted) return;

    final strings = AppStrings.of(this.context);

    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(content: Text('${strings.backupCreated} ${backup.fileName}')),
    );
  }

  Future<void> _restoreBackup(BuildContext context, BackupEntry backup) async {
    final strings = AppStrings.of(context);
    final appSettingsCubit = this.context.read<AppSettingsCubit>();
    final libraryCubit = this.context.read<LibraryCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.restoreBackup),
          content: Text(strings.restoreWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.restore),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _backupService.restoreBackup(backup.filePath);
    if (!mounted) return;

    await appSettingsCubit.loadSettings();
    await libraryCubit.loadLibrary();
    if (!mounted) return;

    final updatedStrings = AppStrings.of(this.context);

    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(content: Text(updatedStrings.backupRestored)),
    );
  }

  Future<void> _deleteBackup(BuildContext context, BackupEntry backup) async {
    await _backupService.deleteBackup(backup.filePath);
    await _loadBackups();
    if (!mounted) return;

    final strings = AppStrings.of(this.context);

    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(content: Text(strings.backupDeleted)),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day $hour:$minute';
  }
}
