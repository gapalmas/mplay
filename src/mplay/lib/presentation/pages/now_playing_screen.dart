import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/player/player_cubit.dart';
import '../blocs/player/player_state.dart';

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
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer,
                              Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.album_rounded, size: 120),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      track.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${track.artist} • ${track.format} • ${track.bitrateKbps} kbps',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_border_rounded),
                        ),
                        IconButton(
                          onPressed: () {},
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
                          onPressed: () {},
                          icon: const Icon(Icons.shuffle_rounded),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: context.read<PlayerCubit>().togglePlayPause,
                          icon: Icon(
                            state.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(state.isPlaying ? 'Pause' : 'Play'),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.repeat_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.volume_down_rounded),
                        Expanded(
                          child: Slider(value: 1, max: 1, onChanged: (_) {}),
                        ),
                        const Text('100%'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      tabs: const [Tab(text: 'Letras'), Tab(text: 'Cola')],
                    ),
                    SizedBox(
                      height: 220,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          ListView(
                            children: const [
                              ListTile(title: Text('Is this the real life?')),
                              ListTile(title: Text('Is this just fantasy?')),
                              ListTile(
                                title: Text(
                                  'Caught in a landslide',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'No escape from reality.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
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
                                leading: CircleAvatar(child: Text('${index + 1}')),
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
}
