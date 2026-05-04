import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' as audio_player;

import '../../../data/demo/demo_data.dart';
import '../../../data/services/audio_service.dart';
import '../../../domain/entities/demo_models.dart';
import 'player_state.dart' as player_state;

class PlayerCubit extends Cubit<player_state.PlayerState> {
  final AudioService _audioService = AudioService();
  late final StreamSubscription<audio_player.PlayerState> _playerStateSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;
  late final StreamSubscription<Duration> _positionSubscription;

  PlayerCubit()
      : super(
          player_state.PlayerState(
            currentTrack: DemoData.tracks.first,
            queue: DemoData.tracks,
            isPlaying: false,
            positionSeconds: 0,
          ),
        ) {
    _initializeAudioListeners();
  }

  void _initializeAudioListeners() {
    // Listen to player state changes
    _playerStateSubscription =
        _audioService.playerStateStream.listen((playerState) {
      if (state.currentTrack != null) {
        emit(state.copyWith(isPlaying: playerState.playing));
      }
    });

    // Listen to position changes
    _positionSubscription = _audioService.positionStream.listen((position) {
      if (state.currentTrack != null) {
        emit(state.copyWith(positionSeconds: position.inSeconds.toDouble()));
      }
    });

    // Listen to duration changes
    _durationSubscription = _audioService.durationStream.listen((duration) {
      if (duration != null && state.currentTrack != null) {
        emit(state.copyWith(durationSeconds: duration.inSeconds.toDouble()));
      }
    });
  }

  Future<void> playTrack(DemoTrack track, {required List<DemoTrack> queue}) async {
    try {
      emit(
        state.copyWith(
          currentTrack: track,
          queue: queue,
          isPlaying: false,
          positionSeconds: 0,
        ),
      );

      // Load and play audio file
      if (track.filePath != null) {
        await _audioService.setUrl(track.filePath!);
        await _audioService.play();
      } else {
        print('Track has no file path: ${track.title}');
      }
    } catch (e) {
      print('Error playing track: $e');
      emit(state.copyWith(isPlaying: false));
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (state.isPlaying) {
        await _audioService.pause();
      } else {
        await _audioService.play();
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
    }
  }

  Future<void> seek(double positionSeconds) async {
    try {
      final clamped = positionSeconds.clamp(0, state.maxPositionSeconds).toDouble();
      await _audioService.seek(Duration(seconds: clamped.toInt()));
      emit(state.copyWith(positionSeconds: clamped));
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  Future<void> skipNext() async {
    try {
      if (state.queue.isEmpty) return;

      final currentIndex = state.queue.indexWhere(
        (track) => track.title == state.currentTrack?.title,
      );

      if (currentIndex >= 0 && currentIndex < state.queue.length - 1) {
        final nextTrack = state.queue[currentIndex + 1];
        await playTrack(nextTrack, queue: state.queue);
      }
    } catch (e) {
      print('Error skipping to next: $e');
    }
  }

  Future<void> skipPrevious() async {
    try {
      if (state.queue.isEmpty) return;

      final currentIndex = state.queue.indexWhere(
        (track) => track.title == state.currentTrack?.title,
      );

      if (currentIndex > 0) {
        final previousTrack = state.queue[currentIndex - 1];
        await playTrack(previousTrack, queue: state.queue);
      }
    } catch (e) {
      print('Error skipping to previous: $e');
    }
  }

  @override
  Future<void> close() async {
    await _playerStateSubscription.cancel();
    await _durationSubscription.cancel();
    await _positionSubscription.cancel();
    await _audioService.dispose();
    return super.close();
  }
}
