import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:debt_display/auth0_service.dart';
import 'package:debt_display/config/app_config.dart';
import 'package:debt_display/services/auth_backend_service.dart';
import 'package:debt_display/services/debt_backend_service.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:debt_display/state/bill_creation_state.dart';
import 'package:debt_display/state/bill_list_state.dart';
import 'package:debt_display/state/chart_state.dart';
import 'package:debt_display/state/home_bill_state.dart';
import 'package:debt_display/state/language_state.dart';
import 'package:debt_display/state/navigation_state.dart';
import 'package:debt_display/state/privacy_consent_state.dart';
import 'package:debt_display/state/recipient_group_state.dart';
import 'package:debt_display/state/theme_state.dart';
import 'package:debt_display/ui/app_shell.dart';
import 'package:debt_display/ui/privacy_policy.dart';
import 'package:debt_display/l10n/generated/app_localizations.dart';

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
        ChangeNotifierProvider(create: (_) => LanguageState()..load()),
        ChangeNotifierProvider(create: (_) => PrivacyConsentState()..load()),
        ChangeNotifierProxyProvider<PrivacyConsentState, AuthSessionState>(
          create: (_) => AuthSessionState(
            auth0Service: Auth0Service(),
            authBackendService: AuthBackendService(),
          ),
          update: (_, privacyConsentState, authSessionState) {
            final state = authSessionState!;
            if (privacyConsentState.hasAcceptedCurrentVersion) {
              unawaited(state.initialize());
            }
            return state;
          },
        ),
        ChangeNotifierProxyProvider<AuthSessionState, BillListState>(
          create: (_) =>
              BillListState(debtBackendService: DebtBackendService()),
          update: (_, authSessionState, billListState) =>
              billListState!..updateAuthSession(authSessionState),
        ),
        ChangeNotifierProxyProvider<AuthSessionState, BillCreationState>(
          create: (_) =>
              BillCreationState(debtBackendService: DebtBackendService()),
          update: (_, authSessionState, billCreationState) =>
              billCreationState!..updateAuthSession(authSessionState),
        ),
        ChangeNotifierProxyProvider<AuthSessionState, HomeBillState>(
          create: (_) =>
              HomeBillState(debtBackendService: DebtBackendService()),
          update: (_, authSessionState, homeBillState) =>
              homeBillState!..updateAuthSession(authSessionState),
        ),
        ChangeNotifierProxyProvider<AuthSessionState, ChartState>(
          create: (_) => ChartState(debtBackendService: DebtBackendService()),
          update: (_, authSessionState, chartState) =>
              chartState!..updateAuthSession(authSessionState),
        ),
        ChangeNotifierProxyProvider<AuthSessionState, RecipientGroupState>(
          create: (_) =>
              RecipientGroupState(debtBackendService: DebtBackendService()),
          update: (_, authSessionState, recipientGroupState) =>
              recipientGroupState!..updateAuthSession(authSessionState),
        ),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  Timer? _autoFetchTimer;
  bool _isAutoFetching = false;

  @override
  void dispose() {
    _autoFetchTimer?.cancel();
    super.dispose();
  }

  void _configureAutoFetch(bool isLoggedIn) {
    final interval = AppConfig.autoFetchInterval;
    if (!isLoggedIn || interval == null) {
      _autoFetchTimer?.cancel();
      _autoFetchTimer = null;
      return;
    }
    if (_autoFetchTimer != null) {
      return;
    }
    _autoFetchTimer = Timer.periodic(interval, (_) => _runAutoFetch());
  }

  Future<void> _runAutoFetch() async {
    if (!mounted || _isAutoFetching) {
      return;
    }
    final authState = context.read<AuthSessionState>();
    if (!authState.isAuthenticated || authState.accessToken == null) {
      _autoFetchTimer?.cancel();
      _autoFetchTimer = null;
      return;
    }
    _isAutoFetching = true;
    try {
      await Future.wait([
        context.read<HomeBillState>().refresh(),
        context.read<BillListState>().refresh(),
        context.read<ChartState>().refresh(),
        context.read<BillCreationState>().refresh(),
        context.read<RecipientGroupState>().refresh(),
      ]);
    } finally {
      _isAutoFetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<AuthSessionState, bool>(
      (state) => state.isAuthenticated && state.accessToken != null,
    );
    final themeMode = context.select<ThemeState, ThemeMode>(
      (state) => state.materialThemeMode,
    );
    final lightTheme = context.select<ThemeState, ThemeData>(
      (state) => state.lightTheme,
    );
    final darkTheme = context.select<ThemeState, ThemeData>(
      (state) => state.darkTheme,
    );
    final locale = context.select<LanguageState, Locale?>(
      (state) => state.locale,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _configureAutoFetch(isLoggedIn);
      }
    });

    return MaterialApp(
      title: 'debt_display',
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [Locale('en'), Locale('de')],
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const PrivacyConsentGate(child: MainView()),
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
