import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/demo_models.dart';
import '../blocs/library/library_cubit.dart';
import '../blocs/library/library_state.dart';
import '../blocs/player/player_cubit.dart';
import 'album_detail_screen.dart';
import 'artist_detail_screen.dart';
import 'backup_restore_screen.dart';
import 'equalizer_screen.dart';
import 'now_playing_screen.dart';
import 'playlists_screen.dart';
import 'settings_screen.dart';
import '../widgets/player_mini_player_bar.dart';
import '../widgets/track_artwork.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final TabController _libraryTabs;

  @override
  void initState() {
    super.initState();
    _libraryTabs = TabController(length: 4, vsync: this);
    // Load library when HomeScreen is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LibraryCubit>().loadLibrary();
    });
  }

  @override
  void dispose() {
    _libraryTabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.library_music_rounded, size: 72),
                  const SizedBox(height: 24),
                  const Text('Cargando biblioteca de música...'),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        if (state.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.music_off_rounded, size: 72,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 24),
                    Text(state.error ?? 'Error desconocido',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<LibraryCubit>().loadLibrary(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final tracks = state.tracks;
        final albums = state.albums;
        final artists = state.artists;
        final playlists = state.playlists;

        return Scaffold(
          appBar: AppBar(
            title: const Text('mplay'),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
              PopupMenuButton<_TopMenu>(
                onSelected: (selection) {
                  switch (selection) {
                    case _TopMenu.equalizer:
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EqualizerScreen()),
                      );
                    case _TopMenu.settings:
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    case _TopMenu.backup:
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BackupRestoreScreen(),
                        ),
                      );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _TopMenu.equalizer,
                    child: Text('Ecualizador'),
                  ),
                  PopupMenuItem(value: _TopMenu.settings, child: Text('Ajustes')),
                  PopupMenuItem(
                    value: _TopMenu.backup,
                    child: Text('Backup / Restore'),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _libraryTabs,
              tabs: const [
                Tab(text: 'Canciones'),
                Tab(text: 'Álbumes'),
                Tab(text: 'Artistas'),
                Tab(text: 'Playlists'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _libraryTabs,
            children: [
          ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return Card(
                child: ListTile(
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
                    context.read<PlayerCubit>().playTrack(track, queue: tracks);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NowPlayingScreen(),
                      ),
                    );
                  },
                  onLongPress: () {
                    _showAddToPlaylistSheet(
                      context: context,
                      track: track,
                      playlists: playlists,
                    );
                  },
                ),
              );
            },
          ),
          GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.95,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AlbumDetailScreen(album: album),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: TrackArtwork(
                              track: album.tracks.first,
                              size: 220,
                              radius: 12,
                              iconSize: 48,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          album.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          album.artist,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          ListView.builder(
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                  title: Text(artist.name),
                  subtitle: Text(
                    '${artist.albums} álbumes • ${artist.tracks} canciones',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ArtistDetailScreen(artist: artist),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.queue_music_rounded),
                  ),
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.trackCount} canciones'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PlaylistsScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
            ],
          ),
          bottomNavigationBar: const PlayerMiniPlayerBar(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              _libraryTabs.animateTo(3);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PlaylistsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Playlist'),
          ),
        );
      },
    );
  }

  Future<void> _showAddToPlaylistSheet({
    required BuildContext context,
    required DemoTrack track,
    required List<DemoPlaylist> playlists,
  }) async {
    final customPlaylists = playlists
        .where((playlist) => playlist.name != 'Todas las canciones')
        .toList();

    if (customPlaylists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero crea una playlist personalizada.'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Añadir a playlist')),
              ...customPlaylists.map(
                (playlist) => ListTile(
                  leading: const Icon(Icons.playlist_add_rounded),
                  title: Text(playlist.name),
                  onTap: () => Navigator.pop(sheetContext, playlist.name),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && context.mounted) {
      await context.read<LibraryCubit>().addTrackToPlaylist(selected, track);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Añadida a "$selected"')),
        );
      }
    }
  }
}

enum _TopMenu { equalizer, settings, backup }
