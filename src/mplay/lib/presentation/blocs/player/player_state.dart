import '../../../domain/entities/demo_models.dart';

enum RepeatMode { off, all, one }

class PlayerState {
  const PlayerState({
    this.currentTrack,
    this.queue = const [],
    this.isPlaying = false,
    this.isShuffleEnabled = false,
    this.repeatMode = RepeatMode.off,
    this.positionSeconds = 0,
    this.durationSeconds,
    this.volume = 1.0,
    this.audioSessionId,
  });

  final DemoTrack? currentTrack;
  final List<DemoTrack> queue;
  final bool isPlaying;
  final bool isShuffleEnabled;
  final RepeatMode repeatMode;
  final double positionSeconds;
  final double? durationSeconds;
  final double volume;
  final int? audioSessionId;

  bool get hasTrack => currentTrack != null;

  double get maxPositionSeconds {
    // Use actual duration if available, otherwise use track duration
    if (durationSeconds != null && durationSeconds! > 0) {
      return durationSeconds!;
    }
    if (currentTrack == null) {
      return 1;
    }
    return currentTrack!.durationSeconds.toDouble();
  }

  String get positionLabel {
    final total = positionSeconds.floor();
    final mins = total ~/ 60;
    final secs = total % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String get durationLabel {
    final total = maxPositionSeconds.floor();
    final mins = total ~/ 60;
    final secs = total % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  PlayerState copyWith({
    DemoTrack? currentTrack,
    List<DemoTrack>? queue,
    bool? isPlaying,
    bool? isShuffleEnabled,
    RepeatMode? repeatMode,
    double? positionSeconds,
    double? durationSeconds,
    double? volume,
    int? audioSessionId,
    bool clearTrack = false,
  }) {
    return PlayerState(
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      queue: queue ?? this.queue,
      isPlaying: isPlaying ?? this.isPlaying,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      volume: volume ?? this.volume,
      audioSessionId: audioSessionId ?? this.audioSessionId,
    );
  }
}
