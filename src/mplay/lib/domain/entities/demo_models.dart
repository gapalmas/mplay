class DemoTrack {
  const DemoTrack({
    required this.title,
    required this.artist,
    required this.album,
    required this.durationLabel,
    required this.durationSeconds,
    required this.format,
    required this.bitrateKbps,
    this.songId,
    this.filePath,
    this.uri,
  });

  final String title;
  final String artist;
  final String album;
  final String durationLabel;
  final int durationSeconds;
  final String format;
  final int bitrateKbps;
  final int? songId;
  final String? filePath; // Local file path
  final String? uri; // Content URI for Android
}

class DemoAlbum {
  DemoAlbum({
    required this.name,
    required this.artist,
    required this.year,
    required this.totalDuration,
    required this.tracks,
  });

  final String name;
  final String artist;
  final int year;
  final String totalDuration;
  final List<DemoTrack> tracks;
}

class DemoArtist {
  const DemoArtist({
    required this.name,
    required this.albums,
    required this.tracks,
  });

  final String name;
  final int albums;
  final int tracks;
}

class DemoPlaylist {
  DemoPlaylist({
    required this.name,
    required this.trackCount,
    required this.totalDuration,
    required this.tracks,
  });

  final String name;
  final int trackCount;
  final String totalDuration;
  final List<DemoTrack> tracks;
}
