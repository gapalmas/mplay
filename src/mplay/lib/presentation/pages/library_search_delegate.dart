import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/demo_models.dart';
import '../blocs/player/player_cubit.dart';
import 'album_detail_screen.dart';
import 'artist_detail_screen.dart';
import 'now_playing_screen.dart';
import 'playlists_screen.dart';
import '../widgets/track_artwork.dart';

class LibrarySearchDelegate extends SearchDelegate<void> {
  LibrarySearchDelegate({
    required this.tracks,
    required this.albums,
    required this.artists,
    required this.playlists,
    required this.searchLabel,
    required this.searchPrompt,
    required this.noResultsLabel,
    required this.songsLabel,
    required this.albumsLabel,
    required this.artistsLabel,
    required this.playlistsLabel,
  });

  final List<DemoTrack> tracks;
  final List<DemoAlbum> albums;
  final List<DemoArtist> artists;
  final List<DemoPlaylist> playlists;
  final String searchLabel;
  final String searchPrompt;
  final String noResultsLabel;
  final String songsLabel;
  final String albumsLabel;
  final String artistsLabel;
  final String playlistsLabel;

  @override
  String? get searchFieldLabel => searchLabel;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.close_rounded),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildBody(context, previewMode: query.trim().isEmpty);
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context, {bool previewMode = false}) {
    final normalized = query.trim().toLowerCase();
    final filteredTracks = _filterTracks(normalized, previewMode);
    final filteredAlbums = _filterAlbums(normalized, previewMode);
    final filteredArtists = _filterArtists(normalized, previewMode);
    final filteredPlaylists = _filterPlaylists(normalized, previewMode);

    final hasAnyResults = filteredTracks.isNotEmpty ||
        filteredAlbums.isNotEmpty ||
        filteredArtists.isNotEmpty ||
        filteredPlaylists.isNotEmpty;

    if (previewMode && normalized.isEmpty && !hasAnyResults) {
      return Center(child: Text(searchPrompt));
    }

    if (!hasAnyResults) {
      return Center(child: Text(noResultsLabel));
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      children: [
        if (filteredTracks.isNotEmpty)
          _ResultSection(
            title: songsLabel,
            children: filteredTracks
                .map((track) => ListTile(
                      leading: TrackArtwork(
                        track: track,
                        size: 40,
                        radius: 20,
                        iconSize: 20,
                      ),
                      title: Text(track.title),
                      subtitle: Text(track.artist),
                      trailing: Text(track.durationLabel),
                      onTap: () {
                        final navigator = Navigator.of(context);
                        context.read<PlayerCubit>().playTrack(track, queue: tracks);
                        close(context, null);
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => const NowPlayingScreen(),
                          ),
                        );
                      },
                    ))
                .toList(),
          ),
        if (filteredAlbums.isNotEmpty)
          _ResultSection(
            title: albumsLabel,
            children: filteredAlbums
                .map((album) => ListTile(
                      leading: TrackArtwork(
                        track: album.tracks.first,
                        size: 40,
                        radius: 12,
                        iconSize: 20,
                      ),
                      title: Text(album.name),
                      subtitle: Text(album.artist),
                      onTap: () {
                        final navigator = Navigator.of(context);
                        close(context, null);
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => AlbumDetailScreen(album: album),
                          ),
                        );
                      },
                    ))
                .toList(),
          ),
        if (filteredArtists.isNotEmpty)
          _ResultSection(
            title: artistsLabel,
            children: filteredArtists
                .map((artist) => ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_rounded),
                      ),
                      title: Text(artist.name),
                      subtitle: Text(
                        '${artist.albums} • ${artist.tracks}',
                      ),
                      onTap: () {
                        final navigator = Navigator.of(context);
                        close(context, null);
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => ArtistDetailScreen(artist: artist),
                          ),
                        );
                      },
                    ))
                .toList(),
          ),
        if (filteredPlaylists.isNotEmpty)
          _ResultSection(
            title: playlistsLabel,
            children: filteredPlaylists
                .map((playlist) => ListTile(
                      leading: playlist.tracks.isNotEmpty
                          ? TrackArtwork(
                              track: playlist.tracks.first,
                              size: 40,
                              radius: 20,
                              iconSize: 20,
                            )
                          : const CircleAvatar(
                              child: Icon(Icons.queue_music_rounded),
                            ),
                      title: Text(playlist.name),
                      subtitle: Text('${playlist.trackCount}'),
                      onTap: () {
                        final navigator = Navigator.of(context);
                        close(context, null);
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailScreen(
                              playlistName: playlist.name,
                            ),
                          ),
                        );
                      },
                    ))
                .toList(),
          ),
      ],
    );
  }

  List<DemoTrack> _filterTracks(String normalized, bool previewMode) {
    final source = normalized.isEmpty
        ? tracks.take(8).toList()
        : tracks.where(
            (track) => _matchesAny(
              normalized,
              [track.title, track.artist, track.album],
            ),
          );
    return source.toList();
  }

  List<DemoAlbum> _filterAlbums(String normalized, bool previewMode) {
    final source = normalized.isEmpty
        ? albums.take(6).toList()
        : albums.where(
            (album) => _matchesAny(normalized, [album.name, album.artist]),
          );
    return source.toList();
  }

  List<DemoArtist> _filterArtists(String normalized, bool previewMode) {
    final source = normalized.isEmpty
        ? artists.take(6).toList()
        : artists.where((artist) => _matchesAny(normalized, [artist.name]));
    return source.toList();
  }

  List<DemoPlaylist> _filterPlaylists(String normalized, bool previewMode) {
    final source = normalized.isEmpty
        ? playlists.take(6).toList()
        : playlists.where((playlist) => _matchesAny(normalized, [playlist.name]));
    return source.toList();
  }

  bool _matchesAny(String normalized, List<String> values) {
    return values.any((value) => value.toLowerCase().contains(normalized));
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}