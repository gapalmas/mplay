import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/demo_models.dart';
import '../blocs/library/library_cubit.dart';
import '../blocs/library/library_state.dart';
import '../blocs/player/player_cubit.dart';
import '../widgets/player_mini_player_bar.dart';
import '../widgets/track_artwork.dart';
import 'album_detail_screen.dart';
import 'now_playing_screen.dart';

class ArtistDetailScreen extends StatelessWidget {
  const ArtistDetailScreen({super.key, required this.artist});

  final DemoArtist artist;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, libraryState) {
        final artistTracks = libraryState.tracks
            .where((t) => t.artist == artist.name)
            .toList();
        final artistAlbums = libraryState.albums
            .where((a) => a.artist == artist.name)
            .toList();
        final artistMetadata = _buildArtistMetadata(
          albumCount: artistAlbums.length,
          trackCount: artistTracks.length,
          totalSeconds: artistTracks.fold(
            0,
            (sum, track) => sum + track.durationSeconds,
          ),
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Artista')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final avatarRadius = constraints.maxWidth < 360
                          ? 30.0
                          : 36.0;

                      return Column(
                        children: [
                          CircleAvatar(
                            radius: avatarRadius,
                            child: Icon(
                              Icons.person_rounded,
                              size: avatarRadius,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            artist.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            artistMetadata,
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
                                  onPressed: artistTracks.isEmpty
                                      ? null
                                      : () {
                                          context.read<PlayerCubit>().playTrack(
                                            artistTracks.first,
                                            queue: artistTracks,
                                          );
                                        },
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Reproducir'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: artistTracks.isEmpty
                                      ? null
                                      : () {
                                          final shuffled = List<DemoTrack>.from(
                                            artistTracks,
                                          )..shuffle();
                                          context.read<PlayerCubit>().playTrack(
                                            shuffled.first,
                                            queue: shuffled,
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
                ),
              ),
              if (artistAlbums.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Álbumes', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                SizedBox(
                  height: 155,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: artistAlbums.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final album = artistAlbums[index];
                      return SizedBox(
                        width: 130,
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AlbumDetailScreen(album: album),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: SizedBox.square(
                                        dimension: 100,
                                        child: TrackArtwork(
                                          track: album.tracks.first,
                                          size: 100,
                                          radius: 6,
                                          iconSize: 32,
                                          showBackground: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    album.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (artistTracks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Canciones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...artistTracks
                    .take(5)
                    .map(
                      (track) => Card(
                        child: ListTile(
                          leading: TrackArtwork(
                            track: track,
                            size: 40,
                            radius: 20,
                            iconSize: 20,
                          ),
                          title: Text(track.title),
                          subtitle: Text(track.album),
                          trailing: Text(track.durationLabel),
                          onTap: () {
                            context.read<PlayerCubit>().playTrack(
                              track,
                              queue: artistTracks,
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NowPlayingScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
              ],
            ],
          ),
          bottomNavigationBar: const PlayerMiniPlayerBar(),
        );
      },
    );
  }

  String _buildArtistMetadata({
    required int albumCount,
    required int trackCount,
    required int totalSeconds,
  }) {
    return [
      '$albumCount álbumes',
      '$trackCount canciones',
      _formatDurationLabel(totalSeconds),
    ].join(' • ');
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
