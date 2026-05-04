import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'presentation/blocs/app_settings/app_settings_cubit.dart';
import 'presentation/blocs/app_settings/app_settings_state.dart';
import 'presentation/blocs/library/library_cubit.dart';
import 'presentation/blocs/player/player_cubit.dart';
import 'presentation/pages/home_screen.dart';

class MPlayApp extends StatelessWidget {
  const MPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppSettingsCubit()),
        BlocProvider(create: (_) => LibraryCubit()),
        BlocProvider(create: (context) => PlayerCubit(context.read<AppSettingsCubit>())),
      ],
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, settings) {
          return MaterialApp(
            title: 'mplay',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            locale: _localeForLanguage(settings.language),
            supportedLocales: const [Locale('es'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            home: const HomeScreen(),
          );
        },
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

  Locale? _localeForLanguage(AppLanguage language) {
    return switch (language) {
      AppLanguage.spanish => const Locale('es'),
      AppLanguage.english => const Locale('en'),
      AppLanguage.system => null,
    };
  }
}
