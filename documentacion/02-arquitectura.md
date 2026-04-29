# Arquitectura de la Aplicación — mplay

**Patrón:** Clean Architecture + BLoC  
**Lenguaje:** Dart / Flutter  
**Target:** Android (compatible iOS)  
**Versión:** v3 — incluye Ecualizador, Letras, Playlists, Backup/Restore, Configuración y Tema

---

## Patrón arquitectónico

Se adopta **Clean Architecture** con **BLoC** (Business Logic Component) como gestor de estado.

```
Presentation  ──►  Domain  ──►  Data
(BLoC/Widgets)    (Entidades,   (Repositorios,
                   UsesCases,    DataSources,
                   Interfaces)   Paquetes externos)
```

La regla de dependencia fluye **hacia adentro**: las capas externas dependen de las internas, nunca al revés. El **Domain** no conoce Flutter ni paquetes de terceros.

---

## Estructura de carpetas

```
lib/
├── main.dart
├── app.dart                        ← MaterialApp + rutas
├── di/
│   └── injection.dart              ← GetIt (inyección de dependencias)
│
├── domain/
│   ├── entities/
│   │   ├── track.dart              ← incluye AudioFormat enum
│   │   ├── album.dart
│   │   ├── artist.dart
│   │   ├── playlist.dart
│   │   ├── equalizer_band.dart
│   │   ├── equalizer_profile.dart
│   │   ├── lyric_line.dart
│   │   ├── lyrics.dart             ← incluye LyricsSource enum
│   │   ├── lyrics_cache_entry.dart
│   │   ├── app_settings.dart       ← incluye ThemeMode enum
│   │   ├── app_backup.dart
│   │   └── backup_metadata.dart
│   ├── repositories/
│   │   ├── media_repository.dart
│   │   ├── audio_repository.dart
│   │   ├── playlist_repository.dart
│   │   ├── equalizer_repository.dart
│   │   ├── lyrics_repository.dart
│   │   ├── settings_repository.dart
│   │   └── backup_repository.dart
│   └── use_cases/
│       ├── get_all_tracks.dart
│       ├── get_all_albums.dart
│       ├── get_all_artists.dart
│       ├── play_track.dart
│       ├── control_playback.dart
│       ├── get_playlists.dart
│       ├── create_playlist.dart
│       ├── delete_playlist.dart
│       ├── add_track_to_playlist.dart
│       ├── remove_track_from_playlist.dart
│       ├── get_equalizer_profiles.dart
│       ├── save_equalizer_profile.dart
│       ├── apply_equalizer_profile.dart
│       ├── delete_equalizer_profile.dart
│       ├── get_lyrics.dart
│       ├── cache_lyrics.dart
│       ├── get_settings.dart
│       ├── save_settings.dart
│       ├── export_backup.dart
│       └── import_backup.dart
│
├── data/
│   ├── repositories/
│   │   ├── media_repository_impl.dart
│   │   ├── audio_repository_impl.dart
│   │   ├── playlist_repository_impl.dart
│   │   ├── equalizer_repository_impl.dart
│   │   ├── lyrics_repository_impl.dart
│   │   ├── settings_repository_impl.dart
│   │   └── backup_repository_impl.dart
│   ├── datasources/
│   │   ├── local_media_datasource.dart      ← on_audio_query
│   │   ├── audio_player_datasource.dart     ← just_audio + audio_service
│   │   ├── playlist_local_datasource.dart   ← sqflite
│   │   ├── equalizer_datasource.dart        ← just_audio_equalizer
│   │   ├── lyrics_file_datasource.dart      ← File system (.lrc / .txt)
│   │   ├── lyrics_cache_datasource.dart     ← sqflite
│   │   ├── settings_datasource.dart         ← shared_preferences
│   │   └── backup_datasource.dart           ← path_provider + file_picker + share_plus
│   └── models/
│       ├── track_model.dart
│       ├── album_model.dart
│       └── artist_model.dart
│
└── presentation/
    ├── blocs/
    │   ├── player/
    │   │   ├── player_bloc.dart
    │   │   ├── player_event.dart
    │   │   └── player_state.dart
    │   ├── library/
    │   │   ├── library_bloc.dart
    │   │   ├── library_event.dart
    │   │   └── library_state.dart
    │   ├── playlist/
    │   │   ├── playlist_bloc.dart
    │   │   ├── playlist_event.dart
    │   │   └── playlist_state.dart
    │   ├── equalizer/
    │   │   ├── equalizer_bloc.dart
    │   │   ├── equalizer_event.dart
    │   │   └── equalizer_state.dart
    │   └── lyrics/
    │       ├── lyrics_bloc.dart
    │       ├── lyrics_event.dart
    │       └── lyrics_state.dart
    ├── pages/
    │   ├── home_screen.dart
    │   ├── now_playing_screen.dart
    │   ├── album_detail_screen.dart
    │   ├── artist_detail_screen.dart
    │   ├── playlists_screen.dart
    │   ├── playlist_detail_screen.dart
    │   └── equalizer_screen.dart
    └── widgets/
        ├── player_bar.dart
        ├── track_tile.dart
        ├── album_card.dart
        ├── lyrics_view.dart
        └── equalizer_band_slider.dart
```

---

## Diagramas UML

| Diagrama | Archivo |
|---|---|
| Componentes (arquitectura general) | [02-arquitectura-componentes.puml](02-arquitectura-componentes.puml) |
| Clases (entidades, repos, BLoC) | [03-diagrama-clases.puml](03-diagrama-clases.puml) |
| Secuencia — reproducir canción | [04-secuencia-reproduccion.puml](04-secuencia-reproduccion.puml) |
| Estados del reproductor (PlayerBloc) | [05-estados-reproductor.puml](05-estados-reproductor.puml) |

---

## Paquetes principales

| Paquete | Versión | Propósito |
|---|---|---|
| `flutter_bloc` | ^8.1.x | Gestor de estado BLoC |
| `equatable` | ^2.0.x | Igualdad de valor en entidades/estados |
| `just_audio` | ^0.9.x | Reproducción de audio |
| `audio_service` | ^0.18.x | Reproducción en segundo plano + notificación multimedia |
| `just_audio_equalizer` | ^0.0.x | Ecualizador nativo Android (AudioEffect API) |
| `on_audio_query` | ^2.9.x | Consulta de archivos de audio en MediaStore (Android) |
| `sqflite` | ^2.3.x | Persistencia local (playlists, caché de letras) |
| `shared_preferences` | ^2.2.x | Persistencia de configuración (AppSettings) |
| `path_provider` | ^2.1.x | Ruta de almacenamiento para archivos de backup |
| `file_picker` | ^8.x | Selección de archivo `.mplaybackup` para importar |
| `share_plus` | ^9.x | Exportar/compartir el archivo de backup |
| `get_it` | ^7.6.x | Inyección de dependencias (service locator) |

---

## Formatos de audio soportados

Soportados a través de `just_audio` + codecs nativos de Android:

| Formato | Extensión | Notas |
|---|---|---|
| MP3 | `.mp3` | Universal, el más común |
| FLAC | `.flac` | Lossless, alta calidad |
| AAC | `.aac`, `.m4a` | Estándar en iTunes/iOS |
| OGG Vorbis | `.ogg` | Libre y eficiente |
| WAV | `.wav` | Sin compresión |
| OPUS | `.opus` | Alta compresión, buena calidad |
| WMA | `.wma` | Windows Media (Android API >= 21) |

> El enum `AudioFormat` en la entidad `Track` representa el formato detectado a partir de la extensión del archivo.

### Metadata de la canción en reproducción

La entidad `Track` expone toda la información que `NowPlayingScreen` necesita mostrar:

| Campo | Tipo | Descripción |
|---|---|---|
| `title` | `String` | Nombre de la canción |
| `artist` | `String` | Artista |
| `album` | `String` | Álbum |
| `albumArtUri` | `Uri?` | URI de la carátula (desde MediaStore) |
| `duration` | `Duration` | Duración total de la pista |
| `format` | `AudioFormat` | Formato del archivo (mp3, flac, etc.) |
| `bitrate` | `int?` | Tasa de bits en kbps (ej. 128, 192, 320) |
| `sampleRate` | `int?` | Frecuencia de muestreo en Hz (ej. 44100, 48000) |
| `size` | `int?` | Tamaño del archivo en bytes |

> `bitrate`, `sampleRate` y `size` se obtienen de Android `MediaStore` a través de `on_audio_query` (campos `_BITRATE`, `_SAMPLE_RATE`, `_SIZE`). Pueden ser `null` si el dispositivo no expone esos metadatos.

`PlayerPlaying` contiene el `Track` completo, por lo que `NowPlayingScreen` (via `BlocBuilder<PlayerBloc, PlayerState>`) tiene acceso directo a todos estos campos sin llamadas adicionales.

---

## Ecualizador

- Implementado con `just_audio_equalizer`, que expone el **AudioEffect Equalizer API** de Android.
- Soporta n **bandas de frecuencia** (típicamente 5-10 según el dispositivo).
- Cada banda tiene: frecuencia central (Hz), ganancia ajustable (dB), min/max ganancia.
- **Perfiles**: el usuario puede crear, nombrar, guardar y eliminar perfiles personalizados.
- **Presets de fábrica**: Plano, Rock, Pop, Jazz, Clásica, Bass Boost (incluidos por defecto, no editables).
- Los perfiles se persisten en SQLite (`sqflite`) junto con los de playlists.
- `EqualizerBloc` gestiona el estado: perfiles disponibles, perfil activo y habilitado/deshabilitado.

---

## Letras de canciones (Lyrics)

- Soporte para archivos `.lrc` (con timestamps sincronizados) y `.txt` (sin timestamps).
- `LyricsFileDataSource` busca el archivo de letras en el **mismo directorio** que el archivo de audio, con el mismo nombre base:
  - `cancion.mp3` → busca `cancion.lrc` primero, luego `cancion.txt`
- **Formato LRC**: cada línea tiene timestamp `[mm:ss.xx]` seguido del texto. Se parsea en `List<LyricLine>` con `timestamp: Duration`.
- **Formato TXT**: texto plano sin timestamps. Se muestra completo sin sincronización.
- `LyricsBloc` expone `currentLine` que se actualiza con la posición del `PlayerBloc` (sincronización karaoke).
- `LyricsView` widget muestra la letra con la línea activa resaltada y auto-scroll.

---

## Playlists personalizadas

- Almacenadas localmente en SQLite (dos tablas: `playlists` y `playlist_tracks`).
- Operaciones: crear, eliminar, agregar canción, quitar canción, reordenar canciones.
- Desde cualquier `TrackTile` (con long-press) se puede seleccionar a qué playlist agregar.
- `PlaylistBloc` gestiona el estado de la lista completa de playlists y la playlist activa en detalle.
- Las playlists pueden reproducirse completas (se envían al `PlayerBloc` como queue).

---

## Configuración y perfil del reproductor (AppSettings)

### Entidad `AppSettings`

Almacena **toda la configuración persistente del usuario** en un único objeto. Se persiste con `shared_preferences` (JSON serializado).

| Campo | Tipo | Descripción |
|---|---|---|
| `themeMode` | `ThemeMode` | Tema de la interfaz |
| `defaultEqProfileId` | `int?` | ID del perfil de EQ activo al iniciar |
| `equalizerEnabled` | `bool` | Estado inicial del ecualizador |
| `language` | `String` | Código de idioma (`es`, `en`, `system`) |
| `skipSilence` | `bool` | Omitir silencios durante la reproducción |
| `crossfadeDuration` | `Duration` | Duración del crossfade entre canciones (0 = desactivado) |

### Enum `ThemeMode`

```
system   ← sigue el sistema operativo (por defecto)
light    ← siempre claro
dark     ← siempre oscuro
```

### Comportamiento del tema

- `app.dart` escucha el `SettingsBloc` vía `BlocBuilder`.
- Cuando `SettingsLoaded` emite un nuevo `themeMode`, `MaterialApp.themeMode` se actualiza en caliente sin reiniciar la app.
- Los colores se definen en `ThemeData` para `ThemeMode.light` y `ThemeMode.dark`; el sistema elige si se usa `ThemeMode.system`.

### `SettingsBloc`

- Carga `AppSettings` al iniciar la app (evento `LoadSettingsEvent`).
- Acepta `UpdateSettingsEvent(AppSettings)` para cualquier cambio parcial.
- Estado: `SettingsInitial` → `SettingsLoaded(settings)` / `SettingsError`.
- El `SettingsScreen` permite al usuario seleccionar tema, idioma, EQ por defecto, crossfade y otros.

### Integración con Backup

- `AppSettings` se incluye como sección opcional en `AppBackup` (campo `appSettings`).
- `BackupSection.appSettings` permite exportar/importar solo la configuración si se desea.
- Al importar un backup con `appSettings`, el `SettingsBloc` recibe un `UpdateSettingsEvent` para aplicarlo en caliente.

---

## Backup / Restore

> ⚠️ El flujo exacto de exportación/importación (disparador, periodicidad, destino en la nube vs local) está **pendiente de definición**. La arquitectura refleja la estructura mínima acordada.

### Contenido del backup (`AppBackup`)

| Sección (`BackupSection`) | Contenido |
|---|---|
| `playlists` | Todas las playlists con sus canciones |
| `equalizerProfiles` | Perfiles de EQ personalizados (no los presets de fábrica) |
| `lyricsCache` | Letras ya parseadas (evita re-parsear) |
| `appSettings` | Configuración completa del reproductor |

### Formato

- Archivo JSON con extensión `.mplaybackup`.
- Incluye `BackupMetadata`: versión del schema, fecha, nombre del dispositivo, secciones incluidas.

### Paquetes involucrados

- `path_provider` → resolver ruta de escritura del archivo.
- `file_picker` → que el usuario seleccione un `.mplaybackup` para importar.
- `share_plus` → compartir/exportar el archivo generado.

---

## Flujo principal

1. Al iniciar la app → `LibraryBloc` emite `LoadLibraryEvent`.
2. `GetAllTracksUseCase` consulta `MediaRepository` → `LocalMediaDataSource` → Android `MediaStore`.
3. La pantalla `HomeScreen` recibe `LibraryLoaded` y muestra canciones/álbumes/artistas/playlists.
4. El usuario toca una canción → `HomeScreen` envía `PlayTrackEvent` al `PlayerBloc`.
5. `PlayTrackUseCase` llama a `AudioRepository` → `AudioRepositoryImpl` → `AudioPlayerDataSource` → `just_audio`.
6. `audio_service` mantiene la reproducción en segundo plano y muestra la notificación multimedia de Android.
7. `PlayerBloc` escucha el `playerStateStream` y emite `PlayerPlaying` / `PlayerPaused` / etc.
8. `PlayerBar` (visible en todas las pantallas) se actualiza en tiempo real.
9. Al abrir `NowPlayingScreen` → `LyricsBloc` emite `LoadLyricsEvent(track)` y sincroniza con la posición del player.
10. Al abrir `EqualizerScreen` → `EqualizerBloc` carga perfiles y el perfil activo; el usuario ajusta bandas en tiempo real.
11. Long-press sobre un `TrackTile` → bottom sheet para agregar a una playlist existente o crear nueva.
12. Al iniciar la app → `SettingsBloc` carga `AppSettings`; `MaterialApp` aplica el `themeMode` guardado de inmediato.
13. Al cambiar tema desde `SettingsScreen` → `UpdateSettingsEvent` → `SettingsLoaded` → UI se actualiza en caliente.

---

## Permisos Android requeridos

En `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Leer archivos de audio (Android 12 y anteriores) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

<!-- Leer archivos multimedia (Android 13+) -->
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>

<!-- Servicio de reproducción en segundo plano -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
```