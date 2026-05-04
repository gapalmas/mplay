import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'app_settings_service.dart';
import 'playlist_service.dart';

class BackupService {
  BackupService()
      : _playlistService = PlaylistService(),
        _appSettingsService = AppSettingsService();

  final PlaylistService _playlistService;
  final AppSettingsService _appSettingsService;

  Future<void> initialize() async {
    await _playlistService.initialize();
    await _appSettingsService.initialize();
  }

  Future<BackupEntry> createBackup({
    required bool includePlaylists,
    required bool includeSettings,
  }) async {
    final backupDirectory = await _resolveBackupDirectory();
    if (!await backupDirectory.exists()) {
      await backupDirectory.create(recursive: true);
    }

    final exportedAt = DateTime.now();
    final contents = <String>[];
    final data = <String, dynamic>{};

    if (includePlaylists) {
      contents.add('playlists');
      data['playlists'] = await _playlistService.exportRawPlaylists();
    }

    if (includeSettings) {
      contents.add('settings');
      data['settings'] = await _appSettingsService.exportSettings();
    }

    final fileName =
        'mplay_backup_${exportedAt.toIso8601String().replaceAll(':', '-')}.json';
    final file = File('${backupDirectory.path}/$fileName');
    final payload = {
      'schemaVersion': 1,
      'exportedAt': exportedAt.toIso8601String(),
      'contents': contents,
      'data': data,
    };

    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return BackupEntry(
      filePath: file.path,
      fileName: fileName,
      exportedAt: exportedAt,
      contents: contents,
      fileSizeBytes: await file.length(),
    );
  }

  Future<List<BackupEntry>> listBackups() async {
    final backupDirectory = await _resolveBackupDirectory();
    if (!await backupDirectory.exists()) {
      return const [];
    }

    final entries = <BackupEntry>[];
    await for (final entity in backupDirectory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }

      try {
        final raw = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        final contents = (raw['contents'] as List?)?.cast<String>() ?? const <String>[];
        final exportedAt = DateTime.tryParse(raw['exportedAt'] as String? ?? '');
        final stat = await entity.stat();
        entries.add(
          BackupEntry(
            filePath: entity.path,
            fileName: entity.uri.pathSegments.isNotEmpty
                ? entity.uri.pathSegments.last
                : entity.path.split(Platform.pathSeparator).last,
            exportedAt: exportedAt ?? stat.modified,
            contents: contents,
            fileSizeBytes: stat.size,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    entries.sort((a, b) => b.exportedAt.compareTo(a.exportedAt));
    return entries;
  }

  Future<BackupRestoreSummary> restoreBackup(String filePath) async {
    final file = File(filePath);
    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final data = (raw['data'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    if (data.containsKey('playlists')) {
      final rawPlaylists = (data['playlists'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
      await _playlistService.importRawPlaylists(rawPlaylists);
    }

    if (data.containsKey('settings')) {
      final rawSettings = (data['settings'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      await _appSettingsService.importSettings(rawSettings);
    }

    return BackupRestoreSummary(
      restoredPlaylists: data.containsKey('playlists'),
      restoredSettings: data.containsKey('settings'),
    );
  }

  Future<void> deleteBackup(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _resolveBackupDirectory() async {
    if (Platform.isAndroid) {
      final directories = await getExternalStorageDirectories(
        type: StorageDirectory.documents,
      );
      if (directories != null && directories.isNotEmpty) {
        return Directory('${directories.first.path}/mplay_backups');
      }
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    return Directory('${documentsDirectory.path}/mplay_backups');
  }
}

class BackupEntry {
  const BackupEntry({
    required this.filePath,
    required this.fileName,
    required this.exportedAt,
    required this.contents,
    required this.fileSizeBytes,
  });

  final String filePath;
  final String fileName;
  final DateTime exportedAt;
  final List<String> contents;
  final int fileSizeBytes;
}

class BackupRestoreSummary {
  const BackupRestoreSummary({
    required this.restoredPlaylists,
    required this.restoredSettings,
  });

  final bool restoredPlaylists;
  final bool restoredSettings;
}
