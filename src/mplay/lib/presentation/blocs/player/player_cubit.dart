import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../../data/services/audio_service.dart';
import '../../../domain/entities/demo_models.dart';
import 'player_state.dart' as player_state;

class PlayerCubit extends Cubit<player_state.PlayerState> {
  PlayerCubit()
      : _audioService = AudioService(),
        super(const player_state.PlayerState()) {
    _subscribeToAudio();
  }

  final AudioService _audioService;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _stateSub;

  void _subscribeToAudio() {
    _positionSub = _audioService.positionStream.listen((pos) {
      emit(state.copyWith(positionSeconds: pos.inMilliseconds / 1000.0));
    });

    _durationSub = _audioService.durationStream.listen((dur) {
      if (dur != null) {
        emit(state.copyWith(durationSeconds: dur.inMilliseconds / 1000.0));
      }
    });

    _stateSub = _audioService.playerStateStream.listen((ps) {
      final isPlaying = ps.playing &&
          ps.processingState != ja.ProcessingState.completed &&
          ps.processingState != ja.ProcessingState.idle;
      emit(state.copyWith(isPlaying: isPlaying));
    });
  }

  Future<void> playTrack(DemoTrack track, {required List<DemoTrack> queue}) async {
    try {
      emit(state.copyWith(
        currentTrack: track,
        queue: queue,
        isPlaying: false,
        positionSeconds: 0,
      ));

      final uri = track.uri ?? track.filePath;
      if (uri == null) {
        print('PlayerCubit: no URI for track ${track.title}');
        return;
      }

      await _audioService.setUri(uri);
      await _audioService.play();
    } catch (e) {
      print('PlayerCubit: error playing ${track.title}: $e');
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
      print('PlayerCubit: error toggling play/pause: $e');
    }
  }

  Future<void> seek(double positionSeconds) async {
    try {
      final clamped = positionSeconds.clamp(0, state.maxPositionSeconds).toDouble();
      await _audioService.seek(Duration(milliseconds: (clamped * 1000).round()));
    } catch (e) {
      print('PlayerCubit: error seeking: $e');
    }
  }

  Future<void> skipNext() async {
    if (state.queue.isEmpty || state.currentTrack == null) return;
    final idx = state.queue.indexWhere((t) => t.title == state.currentTrack!.title);
    if (idx >= 0 && idx < state.queue.length - 1) {
      await playTrack(state.queue[idx + 1], queue: state.queue);
    }
  }

  Future<void> skipPrevious() async {
    if (state.queue.isEmpty || state.currentTrack == null) return;
    final idx = state.queue.indexWhere((t) => t.title == state.currentTrack!.title);
    if (idx > 0) {
      await playTrack(state.queue[idx - 1], queue: state.queue);
    }
  }

  @override
  Future<void> close() async {
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _stateSub?.cancel();
    await _audioService.dispose();
    return super.close();
  }
}
