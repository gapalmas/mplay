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
        // Filter tracks and albums from the real library by artist name
        final artistTracks = libraryState.tracks
            .where((t) => t.artist == artist.name)
            .toList();
        final artistAlbums = libraryState.albums
            .where((a) => a.artist == artist.name)
            .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Artista')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        child: Icon(Icons.person_rounded, size: 36),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artist.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text('${artistAlbums.length} álbumes • ${artistTracks.length} canciones'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                FilledButton.icon(
                                  onPressed: artistTracks.isEmpty ? null : () {
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
                                  onPressed: artistTracks.isEmpty ? null : () {
                                    final shuffled = List<DemoTrack>.from(artistTracks)..shuffle();
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
                          ],
                        ),
                      ),
                    ],
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
                                  builder: (_) => AlbumDetailScreen(album: album),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: TrackArtwork(
                                      track: album.tracks.first,
                                      size: 120,
                                      radius: 10,
                                      iconSize: 32,
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
                ...artistTracks.take(5).map(
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
}
