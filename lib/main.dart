import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:debt_display/auth0_service.dart';
import 'package:debt_display/config/app_config.dart';
import 'package:debt_display/services/auth_backend_service.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:debt_display/state/navigation_state.dart';
import 'package:debt_display/state/theme_state.dart';
import 'package:debt_display/ui/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  await Auth0Service.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationState()),
        ChangeNotifierProvider(create: (_) => ThemeState()..load()),
        ChangeNotifierProvider(
          create: (_) => AuthSessionState(
            auth0Service: Auth0Service(),
            authBackendService: AuthBackendService(),
          )..initialize(),
        ),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ThemeState, ThemeMode>(
      (state) => state.materialThemeMode,
    );
    final lightTheme = context.select<ThemeState, ThemeData>(
      (state) => state.lightTheme,
    );
    final darkTheme = context.select<ThemeState, ThemeData>(
      (state) => state.darkTheme,
    );

    return MaterialApp(
      title: 'debt_display',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en'), Locale('de')],
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const MainView(),
    );
  }
}

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveShell();
  }
}
