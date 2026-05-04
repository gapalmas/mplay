import '../../../domain/entities/demo_models.dart';

class LibraryState {
  const LibraryState({
    this.isLoading = true,
    this.tracks = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
    this.error,
  });

  final bool isLoading;
  final List<DemoTrack> tracks;
  final List<DemoAlbum> albums;
  final List<DemoArtist> artists;
  final List<DemoPlaylist> playlists;
  final String? error;

  bool get hasError => error != null;

  LibraryState copyWith({
    bool? isLoading,
    List<DemoTrack>? tracks,
    List<DemoAlbum>? albums,
    List<DemoArtist>? artists,
    List<DemoPlaylist>? playlists,
    String? error,
    bool clearError = false,
  }) {
    return LibraryState(
      isLoading: isLoading ?? this.isLoading,
      tracks: tracks ?? this.tracks,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      playlists: playlists ?? this.playlists,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
