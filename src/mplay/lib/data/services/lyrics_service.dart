import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

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
  static const _lyricsStorageChannel = MethodChannel('mplay/lyrics_storage');

  Directory? _lyricsDir;
  final Map<String, Future<LyricsPayload?>> _inFlight = {};

  Future<void> _ensureInitialized() async {
    if (_lyricsDir != null) return;

    Directory? baseDir;
    try {
      final externalDocs = await getExternalStorageDirectories(
        type: StorageDirectory.documents,
      );
      if (externalDocs != null && externalDocs.isNotEmpty) {
        baseDir = externalDocs.first;
      }
    } catch (_) {
      baseDir = null;
    }

    baseDir ??= await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}/lyrics');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _lyricsDir = dir;
  }

  Future<LyricsPayload?> fetchLyricsForTrack(
    DemoTrack track, {
    bool forceRefresh = false,
  }) async {
    await _ensureInitialized();

    final key = _cacheKey(track);
    if (!forceRefresh) {
      final cached = await _readCacheFromFile(key);
      if (cached != null) {
        return cached;
      }
    }

    final running = _inFlight[key];
    if (running != null) {
      return running;
    }

    final future = _fetchAndPersist(track, key);
    _inFlight[key] = future;

    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<LyricsPayload?> _readCacheFromFile(String key) async {
    final rawFromPublic = await _readPublicJsonOnAndroid(key);
    if (rawFromPublic != null && rawFromPublic.isNotEmpty) {
      try {
        final json = jsonDecode(rawFromPublic) as Map<String, dynamic>;
        return LyricsPayload.fromJson(json);
      } catch (_) {
        // fallback al almacenamiento interno
      }
    }

    final file = _jsonFileForKey(key);
    if (!await file.exists()) {
      return null;
    }

    try {
      final raw = await file.readAsString();
      if (raw.isEmpty) {
        return null;
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return LyricsPayload.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<LyricsPayload?> _fetchAndPersist(DemoTrack track, String key) async {
    final payload = await _fetchFromApi(track);
    if (payload != null) {
      await _writeCacheFiles(key, payload);
    }
    return payload;
  }

  Future<void> _writeCacheFiles(String key, LyricsPayload payload) async {
    await _writePublicFilesOnAndroid(key, payload);

    final jsonFile = _jsonFileForKey(key);
    await jsonFile.writeAsString(jsonEncode(payload.toJson()), flush: true);

    final lrcFile = _lrcFileForKey(key);
    if (payload.syncedLyrics.trim().isNotEmpty) {
      await lrcFile.writeAsString(payload.syncedLyrics, flush: true);
    } else if (await lrcFile.exists()) {
      await lrcFile.delete();
    }
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

  File _jsonFileForKey(String key) {
    final dirPath = _lyricsDir?.path;
    if (dirPath == null) {
      throw StateError('LyricsService is not initialized');
    }
    return File('$dirPath/${_safeFileName(key)}.json');
  }

  File _lrcFileForKey(String key) {
    final dirPath = _lyricsDir?.path;
    if (dirPath == null) {
      throw StateError('LyricsService is not initialized');
    }
    return File('$dirPath/${_safeFileName(key)}.lrc');
  }

  String _safeFileName(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final compact = normalized
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final short = compact.substring(0, min(compact.length, 80));
    return '${_stableHash(key).toRadixString(16)}_$short';
  }

  int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<String?> _readPublicJsonOnAndroid(String key) async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      return await _lyricsStorageChannel.invokeMethod<String>(
        'readLyricsJson',
        {'baseName': _safeFileName(key)},
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writePublicFilesOnAndroid(
    String key,
    LyricsPayload payload,
  ) async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _lyricsStorageChannel.invokeMethod<bool>('writeLyricsFiles', {
        'baseName': _safeFileName(key),
        'jsonContent': jsonEncode(payload.toJson()),
        'lrcContent': payload.syncedLyrics.trim().isEmpty
            ? null
            : payload.syncedLyrics,
      });
    } catch (_) {
      // fallback silencioso al almacenamiento interno
    }
  }
}
