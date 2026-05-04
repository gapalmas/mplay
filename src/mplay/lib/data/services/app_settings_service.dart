import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../presentation/blocs/app_settings/app_settings_state.dart';

class AppSettingsService {
  static const _boxName = 'app_settings';
  static const _themeModeKey = 'theme_mode';
  static const _languageKey = 'language';
  static const _skipSilenceKey = 'skip_silence';
  static const _defaultVolumeKey = 'default_volume';
  static const _defaultRepeatModeKey = 'default_repeat_mode';

  late Box _box;

  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  Future<AppSettingsSnapshot> loadSettings() async {
    return AppSettingsSnapshot(
      themeMode: _themeModeFromString(_box.get(_themeModeKey) as String?),
      language: _languageFromString(_box.get(_languageKey) as String?),
      skipSilence: (_box.get(_skipSilenceKey) as bool?) ?? false,
      defaultVolume: ((_box.get(_defaultVolumeKey) as num?) ?? 1.0)
          .toDouble()
          .clamp(0.0, 1.0),
      defaultRepeatMode: _repeatModeFromString(
        _box.get(_defaultRepeatModeKey) as String?,
      ),
    );
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    await _box.put(_themeModeKey, _themeModeToString(themeMode));
  }

  Future<void> saveLanguage(AppLanguage language) async {
    await _box.put(_languageKey, language.name);
  }

  Future<void> saveSkipSilence(bool enabled) async {
    await _box.put(_skipSilenceKey, enabled);
  }

  Future<void> saveDefaultVolume(double volume) async {
    await _box.put(_defaultVolumeKey, volume.clamp(0.0, 1.0));
  }

  Future<void> saveDefaultRepeatMode(DefaultRepeatMode repeatMode) async {
    await _box.put(_defaultRepeatModeKey, repeatMode.name);
  }

  Future<Map<String, dynamic>> exportSettings() async {
    return {
      _themeModeKey: _themeModeToString(
        _themeModeFromString(_box.get(_themeModeKey) as String?),
      ),
      _languageKey: _languageFromString(_box.get(_languageKey) as String?).name,
      _skipSilenceKey: (_box.get(_skipSilenceKey) as bool?) ?? false,
      _defaultVolumeKey: ((_box.get(_defaultVolumeKey) as num?) ?? 1.0)
          .toDouble()
          .clamp(0.0, 1.0),
      _defaultRepeatModeKey: _repeatModeFromString(
        _box.get(_defaultRepeatModeKey) as String?,
      ).name,
    };
  }

  Future<void> importSettings(Map<String, dynamic> data) async {
    await _box.put(
      _themeModeKey,
      _themeModeToString(_themeModeFromString(data[_themeModeKey] as String?)),
    );
    await _box.put(
      _languageKey,
      _languageFromString(data[_languageKey] as String?).name,
    );
    await _box.put(_skipSilenceKey, (data[_skipSilenceKey] as bool?) ?? false);
    await _box.put(
      _defaultVolumeKey,
      (((data[_defaultVolumeKey] as num?) ?? 1.0).toDouble()).clamp(0.0, 1.0),
    );
    await _box.put(
      _defaultRepeatModeKey,
      _repeatModeFromString(data[_defaultRepeatModeKey] as String?).name,
    );
  }

  ThemeMode _themeModeFromString(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  String _themeModeToString(ThemeMode value) {
    return switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  AppLanguage _languageFromString(String? value) {
    return switch (value) {
      'spanish' => AppLanguage.spanish,
      'english' => AppLanguage.english,
      _ => AppLanguage.system,
    };
  }

  DefaultRepeatMode _repeatModeFromString(String? value) {
    return switch (value) {
      'all' => DefaultRepeatMode.all,
      'one' => DefaultRepeatMode.one,
      _ => DefaultRepeatMode.off,
    };
  }
}

class AppSettingsSnapshot {
  const AppSettingsSnapshot({
    required this.themeMode,
    required this.language,
    required this.skipSilence,
    required this.defaultVolume,
    required this.defaultRepeatMode,
  });

  final ThemeMode themeMode;
  final AppLanguage language;
  final bool skipSilence;
  final double defaultVolume;
  final DefaultRepeatMode defaultRepeatMode;
}