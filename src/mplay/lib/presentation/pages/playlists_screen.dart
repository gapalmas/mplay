import 'package:flutter/material.dart';

import '../../domain/entities/demo_models.dart';
import '../widgets/player_mini_player_bar.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({
    super.key,
    required this.playlists,
    required this.initialPlaylist,
  });

  final List<DemoPlaylist> playlists;
  final DemoPlaylist initialPlaylist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      body: ListView.builder(
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
                    builder: (_) => PlaylistDetailScreen(playlist: playlist),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.playlist_add_rounded),
        label: const Text('Nueva playlist'),
      ),
      bottomNavigationBar: const PlayerMiniPlayerBar(),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.playlist});

  final DemoPlaylist playlist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit_rounded)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.delete_rounded)),
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
                  Text(playlist.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('${playlist.trackCount} canciones • ${playlist.totalDuration}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Reproducir'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
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
          ...playlist.tracks.asMap().entries.map((entry) {
            final index = entry.key;
            final track = entry.value;
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(track.title),
                subtitle: Text(track.artist),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(track.durationLabel),
                    const SizedBox(width: 8),
                    const Icon(Icons.drag_indicator_rounded),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: const PlayerMiniPlayerBar(),
    );
  }
}
