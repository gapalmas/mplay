import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/demo/demo_data.dart';
import '../../../domain/entities/demo_models.dart';
import 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  PlayerCubit()
      : super(
          PlayerState(
            currentTrack: DemoData.tracks.first,
            queue: DemoData.tracks,
            isPlaying: false,
            positionSeconds: 45,
          ),
        );

  void playTrack(DemoTrack track, {required List<DemoTrack> queue}) {
    emit(
      state.copyWith(
        currentTrack: track,
        queue: queue,
        isPlaying: true,
        positionSeconds: 0,
      ),
    );
  }

  void togglePlayPause() {
    emit(state.copyWith(isPlaying: !state.isPlaying));
  }

  void seek(double positionSeconds) {
    final clamped = positionSeconds
        .clamp(0, state.maxPositionSeconds)
        .toDouble();
    emit(state.copyWith(positionSeconds: clamped));
  }
}
