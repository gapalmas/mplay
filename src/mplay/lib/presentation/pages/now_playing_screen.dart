import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/demo_models.dart';
import '../blocs/library/library_cubit.dart';
import '../blocs/player/player_cubit.dart';
import '../blocs/player/player_state.dart';
import '../blocs/player/player_state.dart' as player_state;
import '../widgets/marquee_text.dart';
import '../widgets/track_artwork.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late double _position;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _position = 0;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        if (!state.hasTrack || state.currentTrack == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Now Playing')),
            body: const Center(child: Text('No hay canción en reproducción')),
          );
        }
        final track = state.currentTrack!;
        final maxPosition = state.maxPositionSeconds;
        _position = state.positionSeconds;
        final primaryColor = Theme.of(context).colorScheme.primary;
        return Scaffold(
          appBar: AppBar(title: const Text('Now Playing')),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: TrackArtwork(
                              track: track,
                              size: (MediaQuery.sizeOf(context).width - 40)
                                  .clamp(120.0, 420.0)
                                  .toDouble(),
                              radius: 24,
                              iconSize: 120,
                              querySize: 1400,
                              artworkFilterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: MarqueeText(
                            text: track.nowPlayingTickerLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                            gap: 56,
                            velocity: 34,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.favorite_border_rounded),
                            ),
                            PopupMenuButton<_NowPlayingMenuAction>(
                              onSelected: (action) {
                                switch (action) {
                                  case _NowPlayingMenuAction.addToPlaylist:
                                    _showAddToPlaylistMenu(context, track);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: _NowPlayingMenuAction.addToPlaylist,
                                  child: ListTile(
                                    leading: Icon(Icons.playlist_add_rounded),
                                    title: Text('Agregar a playlist'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                              icon: const Icon(Icons.more_vert_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _position.clamp(0, maxPosition),
                          max: maxPosition,
                          onChanged: (value) {
                            context.read<PlayerCubit>().seek(value);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_secondsToLabel(_position)),
                              Text(track.durationLabel),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: context
                                  .read<PlayerCubit>()
                                  .toggleShuffle,
                              icon: const Icon(Icons.shuffle_rounded),
                              color: state.isShuffleEnabled
                                  ? primaryColor
                                  : null,
                              tooltip: state.isShuffleEnabled
                                  ? 'Aleatorio activado'
                                  : 'Aleatorio desactivado',
                            ),
                            IconButton(
                              onPressed: context
                                  .read<PlayerCubit>()
                                  .skipPrevious,
                              icon: const Icon(Icons.skip_previous_rounded),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: context
                                  .read<PlayerCubit>()
                                  .togglePlayPause,
                              icon: Icon(
                                state.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                              label: Text(state.isPlaying ? 'Pause' : 'Play'),
                            ),
                            IconButton(
                              onPressed: context.read<PlayerCubit>().skipNext,
                              icon: const Icon(Icons.skip_next_rounded),
                            ),
                            IconButton(
                              onPressed: context
                                  .read<PlayerCubit>()
                                  .cycleRepeatMode,
                              icon: Icon(
                                state.repeatMode == player_state.RepeatMode.one
                                    ? Icons.repeat_one_rounded
                                    : Icons.repeat_rounded,
                              ),
                              color:
                                  state.repeatMode ==
                                      player_state.RepeatMode.off
                                  ? null
                                  : primaryColor,
                              tooltip: switch (state.repeatMode) {
                                player_state.RepeatMode.off =>
                                  'Repetir desactivado',
                                player_state.RepeatMode.all => 'Repetir cola',
                                player_state.RepeatMode.one =>
                                  'Repetir canción',
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.volume_down_rounded),
                            Expanded(
                              child: Slider(
                                value: state.volume.clamp(0.0, 1.0),
                                max: 1,
                                onChanged: (value) {
                                  context.read<PlayerCubit>().setVolume(value);
                                },
                              ),
                            ),
                            Text('${(state.volume * 100).round()}%'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Letras'),
                            Tab(text: 'Cola'),
                          ],
                        ),
                        SizedBox(
                          height: 220,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              ListView(
                                children: const [
                                  ListTile(
                                    title: Text('Is this the real life?'),
                                  ),
                                  ListTile(
                                    title: Text('Is this just fantasy?'),
                                  ),
                                  ListTile(
                                    title: Text(
                                      'Caught in a landslide',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ListTile(
                                    title: Text(
                                      'No escape from reality.',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ListTile(title: Text('Open your eyes...')),
                                ],
                              ),
                              ListView.builder(
                                itemCount: state.queue.length,
                                itemBuilder: (context, index) {
                                  final item = state.queue[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text('${index + 1}'),
                                    ),
                                    title: Text(item.title),
                                    subtitle: Text(item.artist),
                                    trailing: Text(item.durationLabel),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _secondsToLabel(double seconds) {
    final total = seconds.floor();
    final mins = total ~/ 60;
    final secs = total % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _showAddToPlaylistMenu(
    BuildContext context,
    DemoTrack track,
  ) async {
    final playlists = context
        .read<LibraryCubit>()
        .state
        .playlists
        .where((playlist) => playlist.name != 'Todas las canciones')
        .toList();

    if (playlists.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay playlists personalizadas disponibles.'),
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
              const ListTile(title: Text('Agregar a playlist')),
              ...playlists.map(
                (playlist) => ListTile(
                  leading: const Icon(Icons.queue_music_rounded),
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.trackCount} canciones'),
                  onTap: () => Navigator.pop(sheetContext, playlist.name),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || !context.mounted) return;

    await context.read<LibraryCubit>().addTrackToPlaylist(selected, track);

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Canción añadida a "$selected"')));
  }
}

enum _NowPlayingMenuAction { addToPlaylist }
