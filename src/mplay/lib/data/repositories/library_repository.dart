import '../services/music_scanner.dart';
import '../services/music_cache_service.dart';
import '../../domain/entities/demo_models.dart';

/// Loads the music library: returns cached tracks if valid,
/// otherwise scans the device and caches the result.
class LibraryRepository {
  LibraryRepository() : _scanner = MusicScanner(), _cache = MusicCacheService();

  final MusicScanner _scanner;
  final MusicCacheService _cache;

  Future<void> initialize() async {
    await _cache.initialize();
  }

  /// Returns all tracks. Uses cache if fresh, else scans device.
  Future<List<DemoTrack>> getAllTracks({bool forceRefresh = false}) async {
    final cached = _cache.getCachedTracks();

    if (!forceRefresh) {
      if (cached != null) {
        print(
          'LibraryRepository: returning ${cached.length} tracks from cache',
        );
        return cached;
      }
    }

    print('LibraryRepository: scanning device music...');
    final tracks = await _scanner.scanTracks();

    final hasChanges = _hasLibraryChanges(cached, tracks);
    if (tracks.isNotEmpty && (forceRefresh || hasChanges || cached == null)) {
      await _cache.cacheTracks(tracks);
    } else if (!hasChanges && cached != null) {
      print('LibraryRepository: no changes detected, keeping cached library');
      return cached;
    }

    return tracks;
  }

  bool _hasLibraryChanges(
    List<DemoTrack>? oldTracks,
    List<DemoTrack> newTracks,
  ) {
    if (oldTracks == null) return true;
    if (oldTracks.length != newTracks.length) return true;

    final oldKeys = oldTracks.map(_trackIdentityKey).toSet();
    final newKeys = newTracks.map(_trackIdentityKey).toSet();
    if (oldKeys.length != newKeys.length) return true;

    for (final key in oldKeys) {
      if (!newKeys.contains(key)) {
        return true;
      }
    }

    return false;
  }

  String _trackIdentityKey(DemoTrack track) {
    final songId = track.songId ?? 0;
    final path = (track.filePath ?? '').toLowerCase();
    final duration = track.durationSeconds;
    return '$songId|$path|$duration';
  }

  /// Groups tracks by album name and returns list of [DemoAlbum]
  List<DemoAlbum> buildAlbums(List<DemoTrack> tracks) {
    final map = <String, List<DemoTrack>>{};
    for (final t in tracks) {
      final key = _albumGroupingKey(t);
      map.putIfAbsent(key, () => []).add(t);
    }

    return map.entries.map((e) {
      final albumTracks = e.value;
      final totalSec = albumTracks.fold(0, (sum, t) => sum + t.durationSeconds);
      final mins = totalSec ~/ 60;
      final secs = totalSec % 60;

      final folderName = _folderNameFromPath(e.key);
      final albumName = folderName?.isNotEmpty == true
          ? folderName!
          : albumTracks.first.album;

      return DemoAlbum(
        name: albumName,
        artist: albumTracks.first.artist,
        year: 0,
        totalDuration: '$mins:${secs.toString().padLeft(2, '0')}',
        tracks: albumTracks,
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Groups tracks by artist name and returns list of [DemoArtist]
  List<DemoArtist> buildArtists(List<DemoTrack> tracks) {
    final byArtist = <String, List<DemoTrack>>{};
    for (final t in tracks) {
      byArtist.putIfAbsent(t.artist, () => []).add(t);
    }

    return byArtist.entries.map((e) {
      final artistTracks = e.value;
      final albumCount = artistTracks.map((t) => t.album).toSet().length;
      return DemoArtist(
        name: e.key,
        albums: albumCount,
        tracks: artistTracks.length,
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> clearCache() async {
    await _cache.clearCache();
  }

  String _albumGroupingKey(DemoTrack track) {
    final path = track.filePath;
    if (path != null && path.isNotEmpty) {
      final normalized = path.replaceAll('\\', '/');
      final split = normalized.split('/');
      if (split.length > 1) {
        return split.sublist(0, split.length - 1).join('/');
      }
    }
    return 'meta:${track.album.toLowerCase()}';
  }

  String? _folderNameFromPath(String key) {
    if (key.startsWith('meta:')) return null;
    final normalized = key.replaceAll('\\', '/');
    final split = normalized.split('/').where((p) => p.isNotEmpty).toList();
    if (split.isEmpty) return null;
    return split.last;
  }
}
