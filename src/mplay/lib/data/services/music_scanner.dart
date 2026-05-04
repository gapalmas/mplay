import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to scan and retrieve audio files from device
class MusicScanner {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Request permissions for accessing music files
  Future<bool> requestPermissions() async {
    final status = await Permission.audio.request();
    return status.isGranted;
  }

  /// Check if permission is already granted
  Future<bool> hasPermission() async {
    return await Permission.audio.isDenied == false;
  }

  /// Scan all songs on device
  Future<List<SongModel>> querySongs() async {
    try {
      bool permissionGranted = await requestPermissions();
      if (!permissionGranted) {
        print('Permission denied for accessing audio files');
        return [];
      }

      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
      );

      print('Found ${songs.length} songs on device');
      return songs;
    } catch (e) {
      print('Error querying songs: $e');
      return [];
    }
  }

  /// Get all albums available
  Future<List<AlbumModel>> queryAlbums() async {
    try {
      final albums = await _audioQuery.queryAlbums(
        sortType: AlbumSortType.ALBUM,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
      return albums;
    } catch (e) {
      print('Error querying albums: $e');
      return [];
    }
  }

  /// Get all artists available
  Future<List<ArtistModel>> queryArtists() async {
    try {
      final artists = await _audioQuery.queryArtists(
        sortType: ArtistSortType.ARTIST,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
      return artists;
    } catch (e) {
      print('Error querying artists: $e');
      return [];
    }
  }

  /// Search songs by artist
  Future<List<SongModel>> searchSongsByArtist(String artist) async {
    try {
      final allSongs = await querySongs();
      return allSongs
          .where((song) => song.artist?.toLowerCase().contains(artist.toLowerCase()) ?? false)
          .toList();
    } catch (e) {
      print('Error searching songs by artist: $e');
      return [];
    }
  }

  /// Search songs by album
  Future<List<SongModel>> searchSongsByAlbum(String album) async {
    try {
      final allSongs = await querySongs();
      return allSongs
          .where((song) => song.album?.toLowerCase().contains(album.toLowerCase()) ?? false)
          .toList();
    } catch (e) {
      print('Error searching songs by album: $e');
      return [];
    }
  }
}
