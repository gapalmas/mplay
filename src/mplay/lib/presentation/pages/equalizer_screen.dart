import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/player/player_cubit.dart';
import '../blocs/player/player_state.dart';
import '../widgets/player_mini_player_bar.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  Future<void> _openEqualizer(BuildContext context) async {
    final opened = await context.read<PlayerCubit>().openEqualizer();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'Ecualizador del sistema abierto'
              : 'No se pudo abrir el ecualizador. Inicia reproducción primero o verifica tu dispositivo.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Ecualizador')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.equalizer_rounded),
                  title: const Text('Ecualizador del sistema'),
                  subtitle: Text(
                    state.audioSessionId != null
                        ? 'Sesión de audio activa detectada'
                        : 'Primero inicia la reproducción de una canción',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: state.audioSessionId != null
                    ? () => _openEqualizer(context)
                    : null,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Abrir ecualizador'),
              ),
              const SizedBox(height: 12),
              Text(
                'Este botón abre el panel de audio del dispositivo para ajustar bandas y efectos sobre la reproducción actual.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          bottomNavigationBar: const PlayerMiniPlayerBar(),
        );
      },
    );
  }
}
