import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/demo_models.dart';

/// Wraps just_audio AudioPlayer with a clean interface for the PlayerCubit
class AudioService {
  AudioService() : _player = AudioPlayer();

  final AudioPlayer _player;
  static const MethodChannel _audioFxChannel = MethodChannel('mplay/audio_fx');

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get audioSessionIdStream => _player.androidAudioSessionIdStream;
  Stream<double> get volumeStream => _player.volumeStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  bool get playing => _player.playing;

  Future<void> setQueue(
    List<DemoTrack> queue, {
    required int initialIndex,
  }) async {
    try {
      final sources = queue
          .map((track) {
            final uri = track.uri ?? track.filePath;
            if (uri == null || uri.isEmpty) {
              return null;
            }
            return AudioSource.uri(
              Uri.parse(uri),
              tag: MediaItem(
                id: uri,
                title: track.title,
                artist: track.artist,
                album: track.album,
                duration: Duration(seconds: track.durationSeconds),
                artUri: _buildArtworkUri(track),
              ),
            );
          })
          .whereType<AudioSource>()
          .toList();

      if (sources.isEmpty) {
        throw StateError('No hay pistas válidas para reproducir');
      }

      final safeIndex = initialIndex.clamp(0, sources.length - 1);
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: safeIndex,
      );
    } catch (e) {
      print('AudioService: error setting queue: $e');
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

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0).toDouble();
    await _player.setVolume(clamped);
  }

  Future<void> setSkipSilenceEnabled(bool enabled) async {
    await _player.setSkipSilenceEnabled(enabled);
  }

  Future<void> seekToNext() => _player.seekToNext();
  Future<void> seekToPrevious() => _player.seekToPrevious();

  Future<bool> openSystemEqualizer(int sessionId) async {
    try {
      final opened = await _audioFxChannel.invokeMethod<bool>('openEqualizer', {
        'sessionId': sessionId,
      });
      return opened ?? false;
    } catch (e) {
      print('AudioService: error opening equalizer: $e');
      return false;
    }
  }

  Future<void> dispose() async => _player.dispose();

  Uri? _buildArtworkUri(DemoTrack track) {
    final songId = track.songId;
    if (songId != null && songId > 0) {
      return Uri.parse('content://media/external/audio/media/$songId/albumart');
    }

    final path = track.filePath;
    if (path != null && path.isNotEmpty) {
      return Uri.file(path);
    }

    return null;
  }
}
