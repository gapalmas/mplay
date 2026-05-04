import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../blocs/app_settings/app_settings_cubit.dart';
import '../blocs/app_settings/app_settings_state.dart';
import '../localization/app_strings.dart';
import '../widgets/player_mini_player_bar.dart';
import 'backup_restore_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, settings) {
        return Scaffold(
          appBar: AppBar(title: Text(strings.settingsTitle)),
          body: settings.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      strings.appearance,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Card(
                      child: RadioGroup<ThemeMode>(
                        groupValue: settings.themeMode,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          context.read<AppSettingsCubit>().setThemeMode(value);
                        },
                        child: Column(
                          children: [
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.system,
                              title: Text(strings.followSystem),
                            ),
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.light,
                              title: Text(strings.light),
                            ),
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.dark,
                              title: Text(strings.dark),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.playback,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Card(
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            value: settings.skipSilence,
                            onChanged: context
                                .read<AppSettingsCubit>()
                                .setSkipSilence,
                            title: Text(strings.skipSilence),
                            subtitle: Text(strings.skipSilenceDescription),
                          ),
                          ListTile(
                            title: Text(strings.defaultVolume),
                            subtitle: Text(
                              '${(settings.defaultVolume * 100).round()}%',
                            ),
                            trailing: SizedBox(
                              width: 160,
                              child: Slider(
                                value: settings.defaultVolume,
                                min: 0,
                                max: 1,
                                divisions: 20,
                                onChanged: context
                                    .read<AppSettingsCubit>()
                                    .setDefaultVolume,
                              ),
                            ),
                          ),
                          ListTile(
                            title: Text(strings.defaultRepeat),
                            trailing: DropdownButton<DefaultRepeatMode>(
                              value: settings.defaultRepeatMode,
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                context
                                    .read<AppSettingsCubit>()
                                    .setDefaultRepeatMode(value);
                              },
                              items: [
                                DropdownMenuItem(
                                  value: DefaultRepeatMode.off,
                                  child: Text(strings.repeatDisabled),
                                ),
                                DropdownMenuItem(
                                  value: DefaultRepeatMode.all,
                                  child: Text(strings.repeatQueue),
                                ),
                                DropdownMenuItem(
                                  value: DefaultRepeatMode.one,
                                  child: Text(strings.repeatSong),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.languageSection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Card(
                      child: ListTile(
                        title: Text(strings.language),
                        subtitle: Text(strings.languageDescription),
                        trailing: DropdownButton<AppLanguage>(
                          value: settings.language,
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            context.read<AppSettingsCubit>().setLanguage(value);
                          },
                          items: [
                            DropdownMenuItem(
                              value: AppLanguage.system,
                              child: Text(strings.followSystem),
                            ),
                            DropdownMenuItem(
                              value: AppLanguage.spanish,
                              child: Text(strings.spanish),
                            ),
                            DropdownMenuItem(
                              value: AppLanguage.english,
                              child: Text(strings.english),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BackupRestoreScreen(),
                          ),
                        );
                      },
                      child: Text(strings.backupAndRestore),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<PackageInfo>(
                      future: _packageInfoFuture,
                      builder: (context, snapshot) {
                        final version = snapshot.data;
                        final label = version == null
                            ? 'mplay'
                            : 'mplay v${version.version}+${version.buildNumber}';
                        return Center(
                          child: Text(
                            '$label • Flutter • Android',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ],
                ),
          bottomNavigationBar: const PlayerMiniPlayerBar(),
        );
      },
    );
  }
}
