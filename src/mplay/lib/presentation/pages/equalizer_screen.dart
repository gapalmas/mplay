import 'package:flutter/material.dart';

import '../widgets/player_mini_player_bar.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  bool enabled = true;
  String profile = 'Rock';
  final frequencies = ['60Hz', '170Hz', '310Hz', '600Hz', '1kHz', '3kHz'];
  late final List<double> values = [5, 2, 0, -1, 3, 4];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ecualizador')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile.adaptive(
              value: enabled,
              onChanged: (value) => setState(() => enabled = value),
              title: const Text('Ecualizador activo'),
              subtitle: Text(enabled ? 'ON' : 'OFF'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Perfil'),
              trailing: DropdownButton<String>(
                value: profile,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => profile = value);
                },
                items: const [
                  DropdownMenuItem(value: 'Plano', child: Text('Plano')),
                  DropdownMenuItem(value: 'Rock', child: Text('Rock')),
                  DropdownMenuItem(value: 'Pop', child: Text('Pop')),
                  DropdownMenuItem(value: 'Jazz', child: Text('Jazz')),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: List.generate(frequencies.length, (index) {
                  return Row(
                    children: [
                      SizedBox(width: 56, child: Text(frequencies[index])),
                      Expanded(
                        child: Slider(
                          value: values[index],
                          min: -12,
                          max: 12,
                          divisions: 24,
                          label: values[index].toStringAsFixed(0),
                          onChanged: enabled
                              ? (value) {
                                  setState(() => values[index] = value);
                                }
                              : null,
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(values[index].toStringAsFixed(0)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () {
              setState(() {
                for (var index = 0; index < values.length; index++) {
                  values[index] = 0;
                }
              });
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Restablecer'),
          ),
        ],
      ),
      bottomNavigationBar: const PlayerMiniPlayerBar(),
    );
  }
}
