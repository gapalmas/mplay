import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../data/services/lyrics_service.dart';
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
  final LyricsService _lyricsService = LyricsService();
  final ScrollController _lyricsScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  final Map<String, Future<LyricsPayload?>> _lyricsFutureCache = {};
  Color? _dominantColor;
  String _lastTrackId = '';
  String _lastLyricsTrackKey = '';
  int _lastLyricsIndex = -1;

  static const double _lyricsItemExtent = 62;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _position = 0;
  }

  @override
  void dispose() {
    _lyricsScrollController.dispose();
    _mainScrollController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateDominantColor(DemoTrack track) async {
    final trackId = '${track.songId ?? '${track.title}${track.artist}'}';

    if (trackId == _lastTrackId && _dominantColor != null) {
      return;
    }
    _lastTrackId = trackId;

    try {
      if (track.songId != null && track.songId! > 0) {
        // Obtener la imagen del archivo local
        final onAudioQuery = OnAudioQuery();
        final artworkBytes = await onAudioQuery.queryArtwork(
          track.songId!,
          ArtworkType.AUDIO,
        );

        if (artworkBytes != null && mounted) {
          final imageProvider = MemoryImage(artworkBytes);
          final paletteGenerator = await PaletteGenerator.fromImageProvider(
            imageProvider,
            size: const Size(200, 200),
          );

          final dominantColor =
              paletteGenerator.dominantColor?.color ??
              paletteGenerator.vibrantColor?.color ??
              paletteGenerator.mutedColor?.color ??
              Theme.of(context).colorScheme.surface;

          if (mounted) {
            setState(() {
              _dominantColor = dominantColor;
            });
          }
          return;
        }
      }

      // Fallback si no hay songId o artwork
      if (mounted) {
        setState(() {
          _dominantColor = Theme.of(context).colorScheme.surface;
        });
      }
    } catch (e) {
      // Fallback seguro
      if (mounted) {
        setState(() {
          _dominantColor = Theme.of(context).colorScheme.surface;
        });
      }
    }
  }

  bool _isColorLight(Color color) {
    return color.computeLuminance() > 0.5;
  }

  void _scrollToTabsContent() {
    if (!_mainScrollController.hasClients) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mainScrollController.hasClients) {
        return;
      }
      _mainScrollController.animateTo(
        _mainScrollController.position.maxScrollExtent * 1.25,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onTabChanged() {
    // Cambio de tab por swipe o por toque en tab diferente
    if (_tabController.indexIsChanging) {
      _scrollToTabsContent();
    }

    // Cuando se selecciona tab Letras, resetear índice para sincronizar scroll
    if (_tabController.index == 0 && _tabController.indexIsChanging) {
      _lastLyricsIndex = -1;
    }
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

        // Usa microtask para actualizar el color después del build
        Future.microtask(() => _updateDominantColor(track));

        final maxPosition = state.maxPositionSeconds;
        _position = state.positionSeconds;
        final primaryColor = Theme.of(context).colorScheme.primary;

        final backgroundColor =
            _dominantColor ?? Theme.of(context).colorScheme.surface;
        final isLight = _isColorLight(backgroundColor);
        final textColor = isLight ? Colors.black87 : Colors.white;
        final accentColor = isLight
            ? Colors.black.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.7);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Now Playing'),
            backgroundColor: backgroundColor.withValues(alpha: 0.85),
            foregroundColor: textColor,
          ),
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _mainScrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        GestureDetector(
                          onHorizontalDragEnd: (details) {
                            const minSwipeDistance = 50.0;
                            if (details.velocity.pixelsPerSecond.dx <
                                -minSwipeDistance) {
                              // Swipe left -> next track
                              context.read<PlayerCubit>().skipNext();
                            } else if (details.velocity.pixelsPerSecond.dx >
                                minSwipeDistance) {
                              // Swipe right -> previous track
                              context.read<PlayerCubit>().skipPrevious();
                            }
                          },
                          child: AspectRatio(
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
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: MarqueeText(
                            text: track.nowPlayingTickerLabel,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(color: textColor),
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
                              icon: Icon(
                                Icons.favorite_border_rounded,
                                color: textColor,
                              ),
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
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: primaryColor,
                            inactiveTrackColor: accentColor.withValues(
                              alpha: 0.3,
                            ),
                            thumbColor: primaryColor,
                            overlayColor: primaryColor.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: _position.clamp(0, maxPosition),
                            max: maxPosition,
                            onChanged: (value) {
                              context.read<PlayerCubit>().seek(value);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _secondsToLabel(_position),
                                style: TextStyle(color: textColor),
                              ),
                              Text(
                                track.durationLabel,
                                style: TextStyle(color: textColor),
                              ),
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
                                  : accentColor,
                              tooltip: state.isShuffleEnabled
                                  ? 'Aleatorio activado'
                                  : 'Aleatorio desactivado',
                            ),
                            IconButton(
                              onPressed: context
                                  .read<PlayerCubit>()
                                  .skipPrevious,
                              icon: Icon(
                                Icons.skip_previous_rounded,
                                color: textColor,
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: context
                                  .read<PlayerCubit>()
                                  .togglePlayPause,
                              icon: Icon(
                                state.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: textColor,
                              ),
                              label: Text(
                                state.isPlaying ? 'Pause' : 'Play',
                                style: TextStyle(color: textColor),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                              ),
                            ),
                            IconButton(
                              onPressed: context.read<PlayerCubit>().skipNext,
                              icon: Icon(
                                Icons.skip_next_rounded,
                                color: textColor,
                              ),
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
                                  ? accentColor
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
                            Icon(Icons.volume_down_rounded, color: textColor),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: primaryColor,
                                  inactiveTrackColor: accentColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  thumbColor: primaryColor,
                                  overlayColor: primaryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                child: Slider(
                                  value: state.volume.clamp(0.0, 1.0),
                                  max: 1,
                                  onChanged: (value) {
                                    context.read<PlayerCubit>().setVolume(
                                      value,
                                    );
                                  },
                                ),
                              ),
                            ),
                            Text(
                              '${(state.volume * 100).round()}%',
                              style: TextStyle(color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TabBar(
                          controller: _tabController,
                          onTap: (index) {
                            // Soporta re-tap del tab ya activo (por ejemplo, Letras)
                            _scrollToTabsContent();
                            if (index == 0) {
                              _lastLyricsIndex = -1;
                            }
                          },
                          labelColor: textColor,
                          unselectedLabelColor: accentColor.withValues(
                            alpha: 0.7,
                          ),
                          indicatorColor: primaryColor,
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
                              _buildLyricsTab(
                                track: track,
                                textColor: textColor,
                                accentColor: accentColor,
                              ),
                              ListView.builder(
                                itemCount: state.queue.length,
                                itemBuilder: (context, index) {
                                  final item = state.queue[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(color: textColor),
                                      ),
                                    ),
                                    title: Text(
                                      item.title,
                                      style: TextStyle(color: textColor),
                                    ),
                                    subtitle: Text(
                                      item.artist,
                                      style: TextStyle(color: accentColor),
                                    ),
                                    trailing: Text(
                                      item.durationLabel,
                                      style: TextStyle(color: textColor),
                                    ),
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

  Widget _buildLyricsTab({
    required DemoTrack track,
    required Color textColor,
    required Color accentColor,
  }) {
    final lyricsKey = _lyricsTrackKey(track);
    final future = _lyricsFutureForTrack(track);

    return FutureBuilder<LyricsPayload?>(
      future: future,
      builder: (context, snapshot) {
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Actualizar letras',
                icon: Icon(Icons.refresh_rounded, color: textColor),
                onPressed: () {
                  setState(() {
                    _lastLyricsIndex = -1;
                    _lyricsFutureCache[lyricsKey] = _lyricsService
                        .fetchLyricsForTrack(track, forceRefresh: true);
                  });
                },
              ),
            ),
            Expanded(
              child: _buildLyricsTabBody(
                snapshot: snapshot,
                textColor: textColor,
                accentColor: accentColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLyricsTabBody({
    required AsyncSnapshot<LyricsPayload?> snapshot,
    required Color textColor,
    required Color accentColor,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    final payload = snapshot.data;
    if (payload == null) {
      return Center(
        child: Text(
          'No se encontraron letras para esta canción',
          style: TextStyle(color: textColor),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (payload.instrumental) {
      return Center(
        child: Text(
          'Esta pista es instrumental',
          style: TextStyle(color: textColor),
        ),
      );
    }

    if (payload.hasSynced) {
      final currentIndex = payload.lineIndexAt(
        Duration(milliseconds: (_position * 1000).round()),
      );

      _syncLyricsAutoScroll(currentIndex);

      return ListView.builder(
        controller: _lyricsScrollController,
        itemExtent: _lyricsItemExtent,
        itemCount: payload.lines.length,
        itemBuilder: (context, index) {
          final line = payload.lines[index];
          final isActive = index == currentIndex;

          return ListTile(
            dense: true,
            title: Text(
              line.text.isEmpty ? '♪' : line.text,
              style: TextStyle(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : textColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            subtitle: Text(
              _secondsToLabel(line.time.inMilliseconds / 1000),
              style: TextStyle(color: accentColor),
            ),
          );
        },
      );
    }

    final plainLines = payload.plainLyrics
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (plainLines.isEmpty) {
      return Center(
        child: Text(
          'No hay letras disponibles',
          style: TextStyle(color: textColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: plainLines.length,
      itemBuilder: (context, index) {
        return ListTile(
          dense: true,
          title: Text(plainLines[index], style: TextStyle(color: textColor)),
        );
      },
    );
  }

  void _syncLyricsAutoScroll(int currentIndex) {
    if (currentIndex < 0 || currentIndex == _lastLyricsIndex) {
      return;
    }
    _lastLyricsIndex = currentIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_lyricsScrollController.hasClients) {
        return;
      }

      final position = _lyricsScrollController.position;
      final viewport = position.viewportDimension;
      final target =
          (currentIndex * _lyricsItemExtent) -
          (viewport / 2) +
          (_lyricsItemExtent / 2);

      final clamped = target.clamp(0.0, position.maxScrollExtent).toDouble();
      _lyricsScrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<LyricsPayload?> _lyricsFutureForTrack(
    DemoTrack track, {
    bool forceRefresh = false,
  }) {
    final key = _lyricsTrackKey(track);

    final isTrackChanged = key != _lastLyricsTrackKey;
    if (isTrackChanged) {
      _lastLyricsTrackKey = key;
      _lastLyricsIndex = -1;
      if (_lyricsScrollController.hasClients) {
        _lyricsScrollController.jumpTo(0);
      }
    }

    if (forceRefresh || !_lyricsFutureCache.containsKey(key)) {
      _lyricsFutureCache[key] = _lyricsService.fetchLyricsForTrack(
        track,
        forceRefresh: forceRefresh,
      );
    }

    return _lyricsFutureCache[key]!;
  }

  String _lyricsTrackKey(DemoTrack track) {
    return '${track.songId ?? 0}|${track.title}|${track.artist}|${track.album}|${track.durationSeconds}';
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
