import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/demo_models.dart';

class LyricLine {
  const LyricLine({required this.time, required this.text});

  final Duration time;
  final String text;

  Map<String, dynamic> toJson() => {'ms': time.inMilliseconds, 'text': text};

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      time: Duration(milliseconds: (json['ms'] as num?)?.toInt() ?? 0),
      text: (json['text'] as String?) ?? '',
    );
  }
}

class LyricsPayload {
  const LyricsPayload({
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.duration,
    required this.plainLyrics,
    required this.syncedLyrics,
    required this.lines,
    this.id,
    this.instrumental = false,
  });

  final int? id;
  final String trackName;
  final String artistName;
  final String albumName;
  final int duration;
  final bool instrumental;
  final String plainLyrics;
  final String syncedLyrics;
  final List<LyricLine> lines;

  bool get hasSynced => lines.isNotEmpty;

  int lineIndexAt(Duration position) {
    if (lines.isEmpty) return -1;
    final targetMs = position.inMilliseconds;
    for (var index = lines.length - 1; index >= 0; index--) {
      if (targetMs >= lines[index].time.inMilliseconds) {
        return index;
      }
    }
    return -1;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'trackName': trackName,
    'artistName': artistName,
    'albumName': albumName,
    'duration': duration,
    'instrumental': instrumental,
    'plainLyrics': plainLyrics,
    'syncedLyrics': syncedLyrics,
    'lines': lines.map((line) => line.toJson()).toList(),
  };

  factory LyricsPayload.fromJson(Map<String, dynamic> json) {
    return LyricsPayload(
      id: (json['id'] as num?)?.toInt(),
      trackName: (json['trackName'] as String?) ?? '',
      artistName: (json['artistName'] as String?) ?? '',
      albumName: (json['albumName'] as String?) ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      instrumental: (json['instrumental'] as bool?) ?? false,
      plainLyrics: (json['plainLyrics'] as String?) ?? '',
      syncedLyrics: (json['syncedLyrics'] as String?) ?? '',
      lines: ((json['lines'] as List?) ?? const [])
          .whereType<Map>()
          .map((raw) => LyricLine.fromJson(raw.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class LyricsService {
  static const _baseUrl = 'https://lrclib.net';
  static const _boxName = 'lyrics_cache';
  static const _schemaKey = 'schema_version';
  static const _schemaVersion = 1;

  Box? _box;
  final Map<String, Future<LyricsPayload?>> _inFlight = {};

  Future<void> _ensureInitialized() async {
    if (_box != null && _box!.isOpen) return;

    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);

    final schema = _box!.get(_schemaKey) as int?;
    if (schema != _schemaVersion) {
      await _box!.clear();
      await _box!.put(_schemaKey, _schemaVersion);
    }
  }

  Future<LyricsPayload?> fetchLyricsForTrack(
    DemoTrack track, {
    bool forceRefresh = false,
  }) async {
    await _ensureInitialized();

    final key = _cacheKey(track);
    if (!forceRefresh) {
      final cached = _readCache(key);
      if (cached != null) {
        return cached;
      }
    }

    final running = _inFlight[key];
    if (running != null) {
      return running;
    }

    final future = _fetchAndCache(track, key);
    _inFlight[key] = future;

    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  LyricsPayload? _readCache(String key) {
    final raw = _box?.get(key) as String?;
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return LyricsPayload.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<LyricsPayload?> _fetchAndCache(DemoTrack track, String key) async {
    final payload = await _fetchFromApi(track);
    if (payload != null) {
      await _box?.put(key, jsonEncode(payload.toJson()));
    }
    return payload;
  }

  Future<LyricsPayload?> _fetchFromApi(DemoTrack track) async {
    final exactCached = await _getBySignature(track, cachedOnly: true);
    if (exactCached != null) {
      return exactCached;
    }

    final exact = await _getBySignature(track, cachedOnly: false);
    if (exact != null) {
      return exact;
    }

    final searched = await _searchAndPick(track);
    return searched;
  }

  Future<LyricsPayload?> _getBySignature(
    DemoTrack track, {
    required bool cachedOnly,
  }) async {
    final endpoint = cachedOnly ? '/api/get-cached' : '/api/get';
    final uri = Uri.parse('$_baseUrl$endpoint').replace(
      queryParameters: {
        'track_name': track.title,
        'artist_name': track.artist,
        'album_name': track.album,
        'duration': track.durationSeconds.toString(),
      },
    );

    final json = await _getJsonObject(uri);
    if (json == null || json['trackName'] == null) {
      return null;
    }

    return _toPayload(json);
  }

  Future<LyricsPayload?> _searchAndPick(DemoTrack track) async {
    final query = '${track.title} ${track.artist}'.trim();
    final uri = Uri.parse(
      '$_baseUrl/api/search',
    ).replace(queryParameters: {'q': query});

    final list = await _getJsonArray(uri);
    if (list == null || list.isEmpty) {
      return null;
    }

    final best =
        list
            .whereType<Map>()
            .map((raw) => raw.cast<String, dynamic>())
            .map((item) => MapEntry(item, _score(item, track)))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    if (best.isEmpty || best.first.value <= 0) {
      return null;
    }

    return _toPayload(best.first.key);
  }

  int _score(Map<String, dynamic> item, DemoTrack track) {
    var score = 0;

    final trackName = (item['trackName'] as String? ?? '').toLowerCase();
    final artistName = (item['artistName'] as String? ?? '').toLowerCase();
    final albumName = (item['albumName'] as String? ?? '').toLowerCase();

    final targetTitle = track.title.toLowerCase();
    final targetArtist = track.artist.toLowerCase();
    final targetAlbum = track.album.toLowerCase();

    if (trackName == targetTitle) score += 60;
    if (trackName.contains(targetTitle) || targetTitle.contains(trackName)) {
      score += 30;
    }

    if (artistName == targetArtist) score += 40;
    if (artistName.contains(targetArtist) ||
        targetArtist.contains(artistName)) {
      score += 20;
    }

    if (targetAlbum.isNotEmpty) {
      if (albumName == targetAlbum) score += 20;
      if (albumName.contains(targetAlbum) || targetAlbum.contains(albumName)) {
        score += 10;
      }
    }

    final duration = (item['duration'] as num?)?.toInt() ?? 0;
    final diff = (duration - track.durationSeconds).abs();
    if (diff <= 2) {
      score += 30;
    } else if (diff <= 5) {
      score += 15;
    } else if (diff <= 10) {
      score += 5;
    }

    return score;
  }

  LyricsPayload _toPayload(Map<String, dynamic> json) {
    final synced = (json['syncedLyrics'] as String?) ?? '';
    final plain = (json['plainLyrics'] as String?) ?? '';

    return LyricsPayload(
      id: (json['id'] as num?)?.toInt(),
      trackName: (json['trackName'] as String?) ?? '',
      artistName: (json['artistName'] as String?) ?? '',
      albumName: (json['albumName'] as String?) ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      instrumental: (json['instrumental'] as bool?) ?? false,
      plainLyrics: plain,
      syncedLyrics: synced,
      lines: _parseLrc(synced),
    );
  }

  List<LyricLine> _parseLrc(String lrc) {
    if (lrc.trim().isEmpty) {
      return const [];
    }

    final lines = <LyricLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');

    for (final row in const LineSplitter().convert(lrc)) {
      final matches = regex.allMatches(row).toList();
      if (matches.isEmpty) {
        continue;
      }

      final lyricText = row.replaceAll(regex, '').trim();
      for (final match in matches) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
        final fractionRaw = match.group(3) ?? '0';
        final fraction = int.tryParse(fractionRaw) ?? 0;
        final milliseconds = fractionRaw.length == 2 ? fraction * 10 : fraction;

        lines.add(
          LyricLine(
            time: Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: milliseconds,
            ),
            text: lyricText,
          ),
        );
      }
    }

    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }

  Future<Map<String, dynamic>?> _getJsonObject(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'mplay/1.0 (https://github.com/gapalmas/mplay)',
      );
      final response = await request.close();
      final body = await utf8.decodeStream(response);

      if (response.statusCode != 200 || body.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  Future<List<dynamic>?> _getJsonArray(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'mplay/1.0 (https://github.com/gapalmas/mplay)',
      );
      final response = await request.close();
      final body = await utf8.decodeStream(response);

      if (response.statusCode != 200 || body.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(body);
      if (decoded is List) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  String _cacheKey(DemoTrack track) {
    final title = _normalize(track.title);
    final artist = _normalize(track.artist);
    final album = _normalize(track.album);
    final duration = track.durationSeconds;
    return 'lyrics:$title|$artist|$album|$duration';
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
