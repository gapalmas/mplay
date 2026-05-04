import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/library_repository.dart';
import '../../../data/services/playlist_service.dart';
import '../../../domain/entities/demo_models.dart';
import 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit() : super(const LibraryState());

  final LibraryRepository _repository = LibraryRepository();
  final PlaylistService _playlistService = PlaylistService();

  Future<void> loadLibrary({bool forceRefresh = false}) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _repository.initialize();
      await _playlistService.initialize();
      final tracks = await _repository.getAllTracks(forceRefresh: forceRefresh);

      if (tracks.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          error: 'No se encontraron canciones en el dispositivo.\n'
              'Asegúrate de tener archivos de audio en tu almacenamiento.',
        ));
        return;
      }

      final albums = _repository.buildAlbums(tracks);
      final artists = _repository.buildArtists(tracks);
      final customPlaylists = await _playlistService.loadCustomPlaylists(tracks);
      final playlists = _buildDefaultPlaylists(tracks) + customPlaylists;

      emit(state.copyWith(
        isLoading: false,
        tracks: tracks,
        albums: albums,
        artists: artists,
        playlists: playlists,
        clearError: true,
      ));

      print('LibraryCubit: ${tracks.length} tracks, ${albums.length} albums, ${artists.length} artists');
    } catch (e) {
      print('LibraryCubit: error: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Error al cargar la biblioteca: $e',
      ));
    }
  }

  Future<void> refreshLibrary() async {
    await loadLibrary(forceRefresh: true);
  }

  Future<void> createPlaylist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _playlistService.createPlaylist(trimmed);
    await loadLibrary();
  }

  Future<void> deletePlaylist(String name) async {
    await _playlistService.deletePlaylist(name);
    await loadLibrary();
  }

  Future<void> renamePlaylist(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    await _playlistService.renamePlaylist(oldName, trimmed);
    await loadLibrary();
  }

  Future<void> addTrackToPlaylist(String playlistName, DemoTrack track) async {
    await _playlistService.addTrackToPlaylist(playlistName, track);
    await loadLibrary();
  }

  List<DemoPlaylist> _buildDefaultPlaylists(List<DemoTrack> tracks) {
    if (tracks.isEmpty) return const [];
    final totalSec = tracks.fold(0, (sum, t) => sum + t.durationSeconds);
    final mins = totalSec ~/ 60;
    final secs = totalSec % 60;
    return [
      DemoPlaylist(
        name: 'Todas las canciones',
        trackCount: tracks.length,
        totalDuration: '$mins:${secs.toString().padLeft(2, '0')}',
        tracks: tracks,
      ),
    ];
  }
}
