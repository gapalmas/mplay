import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/demo_models.dart';

class PlaylistService {
  static const _boxName = 'playlist_cache';
  static const _playlistsKey = 'playlists';

  late Box _box;

  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  Future<List<DemoPlaylist>> loadCustomPlaylists(List<DemoTrack> libraryTracks) async {
    final raw = _box.get(_playlistsKey) as String?;
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final byKey = <String, DemoTrack>{
        for (final t in libraryTracks) _trackKey(t): t,
      };

      final output = <DemoPlaylist>[];
      for (final item in decoded) {
        final name = item['name'] as String?;
        final keyList = (item['trackKeys'] as List?)?.cast<String>() ?? <String>[];
        if (name == null || name.trim().isEmpty) continue;

        final tracks = <DemoTrack>[];
        for (final key in keyList) {
          final track = byKey[key];
          if (track != null) tracks.add(track);
        }

        output.add(_toDemoPlaylist(name, tracks));
      }

      return output;
    } catch (e) {
      print('PlaylistService: error loading playlists: $e');
      return [];
    }
  }

  Future<void> createPlaylist(String name) async {
    final list = await _loadRawPlaylists();
    final exists = list.any((p) => (p['name'] as String).toLowerCase() == name.toLowerCase());
    if (exists) return;
    list.add({'name': name, 'trackKeys': <String>[]});
    await _saveRawPlaylists(list);
  }

  Future<void> deletePlaylist(String name) async {
    final list = await _loadRawPlaylists();
    list.removeWhere((p) => (p['name'] as String).toLowerCase() == name.toLowerCase());
    await _saveRawPlaylists(list);
  }

  Future<void> renamePlaylist(String oldName, String newName) async {
    final list = await _loadRawPlaylists();
    final exists = list.any((p) => (p['name'] as String).toLowerCase() == newName.toLowerCase());
    if (exists) return;

    for (var i = 0; i < list.length; i++) {
      if ((list[i]['name'] as String).toLowerCase() == oldName.toLowerCase()) {
        list[i]['name'] = newName;
        break;
      }
    }
    await _saveRawPlaylists(list);
  }

  Future<void> addTrackToPlaylist(String playlistName, DemoTrack track) async {
    final list = await _loadRawPlaylists();
    final key = _trackKey(track);

    for (final item in list) {
      final name = item['name'] as String;
      if (name.toLowerCase() != playlistName.toLowerCase()) continue;

      final keys = (item['trackKeys'] as List).cast<String>();
      if (!keys.contains(key)) {
        keys.add(key);
      }
      break;
    }

    await _saveRawPlaylists(list);
  }

  Future<List<Map<String, dynamic>>> _loadRawPlaylists() async {
    final raw = _box.get(_playlistsKey) as String?;
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveRawPlaylists(List<Map<String, dynamic>> playlists) async {
    await _box.put(_playlistsKey, jsonEncode(playlists));
  }

  DemoPlaylist _toDemoPlaylist(String name, List<DemoTrack> tracks) {
    final totalSec = tracks.fold(0, (sum, t) => sum + t.durationSeconds);
    final mins = totalSec ~/ 60;
    final secs = totalSec % 60;
    return DemoPlaylist(
      name: name,
      trackCount: tracks.length,
      totalDuration: '$mins:${secs.toString().padLeft(2, '0')}',
      tracks: tracks,
    );
  }

  String _trackKey(DemoTrack track) => track.uri ?? track.filePath ?? '${track.artist}|${track.album}|${track.title}';
}
