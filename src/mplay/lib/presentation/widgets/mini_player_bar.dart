import 'package:flutter/material.dart';

import '../../domain/entities/demo_models.dart';
import 'track_artwork.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({
    super.key,
    required this.track,
    required this.positionLabel,
    required this.onPlayPause,
    required this.onOpenNowPlaying,
  });

  final DemoTrack track;
  final String positionLabel;
  final VoidCallback onPlayPause;
  final VoidCallback onOpenNowPlaying;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: onOpenNowPlaying,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: TrackArtwork(
                        track: track,
                        size: 36,
                        radius: 18,
                        iconSize: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${track.title} • ${track.artist}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            positionLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    IconButton(
                      onPressed: onPlayPause,
                      icon: const Icon(Icons.play_arrow_rounded),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(value: 0.14, minHeight: 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
