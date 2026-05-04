import 'dart:io';

import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/demo_models.dart';

/// Scans the device music library using Android MediaStore via on_audio_query
class MusicScanner {
  MusicScanner() : _audioQuery = OnAudioQuery();

  final OnAudioQuery _audioQuery;

  /// Request and check storage permissions
  Future<bool> requestPermissions() async {
    final audioQueryPerm = await _audioQuery.permissionsRequest();

    if (!Platform.isAndroid) {
      return audioQueryPerm;
    }

    final audioStatus = await Permission.audio.request();
    final imagesStatus = await Permission.photos.request();

    final audioGranted = audioStatus.isGranted || audioStatus.isLimited;
    final imagesGranted = imagesStatus.isGranted || imagesStatus.isLimited;

    return audioQueryPerm && audioGranted && imagesGranted;
  }

  Future<bool> hasPermissions() async {
    return _audioQuery.permissionsStatus();
  }

  /// Scan device for all music tracks, returns list of [DemoTrack]
  Future<List<DemoTrack>> scanTracks() async {
    final hasPerm = await requestPermissions();
    if (!hasPerm) {
      print('MusicScanner: storage permission denied');
      return [];
    }

    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    print('MusicScanner: found ${songs.length} songs on device');

    // Filter out very short clips (< 30s), non-music and excluded app directories
    final filtered = songs.where((s) {
      final duration = s.duration ?? 0;
      if (duration < 30000) return false; // at least 30 seconds
      return !_isExcludedPath(s.data);
    }).toList();

    return filtered.map(_songModelToTrack).toList();
  }

  DemoTrack _songModelToTrack(SongModel song) {
    final durationMs = song.duration ?? 0;
    final durationSec = (durationMs / 1000).round();
    final mins = durationSec ~/ 60;
    final secs = durationSec % 60;
    final bitrateKbps = _estimateBitrateKbps(
      sizeBytes: song.size,
      durationMs: durationMs,
    );

    return DemoTrack(
      title: song.title.isNotEmpty ? song.title : 'Unknown Title',
      artist: (song.artist?.isNotEmpty == true)
          ? song.artist!
          : 'Unknown Artist',
      album: (song.album?.isNotEmpty == true) ? song.album! : 'Unknown Album',
      durationLabel: '$mins:${secs.toString().padLeft(2, '0')}',
      durationSeconds: durationSec,
      format: song.fileExtension.toUpperCase().isNotEmpty
          ? song.fileExtension.toUpperCase()
          : 'MP3',
      bitrateKbps: bitrateKbps,
      songId: song.id,
      uri: song.uri,
      filePath: song.data,
    );
  }

  int _estimateBitrateKbps({required int sizeBytes, required int durationMs}) {
    if (sizeBytes <= 0 || durationMs <= 0) {
      return 0;
    }

    // kbps ≈ (bytes * 8) / durationMs
    final kbps = ((sizeBytes * 8) / durationMs).round();
    return kbps > 0 ? kbps : 0;
  }

  /// Returns true if the file path belongs to a directory that should be
  /// excluded from the music library (messaging apps, call recorders, etc.).
  bool _isExcludedPath(String? path) {
    if (path == null || path.isEmpty) return false;

    final lower = path.toLowerCase();

    // Segments that unambiguously identify non-music audio from apps or system recorders.
    const excludedSegments = [
      // WhatsApp (internal & external storage, including scoped storage path)
      'whatsapp/media/whatsapp audio',
      'whatsapp/media/whatsapp voice notes',
      'android/media/com.whatsapp',
      // Telegram voice messages and audio
      'telegram/telegram audio',
      'telegram/audio',
      'android/media/org.telegram',
      // Call recorders – common across manufacturers and third-party apps
      'callrecording',
      'call recording',
      'call_recording',
      'callrecorder',
      'call recorder',
      'call_recorder',
      'recorded calls',
      'recordedcalls',
      'phonerecorder',
      'phone recorder',
      // MIUI / Xiaomi voice recorder
      'miui/sound_recorder',
      'sound_recorder',
      // Samsung / generic voice memo / voice recorder
      'voicenote',
      'voice note',
      'voicememo',
      'voice memo',
      'voicerecorder',
      'voice recorder',
      'voice_recorder',
      // Android system notifications and ringtones (not music)
      '/notifications/',
      '/ringtones/',
      '/alarms/',
    ];

    return excludedSegments.any((seg) => lower.contains(seg));
  }
}
