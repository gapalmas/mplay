import 'dart:io';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../domain/entities/demo_models.dart';

class TrackArtwork extends StatelessWidget {
  const TrackArtwork({
    super.key,
    required this.track,
    this.size = 48,
    this.radius = 10,
    this.iconSize = 24,
  });

  final DemoTrack track;
  final double size;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final fallback = _fallback(context);

    if (track.songId != null && track.songId! > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: QueryArtworkWidget(
          id: track.songId!,
          type: ArtworkType.AUDIO,
          artworkWidth: size,
          artworkHeight: size,
          artworkFit: BoxFit.cover,
          nullArtworkWidget: _folderCoverOrFallback(context),
        ),
      );
    }

    return _folderCoverOrFallback(context) ?? fallback;
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Icon(Icons.music_note_rounded, size: iconSize),
    );
  }

  Widget? _folderCoverOrFallback(BuildContext context) {
    final path = track.filePath;
    if (path == null || path.isEmpty) {
      return _fallback(context);
    }

    final sep = Platform.pathSeparator;
    final lastSep = path.lastIndexOf(sep);
    if (lastSep <= 0) {
      return _fallback(context);
    }

    final dirPath = path.substring(0, lastSep);
    final baseName = path.substring(lastSep + 1);
    final dot = baseName.lastIndexOf('.');
    final fileStem = dot > 0 ? baseName.substring(0, dot) : baseName;

    final candidates = [
      '$dirPath${sep}cover.jpg',
      '$dirPath${sep}Cover.jpg',
      '$dirPath${sep}folder.jpg',
      '$dirPath${sep}Folder.jpg',
      '$dirPath$sep$fileStem.jpg',
      '$dirPath$sep$fileStem.png',
    ];

    for (final candidate in candidates) {
      final file = File(candidate);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallback(context),
          ),
        );
      }
    }

    return _fallback(context);
  }
}
