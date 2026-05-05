import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/demo_models.dart';
import '../blocs/library/library_cubit.dart';
import '../blocs/library/library_state.dart';
import '../blocs/player/player_cubit.dart';
import '../widgets/player_mini_player_bar.dart';
import '../widgets/track_artwork.dart';
import 'now_playing_screen.dart';

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
        final albumMetadata = _buildAlbumMetadata(album);

        return Scaffold(
          appBar: AppBar(title: const Text('Álbum')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final coverSize = constraints.maxWidth < 360 ? 96.0 : 120.0;

                  return Column(
                    children: [
                      Container(
                        width: coverSize,
                        height: coverSize,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: TrackArtwork(
                          track: album.tracks.first,
                          size: coverSize,
                          radius: 6,
                          iconSize: coverSize * 0.45,
                          showBackground: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        album.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        album.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        albumMetadata,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                                          builder: (_) =>
                                              const NowPlayingScreen(),
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
                                          builder: (_) =>
                                              const NowPlayingScreen(),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.shuffle_rounded),
                              label: const Text('Aleatorio'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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

  String _buildAlbumMetadata(DemoAlbum album) {
    final parts = <String>[];

    if (album.year > 0) {
      parts.add('${album.year}');
    }

    parts.add('${album.tracks.length} canciones');
    parts.add(
      _formatDurationLabel(
        album.tracks.fold(0, (sum, track) => sum + track.durationSeconds),
      ),
    );

    return parts.join(' • ');
  }

  String _formatDurationLabel(int totalSeconds) {
    if (totalSeconds <= 0) {
      return '0m';
    }

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    if (minutes > 0) {
      return '${minutes}m';
    }

    return '1m';
  }
}
