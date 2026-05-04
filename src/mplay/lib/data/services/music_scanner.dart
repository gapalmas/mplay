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

    // Filter out very short clips (< 30s) and non-music
    final filtered = songs.where((s) {
      final duration = s.duration ?? 0;
      return duration >= 30000; // at least 30 seconds
    }).toList();

    return filtered.map(_songModelToTrack).toList();
  }

  DemoTrack _songModelToTrack(SongModel song) {
    final durationMs = song.duration ?? 0;
    final durationSec = (durationMs / 1000).round();
    final mins = durationSec ~/ 60;
    final secs = durationSec % 60;

    return DemoTrack(
      title: song.title.isNotEmpty ? song.title : 'Unknown Title',
      artist: (song.artist?.isNotEmpty == true) ? song.artist! : 'Unknown Artist',
      album: (song.album?.isNotEmpty == true) ? song.album! : 'Unknown Album',
      durationLabel: '$mins:${secs.toString().padLeft(2, '0')}',
      durationSeconds: durationSec,
      format: song.fileExtension.toUpperCase().isNotEmpty ? song.fileExtension.toUpperCase() : 'MP3',
      bitrateKbps: 0,
      songId: song.id,
      uri: song.uri,
      filePath: song.data,
    );
  }
}
