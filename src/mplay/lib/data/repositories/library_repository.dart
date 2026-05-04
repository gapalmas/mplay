import 'package:on_audio_query/on_audio_query.dart';

import '../../domain/entities/demo_models.dart';
import '../services/music_scanner.dart';

class LibraryRepository {
  final MusicScanner _musicScanner = MusicScanner();

  /// Get all available tracks from device
  Future<List<DemoTrack>> getAllTracks() async {
    final songs = await _musicScanner.querySongs();
    return _convertSongsToTracks(songs);
  }

  /// Get all albums from device
  Future<List<DemoAlbum>> getAllAlbums() async {
    final albums = await _musicScanner.queryAlbums();
    final tracks = await getAllTracks();

    return albums.map((album) {
      final albumTracks = tracks
          .where((track) => track.album.toLowerCase() == album.album.toLowerCase())
          .toList();

      return DemoAlbum(
        name: album.album,
        artist: album.artist ?? 'Unknown Artist',
        year: album.numOfSongs > 0 ? 2024 : 2024,
        totalDuration: _calculateDuration(albumTracks),
        tracks: albumTracks,
      );
    }).toList();
  }

  /// Get all artists from device
  Future<List<DemoArtist>> getAllArtists() async {
    final artists = await _musicScanner.queryArtists();
    final songs = await _musicScanner.querySongs();

    return artists.map((artist) {
      final artistSongs = songs
          .where((song) =>
              (song.artist ?? '').toLowerCase() == artist.artist.toLowerCase())
          .toList();

      return DemoArtist(
        name: artist.artist,
        albums: 0,
        tracks: artistSongs.length,
      );
    }).toList();
  }

  /// Convert SongModel from on_audio_query to DemoTrack
  List<DemoTrack> _convertSongsToTracks(List<SongModel> songs) {
    return songs.map((song) {
      final duration = Duration(milliseconds: song.duration ?? 0);
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      final durationLabel = '$minutes:${seconds.toString().padLeft(2, '0')}';

      return DemoTrack(
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        album: song.album ?? 'Unknown Album',
        durationLabel: durationLabel,
        durationSeconds: (song.duration ?? 0) ~/ 1000,
        format: _getAudioFormat(song.data),
        bitrateKbps: 320,
        filePath: song.data,
        uri: song.uri,
      );
    }).toList();
  }

  String _getAudioFormat(String filePath) {
    if (filePath.endsWith('.flac')) return 'FLAC';
    if (filePath.endsWith('.mp3')) return 'MP3';
    if (filePath.endsWith('.aac')) return 'AAC';
    if (filePath.endsWith('.m4a')) return 'M4A';
    if (filePath.endsWith('.wav')) return 'WAV';
    if (filePath.endsWith('.ogg')) return 'OGG';
    return 'UNKNOWN';
  }

  String _calculateDuration(List<DemoTrack> tracks) {
    if (tracks.isEmpty) return '0m';
    
    int totalSeconds = tracks.fold<int>(0, (sum, track) => sum + track.durationSeconds);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
