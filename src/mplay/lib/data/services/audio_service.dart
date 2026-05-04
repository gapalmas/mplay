import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';

/// Wraps just_audio AudioPlayer with a clean interface for the PlayerCubit
class AudioService {
  AudioService() : _player = AudioPlayer();

  final AudioPlayer _player;
  static const MethodChannel _audioFxChannel = MethodChannel('mplay/audio_fx');

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get audioSessionIdStream => _player.androidAudioSessionIdStream;

  bool get playing => _player.playing;

  /// Load a file URI or content URI and prepare for playback
  Future<void> setUri(String uri) async {
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(uri)));
    } catch (e) {
      print('AudioService: error setting URI $uri: $e');
      rethrow;
    }
  }

  Future<void> play() async => _player.play();
  Future<void> pause() async => _player.pause();
  Future<void> stop() async => _player.stop();

  Future<void> seek(Duration position) async {
    final duration = _player.duration;
    if (duration != null && position > duration) {
      position = duration;
    }
    await _player.seek(position);
  }

  Future<bool> openSystemEqualizer(int sessionId) async {
    try {
      final opened = await _audioFxChannel.invokeMethod<bool>(
        'openEqualizer',
        {'sessionId': sessionId},
      );
      return opened ?? false;
    } catch (e) {
      print('AudioService: error opening equalizer: $e');
      return false;
    }
  }

  Future<void> dispose() async => _player.dispose();
}
