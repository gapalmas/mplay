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
  StreamSubscription? _sessionIdSub;
  StreamSubscription? _volumeSub;
  bool _isHandlingCompletion = false;

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

      if (ps.processingState == ja.ProcessingState.completed) {
        unawaited(_handleTrackCompleted());
      }
    });

    _sessionIdSub = _audioService.audioSessionIdStream.listen((sessionId) {
      if (sessionId != null && sessionId > 0) {
        emit(state.copyWith(audioSessionId: sessionId));
      }
    });

    _volumeSub = _audioService.volumeStream.listen((volume) {
      emit(state.copyWith(volume: volume));
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
    final idx = state.queue.indexWhere(
      (track) => _sameTrack(track, state.currentTrack!),
    );
    if (idx >= 0 && idx < state.queue.length - 1) {
      await playTrack(state.queue[idx + 1], queue: state.queue);
    }
  }

  Future<void> skipPrevious() async {
    if (state.queue.isEmpty || state.currentTrack == null) return;
    final idx = state.queue.indexWhere(
      (track) => _sameTrack(track, state.currentTrack!),
    );
    if (idx > 0) {
      await playTrack(state.queue[idx - 1], queue: state.queue);
    }
  }

  Future<void> _handleTrackCompleted() async {
    if (_isHandlingCompletion) return;
    _isHandlingCompletion = true;
    try {
      await skipNext();
    } finally {
      _isHandlingCompletion = false;
    }
  }

  bool _sameTrack(DemoTrack a, DemoTrack b) {
    final aKey = a.uri ?? a.filePath;
    final bKey = b.uri ?? b.filePath;
    if (aKey != null && bKey != null) {
      return aKey == bKey;
    }
    return a.title == b.title && a.artist == b.artist && a.album == b.album;
  }

  Future<bool> openEqualizer() async {
    final sessionId = state.audioSessionId;
    if (sessionId == null || sessionId <= 0) {
      return false;
    }
    return _audioService.openSystemEqualizer(sessionId);
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioService.setVolume(volume);
    } catch (e) {
      print('PlayerCubit: error setting volume: $e');
    }
  }

  @override
  Future<void> close() async {
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _stateSub?.cancel();
    await _sessionIdSub?.cancel();
    await _volumeSub?.cancel();
    await _audioService.dispose();
    return super.close();
  }
}
