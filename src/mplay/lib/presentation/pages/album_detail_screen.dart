import 'package:flutter/material.dart';

import '../../domain/entities/demo_models.dart';
import '../blocs/player/player_cubit.dart';
import '../widgets/player_mini_player_bar.dart';
import 'now_playing_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AlbumDetailScreen extends StatelessWidget {
  const AlbumDetailScreen({super.key, required this.album});

  final DemoAlbum album;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Álbum')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: const Icon(Icons.album_rounded, size: 54),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(album.artist),
                    const SizedBox(height: 8),
                    Text(
                      '${album.year} • ${album.tracks.length} canciones • ${album.totalDuration}',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Reproducir'),
                        ),
                        const SizedBox(width: 8),
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
            ],
          ),
          const SizedBox(height: 18),
          ...album.tracks.asMap().entries.map((entry) {
            final index = entry.key;
            final track = entry.value;
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(track.title),
                trailing: Text(track.durationLabel),
                onTap: () {
                  context.read<PlayerCubit>().playTrack(track, queue: album.tracks);
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
  }
}
