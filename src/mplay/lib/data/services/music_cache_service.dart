import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/demo_models.dart';

/// Persists the scanned music library to Hive to avoid rescanning on every launch.
/// Cache is valid for 24 hours.
class MusicCacheService {
  static const _boxName = 'music_cache';
  static const _tracksKey = 'tracks';
  static const _timestampKey = 'last_scan';
  static const _cacheValidityMs = 24 * 60 * 60 * 1000; // 24 hours

  late Box _box;

  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  bool get isCacheValid {
    final ts = _box.get(_timestampKey) as int?;
    if (ts == null) return false;
    return DateTime.now().millisecondsSinceEpoch - ts < _cacheValidityMs;
  }

  List<DemoTrack>? getCachedTracks() {
    if (!isCacheValid) return null;
    final raw = _box.get(_tracksKey) as String?;
    if (raw == null) return null;

    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(_fromJson).toList();
    } catch (e) {
      print('MusicCacheService: decode error: $e');
      return null;
    }
  }

  Future<void> cacheTracks(List<DemoTrack> tracks) async {
    final encoded = jsonEncode(tracks.map(_toJson).toList());
    await _box.put(_tracksKey, encoded);
    await _box.put(_timestampKey, DateTime.now().millisecondsSinceEpoch);
    print('MusicCacheService: cached ${tracks.length} tracks');
  }

  Future<void> clearCache() async {
    await _box.delete(_tracksKey);
    await _box.delete(_timestampKey);
  }

  Map<String, dynamic> _toJson(DemoTrack t) => {
        'title': t.title,
        'artist': t.artist,
        'album': t.album,
        'durationLabel': t.durationLabel,
        'durationSeconds': t.durationSeconds,
        'format': t.format,
        'bitrateKbps': t.bitrateKbps,
        'filePath': t.filePath,
        'uri': t.uri,
      };

  DemoTrack _fromJson(Map<String, dynamic> m) => DemoTrack(
        title: m['title'] as String,
        artist: m['artist'] as String,
        album: m['album'] as String,
        durationLabel: m['durationLabel'] as String,
        durationSeconds: m['durationSeconds'] as int,
        format: m['format'] as String,
        bitrateKbps: m['bitrateKbps'] as int,
        filePath: m['filePath'] as String?,
        uri: m['uri'] as String?,
      );
}
