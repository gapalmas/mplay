import 'package:just_audio/just_audio.dart';

/// Service to handle audio playback using just_audio
class AudioService {
  late final AudioPlayer _audioPlayer;

  AudioService() {
    _audioPlayer = AudioPlayer();
  }

  AudioPlayer get audioPlayer => _audioPlayer;

  Future<void> setUrl(String filePath) async {
    try {
      await _audioPlayer.setFilePath(filePath);
    } catch (e) {
      print('Error setting audio file: $e');
      rethrow;
    }
  }

  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing audio: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping audio: $e');
      rethrow;
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
      rethrow;
    }
  }

  Duration? getCurrentPosition() {
    return _audioPlayer.position;
  }

  Duration? getDuration() {
    return _audioPlayer.duration;
  }

  bool isPlaying() {
    return _audioPlayer.playing;
  }

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
