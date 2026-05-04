import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/demo/demo_data.dart';
import 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit() : super(const LibraryState());

  void loadLibrary() {
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
