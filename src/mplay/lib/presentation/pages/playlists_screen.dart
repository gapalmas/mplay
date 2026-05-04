import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/demo_models.dart';
import '../blocs/library/library_cubit.dart';
import '../blocs/library/library_state.dart';
import '../blocs/player/player_cubit.dart';
import '../widgets/player_mini_player_bar.dart';
import 'now_playing_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      body: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          final playlists = state.playlists;
          if (playlists.isEmpty) {
            return const Center(child: Text('No hay playlists disponibles'));
          }

          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.library_music_rounded),
                  ),
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.trackCount} canciones'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailScreen(
                          playlistName: playlist.name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlaylistDialog(context),
        icon: const Icon(Icons.playlist_add_rounded),
        label: const Text('Nueva playlist'),
      ),
      bottomNavigationBar: const PlayerMiniPlayerBar(),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva playlist'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nombre de la playlist',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    if (name != null && name.trim().isNotEmpty && context.mounted) {
      await context.read<LibraryCubit>().createPlaylist(name.trim());
    }
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlistName,
  });

  final String playlistName;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        DemoPlaylist? playlist;
        for (final item in state.playlists) {
          if (item.name == playlistName) {
            playlist = item;
            break;
          }
        }
        if (playlist == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Playlist')),
            body: const Center(child: Text('Playlist no encontrada')),
          );
        }
        final currentPlaylist = playlist;

        return Scaffold(
          appBar: AppBar(
            title: Text(currentPlaylist.name),
            actions: [
              IconButton(
                onPressed: () => _showRenameDialog(context, currentPlaylist.name),
                icon: const Icon(Icons.edit_rounded),
              ),
              IconButton(
                onPressed: currentPlaylist.name == 'Todas las canciones'
                    ? null
                    : () async {
                        await context.read<LibraryCubit>().deletePlaylist(currentPlaylist.name);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                icon: const Icon(Icons.delete_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentPlaylist.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('${currentPlaylist.trackCount} canciones • ${currentPlaylist.totalDuration}'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: currentPlaylist.tracks.isEmpty
                                ? null
                                : () {
                                    context.read<PlayerCubit>().playTrack(
                                      currentPlaylist.tracks.first,
                                      queue: currentPlaylist.tracks,
                                    );
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const NowPlayingScreen(),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Reproducir'),
                          ),
                          OutlinedButton.icon(
                            onPressed: currentPlaylist.tracks.isEmpty
                                ? null
                                : () {
                                    final shuffled = List<DemoTrack>.from(currentPlaylist.tracks)..shuffle();
                                    context.read<PlayerCubit>().playTrack(
                                      shuffled.first,
                                      queue: shuffled,
                                    );
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const NowPlayingScreen(),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.shuffle_rounded),
                            label: const Text('Aleatorio'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ...currentPlaylist.tracks.asMap().entries.map((entry) {
                final index = entry.key;
                final track = entry.value;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(track.title),
                    subtitle: Text(track.artist),
                    trailing: Text(track.durationLabel),
                    onTap: () {
                      context.read<PlayerCubit>().playTrack(
                        track,
                        queue: currentPlaylist.tracks,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NowPlayingScreen(),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
          bottomNavigationBar: const PlayerMiniPlayerBar(),
        );
      },
    );
  }

  Future<void> _showRenameDialog(BuildContext context, String oldName) async {
    if (oldName == 'Todas las canciones') return;

    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renombrar playlist'),
          content: TextField(
            controller: controller,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.trim().isNotEmpty && context.mounted) {
      await context.read<LibraryCubit>().renamePlaylist(oldName, newName.trim());
    }
  }
}
