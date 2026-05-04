import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/library_repository.dart';
import 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit() : super(const LibraryState());

  final LibraryRepository _repository = LibraryRepository();

  Future<void> loadLibrary({bool forceRefresh = false}) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _repository.initialize();
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

      emit(state.copyWith(
        isLoading: false,
        tracks: tracks,
        albums: albums,
        artists: artists,
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
}
