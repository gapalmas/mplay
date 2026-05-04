import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/app_settings_service.dart';
import 'app_settings_state.dart';

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit()
      : _service = AppSettingsService(),
        super(const AppSettingsState()) {
    loadSettings();
  }

  final AppSettingsService _service;

  Future<void> loadSettings() async {
    await _service.initialize();
    final snapshot = await _service.loadSettings();
    emit(
      state.copyWith(
        isLoading: false,
        themeMode: snapshot.themeMode,
        language: snapshot.language,
        skipSilence: snapshot.skipSilence,
        defaultVolume: snapshot.defaultVolume,
        defaultRepeatMode: snapshot.defaultRepeatMode,
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _service.saveThemeMode(themeMode);
    emit(state.copyWith(themeMode: themeMode));
  }

  Future<void> setLanguage(AppLanguage language) async {
    await _service.saveLanguage(language);
    emit(state.copyWith(language: language));
  }

  Future<void> setSkipSilence(bool enabled) async {
    await _service.saveSkipSilence(enabled);
    emit(state.copyWith(skipSilence: enabled));
  }

  Future<void> setDefaultVolume(double volume) async {
    final normalized = volume.clamp(0.0, 1.0);
    await _service.saveDefaultVolume(normalized);
    emit(state.copyWith(defaultVolume: normalized));
  }

  Future<void> setDefaultRepeatMode(DefaultRepeatMode repeatMode) async {
    await _service.saveDefaultRepeatMode(repeatMode);
    emit(state.copyWith(defaultRepeatMode: repeatMode));
  }

  Future<Map<String, dynamic>> exportSettings() => _service.exportSettings();

  Future<void> importSettings(Map<String, dynamic> data) async {
    await _service.importSettings(data);
    await loadSettings();
  }
}