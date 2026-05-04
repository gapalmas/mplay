import '../services/music_scanner.dart';
import '../services/music_cache_service.dart';
import '../../domain/entities/demo_models.dart';

/// Loads the music library: returns cached tracks if valid,
/// otherwise scans the device and caches the result.
class LibraryRepository {
  LibraryRepository()
      : _scanner = MusicScanner(),
        _cache = MusicCacheService();

  final MusicScanner _scanner;
  final MusicCacheService _cache;

  Future<void> initialize() async {
    await _cache.initialize();
  }

  /// Returns all tracks. Uses cache if fresh, else scans device.
  Future<List<DemoTrack>> getAllTracks({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cache.getCachedTracks();
      if (cached != null) {
        print('LibraryRepository: returning ${cached.length} tracks from cache');
        return cached;
      }
    }

    print('LibraryRepository: scanning device music...');
    final tracks = await _scanner.scanTracks();

    if (tracks.isNotEmpty) {
      await _cache.cacheTracks(tracks);
    }

    return tracks;
  }

  /// Groups tracks by album name and returns list of [DemoAlbum]
  List<DemoAlbum> buildAlbums(List<DemoTrack> tracks) {
    final map = <String, List<DemoTrack>>{};
    for (final t in tracks) {
      map.putIfAbsent(t.album, () => []).add(t);
    }

    return map.entries.map((e) {
      final albumTracks = e.value;
      final totalSec = albumTracks.fold(0, (sum, t) => sum + t.durationSeconds);
      final mins = totalSec ~/ 60;
      final secs = totalSec % 60;
      return DemoAlbum(
        name: e.key,
        artist: albumTracks.first.artist,
        year: 0,
        totalDuration: '$mins:${secs.toString().padLeft(2, '0')}',
        tracks: albumTracks,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
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
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> clearCache() async {
    await _cache.clearCache();
  }
}
