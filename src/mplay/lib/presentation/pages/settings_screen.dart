import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../blocs/app_settings/app_settings_cubit.dart';
import '../blocs/app_settings/app_settings_state.dart';
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
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, settings) {
        return Scaffold(
          appBar: AppBar(title: const Text('Ajustes')),
          body: settings.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Apariencia',
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
                        child: const Column(
                          children: [
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.system,
                              title: Text('Seguir sistema'),
                            ),
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.light,
                              title: Text('Claro'),
                            ),
                            RadioListTile<ThemeMode>(
                              value: ThemeMode.dark,
                              title: Text('Oscuro'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reproducción',
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
                            title: const Text('Omitir silencios'),
                            subtitle: const Text(
                              'Se aplica durante la reproducción en Android.',
                            ),
                          ),
                          ListTile(
                            title: const Text('Volumen predeterminado'),
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
                            title: const Text('Repetición predeterminada'),
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
                              items: const [
                                DropdownMenuItem(
                                  value: DefaultRepeatMode.off,
                                  child: Text('Desactivada'),
                                ),
                                DropdownMenuItem(
                                  value: DefaultRepeatMode.all,
                                  child: Text('Repetir cola'),
                                ),
                                DropdownMenuItem(
                                  value: DefaultRepeatMode.one,
                                  child: Text('Repetir canción'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Idioma',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Idioma'),
                        subtitle: const Text('Se aplicará en toda la app.'),
                        trailing: DropdownButton<AppLanguage>(
                          value: settings.language,
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            context.read<AppSettingsCubit>().setLanguage(value);
                          },
                          items: const [
                            DropdownMenuItem(
                              value: AppLanguage.system,
                              child: Text('Seguir sistema'),
                            ),
                            DropdownMenuItem(
                              value: AppLanguage.spanish,
                              child: Text('Español'),
                            ),
                            DropdownMenuItem(
                              value: AppLanguage.english,
                              child: Text('English'),
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
                      child: const Text('Copia de seguridad y restauración'),
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
