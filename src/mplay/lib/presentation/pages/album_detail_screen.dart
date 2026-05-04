import 'package:flutter/material.dart';

import '../../domain/entities/demo_models.dart';
import '../blocs/library/library_cubit.dart';
import '../blocs/library/library_state.dart';
import '../blocs/player/player_cubit.dart';
import '../widgets/player_mini_player_bar.dart';
import '../widgets/track_artwork.dart';
import 'now_playing_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AlbumDetailScreen extends StatelessWidget {
  const AlbumDetailScreen({super.key, required this.album});

  final DemoAlbum album;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final continuationQueue = _buildAlbumContinuationQueue(
          state.albums,
          album,
        );

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
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                    child: TrackArtwork(
                      track: album.tracks.first,
                      size: 120,
                      radius: 16,
                      iconSize: 54,
                    ),
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
                              onPressed: continuationQueue.isEmpty
                                  ? null
                                  : () {
                                      context.read<PlayerCubit>().playTrack(
                                        continuationQueue.first,
                                        queue: continuationQueue,
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
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: continuationQueue.isEmpty
                                  ? null
                                  : () {
                                      final shuffled = List<DemoTrack>.from(
                                        continuationQueue,
                                      )..shuffle();
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
                      context.read<PlayerCubit>().playTrack(
                            track,
                            queue: continuationQueue,
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

  List<DemoTrack> _buildAlbumContinuationQueue(
    List<DemoAlbum> albums,
    DemoAlbum currentAlbum,
  ) {
    if (albums.isEmpty) {
      return currentAlbum.tracks;
    }

    var startIndex = albums.indexWhere(
      (albumItem) =>
          albumItem.name == currentAlbum.name &&
          albumItem.artist == currentAlbum.artist,
    );

    if (startIndex < 0) {
      startIndex = 0;
    }

    final queue = <DemoTrack>[];
    for (var i = startIndex; i < albums.length; i++) {
      queue.addAll(albums[i].tracks);
    }

    return queue.isEmpty ? currentAlbum.tracks : queue;
  }
}
