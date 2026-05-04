import '../../../domain/entities/demo_models.dart';

class PlayerState {
  const PlayerState({
    this.currentTrack,
    this.queue = const [],
    this.isPlaying = false,
    this.positionSeconds = 0,
  });

  final DemoTrack? currentTrack;
  final List<DemoTrack> queue;
  final bool isPlaying;
  final double positionSeconds;

  bool get hasTrack => currentTrack != null;

  double get maxPositionSeconds {
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

  PlayerState copyWith({
    DemoTrack? currentTrack,
    List<DemoTrack>? queue,
    bool? isPlaying,
    double? positionSeconds,
    bool clearTrack = false,
  }) {
    return PlayerState(
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      queue: queue ?? this.queue,
      isPlaying: isPlaying ?? this.isPlaying,
      positionSeconds: positionSeconds ?? this.positionSeconds,
    );
  }
}
