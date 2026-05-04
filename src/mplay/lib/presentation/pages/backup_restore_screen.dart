import 'package:flutter/material.dart';

import '../widgets/player_mini_player_bar.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool playlists = true;
  bool favorites = true;
  bool settings = true;
  bool lyricsCache = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Copia de seguridad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Exportar', style: Theme.of(context).textTheme.titleMedium),
          Card(
            child: Column(
              children: [
                CheckboxListTile(
                  value: playlists,
                  onChanged: (value) => setState(() => playlists = value ?? false),
                  title: const Text('Playlists'),
                ),
                CheckboxListTile(
                  value: favorites,
                  onChanged: (value) => setState(() => favorites = value ?? false),
                  title: const Text('Favoritos'),
                ),
                CheckboxListTile(
                  value: settings,
                  onChanged: (value) => setState(() => settings = value ?? false),
                  title: const Text('Configuración de la app'),
                ),
                CheckboxListTile(
                  value: lyricsCache,
                  onChanged: (value) => setState(() => lyricsCache = value ?? false),
                  title: const Text('Letras en caché'),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Exportar backup...'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Importar', style: Theme.of(context).textTheme.titleMedium),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('Seleccionar archivo .zip...'),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '⚠ Advertencia: importar reemplazará los datos existentes. Esta acción no se puede deshacer.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Historial', style: Theme.of(context).textTheme.titleMedium),
          Card(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Fecha')),
                DataColumn(label: Text('Operación')),
                DataColumn(label: Text('Estado')),
              ],
              rows: const [
                DataRow(
                  cells: [
                    DataCell(Text('2026-05-01 10:30')),
                    DataCell(Text('Exportar')),
                    DataCell(Text('✓ OK')),
                  ],
                ),
                DataRow(
                  cells: [
                    DataCell(Text('2026-04-29 08:15')),
                    DataCell(Text('Importar')),
                    DataCell(Text('✓ OK')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PlayerMiniPlayerBar(),
    );
  }
}
