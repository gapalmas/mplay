import 'package:flutter/widgets.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.mplay.mplay.audio',
    androidNotificationChannelName: 'Reproducción de música',
    androidNotificationOngoing: false,
    androidStopForegroundOnPause: false,
    preloadArtwork: true,
  );

  runApp(const MPlayApp());
}
