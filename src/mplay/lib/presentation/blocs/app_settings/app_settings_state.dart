import 'package:flutter/material.dart';

enum AppLanguage { system, spanish, english }

enum DefaultRepeatMode { off, all, one }

class AppSettingsState {
  const AppSettingsState({
    this.isLoading = true,
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.system,
    this.skipSilence = false,
    this.defaultVolume = 1.0,
    this.defaultRepeatMode = DefaultRepeatMode.off,
  });

  final bool isLoading;
  final ThemeMode themeMode;
  final AppLanguage language;
  final bool skipSilence;
  final double defaultVolume;
  final DefaultRepeatMode defaultRepeatMode;

  AppSettingsState copyWith({
    bool? isLoading,
    ThemeMode? themeMode,
    AppLanguage? language,
    bool? skipSilence,
    double? defaultVolume,
    DefaultRepeatMode? defaultRepeatMode,
  }) {
    return AppSettingsState(
      isLoading: isLoading ?? this.isLoading,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      skipSilence: skipSilence ?? this.skipSilence,
      defaultVolume: defaultVolume ?? this.defaultVolume,
      defaultRepeatMode: defaultRepeatMode ?? this.defaultRepeatMode,
    );
  }
}