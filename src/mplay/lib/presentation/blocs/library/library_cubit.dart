import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/demo/demo_data.dart';
import '../../../data/repositories/library_repository.dart';
import 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final LibraryRepository _libraryRepository = LibraryRepository();

  LibraryCubit() : super(const LibraryState());

  Future<void> loadLibrary() async {
    emit(state.copyWith(isLoading: true));
    
    try {
      // Try to load real music from device
      final tracks = await _libraryRepository.getAllTracks();
      final albums = await _libraryRepository.getAllAlbums();
      final artists = await _libraryRepository.getAllArtists();

      // If no tracks found, fallback to demo data
      if (tracks.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            tracks: DemoData.tracks,
            albums: DemoData.albums,
            artists: DemoData.artists,
            playlists: DemoData.playlists,
          ),
        );
        print('Using demo data - no music found on device');
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            tracks: tracks,
            albums: albums,
            artists: artists,
            playlists: DemoData.playlists, // Keep demo playlists for now
          ),
        );
        print('Loaded ${tracks.length} tracks, ${albums.length} albums, ${artists.length} artists');
      }
    } catch (e) {
      print('Error loading library: $e');
      // Fallback to demo data on error
      emit(
        state.copyWith(
          isLoading: false,
          tracks: DemoData.tracks,
          albums: DemoData.albums,
          artists: DemoData.artists,
          playlists: DemoData.playlists,
        ),
      );
    }
  }
}
