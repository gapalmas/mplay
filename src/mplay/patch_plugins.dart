#!/usr/bin/env dart
// patch_plugins.dart
// Aplica los parches necesarios a plugins de Flutter que no son compatibles con
// las versiones actuales de Android Gradle Plugin (AGP).
//
// Compatible con Windows y Linux/macOS.
//
// Ejecutar desde la raíz del proyecto Flutter (src/mplay) después de flutter pub get:
//   dart patch_plugins.dart
//
// Problemas solucionados:
//   - on_audio_query_android 1.1.0: falta 'namespace' requerido por AGP 8.x
//   - on_audio_query_android 1.1.0: Java 1.8 vs Kotlin 17 mismatch

import 'dart:io';

void main() {
  _patchOnAudioQuery();
}

void _patchOnAudioQuery() {
  const pluginRelPath = 'on_audio_query_android-1.1.0/android/build.gradle';

  final pluginFile = _findInPubCache(pluginRelPath);

  if (pluginFile == null) {
    _fail(
      'Plugin on_audio_query_android-1.1.0 no encontrado en el pub-cache.\n'
      'Ejecuta "flutter pub get" primero.',
    );
    return;
  }

  var content = pluginFile.readAsStringSync();

  if (content.contains("namespace 'com.lucasjosino.on_audio_query'")) {
    print('✓ Plugin on_audio_query_android ya está parcheado.');
    return;
  }

  // Parche 1: añadir namespace dentro del bloque android { }
  if (!content.contains('android {')) {
    _fail('No se encontró el bloque "android {" en ${pluginFile.path}');
    return;
  }
  content = content.replaceFirst(
    'android {',
    "android {\n    namespace 'com.lucasjosino.on_audio_query'",
  );

  // Parche 2: añadir compileOptions con Java 17 tras compileSdkVersion 33
  if (content.contains('compileSdkVersion 33') &&
      !content.contains('compileOptions')) {
    content = content.replaceFirst(
      'compileSdkVersion 33',
      'compileSdkVersion 33\n\n'
          '    compileOptions {\n'
          '        sourceCompatibility JavaVersion.VERSION_17\n'
          '        targetCompatibility JavaVersion.VERSION_17\n'
          '    }',
    );
  }

  pluginFile.writeAsStringSync(content);
  print('✓ Plugin on_audio_query_android parcheado correctamente en:');
  print('  ${pluginFile.path}');
}

/// Busca [relPath] dentro del pub-cache según el SO actual.
/// Devuelve null si no existe.
File? _findInPubCache(String relPath) {
  final candidates = _pubCacheCandidates();
  for (final base in candidates) {
    final f = File(
      '$base${Platform.pathSeparator}hosted${Platform.pathSeparator}'
      'pub.dev${Platform.pathSeparator}'
      '${relPath.replaceAll('/', Platform.pathSeparator)}',
    );
    if (f.existsSync()) return f;
  }
  return null;
}

/// Retorna las rutas base del pub-cache para el SO actual.
List<String> _pubCacheCandidates() {
  // La variable de entorno PUB_CACHE tiene prioridad si está definida.
  final envCache = Platform.environment['PUB_CACHE'];
  if (envCache != null && envCache.isNotEmpty) return [envCache];

  if (Platform.isWindows) {
    // Windows: %LOCALAPPDATA%\Pub\Cache
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      return ['$localAppData\\Pub\\Cache'];
    }
    // Fallback por si LOCALAPPDATA no está definida
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    return ['$userProfile\\AppData\\Local\\Pub\\Cache'];
  }

  // Linux / macOS
  final home = Platform.environment['HOME'] ?? '';
  return ['$home/.pub-cache'];
}

void _fail(String message) {
  stderr.writeln('ERROR: $message');
  exit(1);
}
