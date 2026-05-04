import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/app_settings/app_settings_cubit.dart';
import '../blocs/app_settings/app_settings_state.dart';

class AppStrings {
  const AppStrings._(this._languageCode);

  final String _languageCode;

  static AppStrings of(BuildContext context) {
    final language = context.select(
      (AppSettingsCubit cubit) => cubit.state.language,
    );
    return AppStrings._(_resolveLanguageCode(context, language));
  }

  static String _resolveLanguageCode(
    BuildContext context,
    AppLanguage language,
  ) {
    return switch (language) {
      AppLanguage.spanish => 'es',
      AppLanguage.english => 'en',
      AppLanguage.system => Localizations.localeOf(context).languageCode,
    };
  }

  bool get isSpanish => _languageCode != 'en';

  String get appTitle => 'mplay';
  String get settingsTitle => isSpanish ? 'Ajustes' : 'Settings';
  String get appearance => isSpanish ? 'Apariencia' : 'Appearance';
  String get followSystem => isSpanish ? 'Seguir sistema' : 'Follow system';
  String get light => isSpanish ? 'Claro' : 'Light';
  String get dark => isSpanish ? 'Oscuro' : 'Dark';
  String get playback => isSpanish ? 'Reproducción' : 'Playback';
  String get skipSilence => isSpanish ? 'Omitir silencios' : 'Skip silence';
  String get skipSilenceDescription => isSpanish
      ? 'Se aplica durante la reproducción en Android.'
      : 'Applied during playback on Android.';
  String get defaultVolume =>
      isSpanish ? 'Volumen predeterminado' : 'Default volume';
  String get defaultRepeat => isSpanish
      ? 'Repetición predeterminada'
      : 'Default repeat mode';
  String get repeatDisabled => isSpanish ? 'Desactivada' : 'Off';
  String get repeatQueue =>
      isSpanish ? 'Repetir cola' : 'Repeat queue';
  String get repeatSong =>
      isSpanish ? 'Repetir canción' : 'Repeat track';
  String get languageSection => isSpanish ? 'Idioma' : 'Language';
  String get language => isSpanish ? 'Idioma' : 'Language';
  String get languageDescription => isSpanish
      ? 'Se aplicará en toda la app.'
      : 'It will be applied across the app.';
  String get spanish => 'Español';
  String get english => 'English';
  String get backupAndRestore => isSpanish
      ? 'Copia de seguridad y restauración'
      : 'Backup and restore';
  String get loadingLibrary => isSpanish
      ? 'Cargando biblioteca de música...'
      : 'Loading music library...';
  String get retry => isSpanish ? 'Reintentar' : 'Retry';
  String get equalizer => isSpanish ? 'Ecualizador' : 'Equalizer';
  String get settingsMenu => isSpanish ? 'Ajustes' : 'Settings';
  String get backupMenu =>
      isSpanish ? 'Backup / Restore' : 'Backup / Restore';
  String get songs => isSpanish ? 'Canciones' : 'Songs';
  String get albums => isSpanish ? 'Álbumes' : 'Albums';
  String get artists => isSpanish ? 'Artistas' : 'Artists';
  String get playlists => isSpanish ? 'Playlists' : 'Playlists';
  String get playlist => isSpanish ? 'Playlist' : 'Playlist';
    String get export => isSpanish ? 'Exportar' : 'Export';
    String get import => isSpanish ? 'Restaurar' : 'Restore';
    String get history => isSpanish ? 'Historial' : 'History';
    String get exportBackup =>
      isSpanish ? 'Crear copia de seguridad' : 'Create backup';
    String get includePlaylists =>
      isSpanish ? 'Playlists personalizadas' : 'Custom playlists';
    String get includeSettings =>
      isSpanish ? 'Configuración de la app' : 'App settings';
    String get noBackups => isSpanish
      ? 'Todavía no hay copias guardadas.'
      : 'There are no saved backups yet.';
    String get restoreBackup =>
      isSpanish ? 'Restaurar backup' : 'Restore backup';
    String get deleteBackup => isSpanish ? 'Eliminar backup' : 'Delete backup';
    String get backupCreated =>
      isSpanish ? 'Backup creado correctamente.' : 'Backup created successfully.';
    String get backupRestored => isSpanish
      ? 'Backup restaurado correctamente.'
      : 'Backup restored successfully.';
    String get backupDeleted =>
      isSpanish ? 'Backup eliminado.' : 'Backup deleted.';
    String get restoreWarning => isSpanish
      ? 'Se reemplazarán las playlists y ajustes incluidos en la copia seleccionada.'
      : 'Playlists and settings included in the selected backup will be replaced.';
    String get cancel => isSpanish ? 'Cancelar' : 'Cancel';
    String get restore => isSpanish ? 'Restaurar' : 'Restore';
    String get delete => isSpanish ? 'Eliminar' : 'Delete';
    String get bytesLabel => 'bytes';
}