import '../../domain/entities/demo_models.dart';

class DemoData {
  static final tracks = [
    const DemoTrack(
      title: 'Bohemian Rhapsody',
      artist: 'Queen',
      album: 'A Night at the Opera',
      durationLabel: '5:55',
      durationSeconds: 355,
      format: 'FLAC',
      bitrateKbps: 320,
    ),
    const DemoTrack(
      title: 'Hotel California',
      artist: 'Eagles',
      album: 'Hotel California',
      durationLabel: '6:30',
      durationSeconds: 390,
      format: 'MP3',
      bitrateKbps: 320,
    ),
    const DemoTrack(
      title: 'Stairway to Heaven',
      artist: 'Led Zeppelin',
      album: 'Untitled',
      durationLabel: '8:02',
      durationSeconds: 482,
      format: 'FLAC',
      bitrateKbps: 960,
    ),
    const DemoTrack(
      title: 'Comfortably Numb',
      artist: 'Pink Floyd',
      album: 'The Wall',
      durationLabel: '6:22',
      durationSeconds: 382,
      format: 'AAC',
      bitrateKbps: 256,
    ),
    const DemoTrack(
      title: 'November Rain',
      artist: 'Guns N\' Roses',
      album: 'Use Your Illusion I',
      durationLabel: '8:57',
      durationSeconds: 537,
      format: 'FLAC',
      bitrateKbps: 320,
    ),
  ];

  static final albums = [
    DemoAlbum(
      name: 'A Night at the Opera',
      artist: 'Queen',
      year: 1975,
      totalDuration: '48:02',
      tracks: tracks,
    ),
    DemoAlbum(
      name: 'The Wall',
      artist: 'Pink Floyd',
      year: 1979,
      totalDuration: '81:09',
      tracks: tracks.reversed.toList(),
    ),
    DemoAlbum(
      name: 'Jazz',
      artist: 'Queen',
      year: 1978,
      totalDuration: '44:49',
      tracks: tracks.take(4).toList(),
    ),
    DemoAlbum(
      name: 'Hotel California',
      artist: 'Eagles',
      year: 1976,
      totalDuration: '43:28',
      tracks: tracks.take(3).toList(),
    ),
  ];

  static final artists = const [
    DemoArtist(name: 'Queen', albums: 18, tracks: 204),
    DemoArtist(name: 'Pink Floyd', albums: 15, tracks: 167),
    DemoArtist(name: 'Eagles', albums: 11, tracks: 96),
    DemoArtist(name: 'Led Zeppelin', albums: 9, tracks: 108),
  ];

  static final playlists = [
    DemoPlaylist(
      name: 'Mis Favoritas',
      trackCount: 45,
      totalDuration: '2h 58min',
      tracks: tracks,
    ),
    DemoPlaylist(
      name: 'Rock Clásico',
      trackCount: 23,
      totalDuration: '1h 42min',
      tracks: tracks,
    ),
    DemoPlaylist(
      name: 'Para Trabajar',
      trackCount: 67,
      totalDuration: '4h 09min',
      tracks: tracks.reversed.toList(),
    ),
  ];
}
