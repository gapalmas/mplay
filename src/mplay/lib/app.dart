import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'presentation/blocs/library/library_cubit.dart';
import 'presentation/blocs/player/player_cubit.dart';
import 'presentation/pages/home_screen.dart';

class MPlayApp extends StatelessWidget {
  const MPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LibraryCubit()),
        BlocProvider(create: (_) => PlayerCubit()),
      ],
      child: MaterialApp(
        title: 'mplay',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: const HomeScreen(),
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final seedColor = brightness == Brightness.dark
        ? const Color(0xFF7DD3FC)
        : const Color(0xFF2563EB);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      cardTheme: const CardThemeData(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
