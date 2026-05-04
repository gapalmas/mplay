import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/player/player_cubit.dart';
import '../blocs/player/player_state.dart';
import '../pages/now_playing_screen.dart';
import 'mini_player_bar.dart';

class PlayerMiniPlayerBar extends StatelessWidget {
  const PlayerMiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        if (!state.hasTrack || state.currentTrack == null) {
          return const SizedBox.shrink();
        }
        return MiniPlayerBar(
          track: state.currentTrack!,
          positionLabel: state.positionLabel,
          isPlaying: state.isPlaying,
          onSkipPrevious: context.read<PlayerCubit>().skipPrevious,
          onSkipNext: context.read<PlayerCubit>().skipNext,
          onPlayPause: context.read<PlayerCubit>().togglePlayPause,
          onOpenNowPlaying: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
            );
          },
        );
      },
    );
  }
}
