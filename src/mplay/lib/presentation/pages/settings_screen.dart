import 'package:flutter/material.dart';

import '../widgets/player_mini_player_bar.dart';
import 'backup_restore_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode selectedTheme = ThemeMode.system;
  bool skipSilence = true;
  int crossfadeSeconds = 3;
  String language = 'Español (ES)';
  String defaultEq = 'Rock';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Apariencia', style: Theme.of(context).textTheme.titleMedium),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: selectedTheme,
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => selectedTheme = value);
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
          Text('Reproducción', style: Theme.of(context).textTheme.titleMedium),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: skipSilence,
                  onChanged: (value) => setState(() => skipSilence = value),
                  title: const Text('Omitir silencios'),
                ),
                ListTile(
                  title: const Text('Crossfade'),
                  subtitle: Text('$crossfadeSeconds seg'),
                  trailing: SizedBox(
                    width: 140,
                    child: Slider(
                      value: crossfadeSeconds.toDouble(),
                      min: 0,
                      max: 12,
                      divisions: 12,
                      onChanged: (value) {
                        setState(() => crossfadeSeconds = value.round());
                      },
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('EQ predeterminado'),
                  trailing: DropdownButton<String>(
                    value: defaultEq,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => defaultEq = value);
                    },
                    items: const [
                      DropdownMenuItem(value: 'Plano', child: Text('Plano')),
                      DropdownMenuItem(value: 'Rock', child: Text('Rock')),
                      DropdownMenuItem(value: 'Pop', child: Text('Pop')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Idioma', style: Theme.of(context).textTheme.titleMedium),
          Card(
            child: ListTile(
              title: const Text('Idioma'),
              trailing: DropdownButton<String>(
                value: language,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => language = value);
                },
                items: const [
                  DropdownMenuItem(
                    value: 'Español (ES)',
                    child: Text('Español (ES)'),
                  ),
                  DropdownMenuItem(
                    value: 'English (US)',
                    child: Text('English (US)'),
                  ),
                  DropdownMenuItem(
                    value: 'System default',
                    child: Text('System default'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
              );
            },
            child: const Text('Copia de seguridad y restauración'),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'mplay v1.0.0 • Flutter • Android',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PlayerMiniPlayerBar(),
    );
  }
}
