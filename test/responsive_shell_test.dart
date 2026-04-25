import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:debt_display/state/navigation_state.dart';
import 'package:debt_display/theme/app_themes.dart';
import 'package:debt_display/ui/app_sections.dart';
import 'package:debt_display/ui/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const _supportedLocales = [Locale('en'), Locale('de')];
final _fixedReferenceDate = DateTime(2026, 4, 25);

void main() {
  testWidgets('home dashboard formats amounts and dates for en_US locale', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    await tester.pumpWidget(
      _buildHomeSectionTestApp(
        authState: _TestAuthSessionState(),
        locale: const Locale('en', 'US'),
        referenceDate: _fixedReferenceDate,
      ),
    );

    final materialLocalizations = _homeMaterialLocalizations(tester);
    final expectedDue = materialLocalizations.formatShortDate(
      _placeholderDueDate(_fixedReferenceDate, 7),
    );
    final expectedAmount = _formatExpectedCurrency(
      1357.63,
      const Locale('en', 'US'),
    );

    expect(find.text('Recent outstanding bills'), findsOneWidget);
    expect(find.textContaining('Due '), findsNWidgets(5));
    expect(find.text('Due $expectedDue'), findsOneWidget);
    expect(find.text('Studio rent top-up'), findsOneWidget);
    expect(find.text('Quarterly electricity bill'), findsOneWidget);
    expect(find.text('Spring grocery split'), findsOneWidget);
    expect(find.text('Weekend train tickets'), findsOneWidget);
    expect(find.text('Internet renewal'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Open bill list'), findsOneWidget);
    expect(find.text('Total still owed'), findsOneWidget);
    expect(find.text(expectedAmount), findsOneWidget);
  });

  testWidgets('home dashboard formats amounts and dates for de_DE locale', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    await tester.pumpWidget(
      _buildHomeSectionTestApp(
        authState: _TestAuthSessionState(),
        locale: const Locale('de', 'DE'),
        referenceDate: _fixedReferenceDate,
      ),
    );

    final materialLocalizations = _homeMaterialLocalizations(tester);
    final expectedDue = materialLocalizations.formatShortDate(
      _placeholderDueDate(_fixedReferenceDate, 7),
    );
    final expectedAmount = _formatExpectedCurrency(
      1357.63,
      const Locale('de', 'DE'),
    );

    expect(find.text('Due $expectedDue'), findsOneWidget);
    expect(find.text(expectedAmount), findsOneWidget);
  });

  testWidgets('home dashboard bill list button shows a placeholder snackbar', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    await tester.pumpWidget(
      _buildHomeSectionTestApp(
        authState: _TestAuthSessionState(),
        referenceDate: _fixedReferenceDate,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-bill-list-button')));
    await tester.pump();

    expect(find.text('Bill list placeholder coming soon.'), findsOneWidget);
  });

  testWidgets(
    'home dashboard collapses hidden bill tags into an overflow chip',
    (tester) async {
      _setTestSurfaceSize(tester, width: 320, height: 1000);

      await tester.pumpWidget(
        _buildHomeSectionTestApp(
          authState: _TestAuthSessionState(),
          referenceDate: _fixedReferenceDate,
        ),
      );

      expect(find.text('+5'), findsOneWidget);
    },
  );

  testWidgets('home dashboard generates placeholder due dates from reference date', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final referenceDate = DateTime(2030, 1, 10);
    await tester.pumpWidget(
      _buildHomeSectionTestApp(
        authState: _TestAuthSessionState(),
        locale: const Locale('en', 'US'),
        referenceDate: referenceDate,
      ),
    );

    final materialLocalizations = _homeMaterialLocalizations(tester);
    const dueOffsets = [7, 5, 4, 2, 1];
    for (final dueOffset in dueOffsets) {
      final expectedDue = materialLocalizations.formatShortDate(
        _placeholderDueDate(referenceDate, dueOffset),
      );
      expect(find.text('Due $expectedDue'), findsOneWidget);
    }
  });

  testWidgets('mobile bottom navigation only shows home and menu', (
    tester,
  ) async {
    final navigationState = NavigationState();
    _setTestSurfaceSize(tester, width: 430, height: 900);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(),
        navigationState: navigationState,
      ),
    );
    await tester.pumpAndSettle();

    final navigationBar = find.byKey(const ValueKey('mobile-navigation-bar'));

    expect(navigationBar, findsOneWidget);
    expect(
      find.descendant(of: navigationBar, matching: find.text('Home')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigationBar, matching: find.text('Menu')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigationBar, matching: find.text('Profile')),
      findsNothing,
    );
  });

  testWidgets('mobile profile state maps to the menu bottom-nav selection', (
    tester,
  ) async {
    final navigationState = NavigationState()
      ..selectDestination(AppDestination.profile);
    _setTestSurfaceSize(tester, width: 430, height: 900);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(),
        navigationState: navigationState,
      ),
    );
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byKey(const ValueKey('mobile-navigation-bar')),
    );

    expect(navigationBar.selectedIndex, 1);
  });

  testWidgets('desktop account summary opens profile', (tester) async {
    final navigationState = NavigationState();
    _setTestSurfaceSize(tester, width: 1280, height: 900);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          displayNameValue: 'Taylor Smith',
          userEmailValue: 'taylor@example.com',
        ),
        navigationState: navigationState,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('desktop-account-summary')));
    await tester.pumpAndSettle();

    expect(navigationState.selectedDestination, AppDestination.profile);
  });

  testWidgets('desktop logout button only logs out', (tester) async {
    final authState = _TestAuthSessionState(
      isAuthenticatedValue: true,
      displayNameValue: 'Taylor Smith',
      userEmailValue: 'taylor@example.com',
    );
    final navigationState = NavigationState();
    _setTestSurfaceSize(tester, width: 1280, height: 900);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: authState,
        navigationState: navigationState,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('desktop-logout-button')));
    await tester.pump();

    expect(authState.logoutCalls, 1);
    expect(navigationState.selectedDestination, AppDestination.home);
  });
}

Widget _buildResponsiveShellTestApp({
  required _TestAuthSessionState authState,
  required NavigationState navigationState,
  Locale locale = const Locale('en', 'US'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: _supportedLocales,
    theme: buildLightTheme(),
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSessionState>.value(value: authState),
        ChangeNotifierProvider<NavigationState>.value(value: navigationState),
      ],
      child: const ResponsiveShell(),
    ),
  );
}

Widget _buildHomeSectionTestApp({
  required _TestAuthSessionState authState,
  Locale locale = const Locale('en', 'US'),
  DateTime? referenceDate,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: _supportedLocales,
    theme: buildLightTheme(),
    home: ChangeNotifierProvider<AuthSessionState>.value(
      value: authState,
      child: Scaffold(
        body: SingleChildScrollView(
          child: HomeSection(
            isDesktop: false,
            referenceDate: referenceDate,
          ),
        ),
      ),
    ),
  );
}

MaterialLocalizations _homeMaterialLocalizations(WidgetTester tester) {
  return MaterialLocalizations.of(tester.element(find.byType(HomeSection)));
}

DateTime _placeholderDueDate(DateTime referenceDate, int dueInDays) {
  final baseDate = DateTime(
    referenceDate.year,
    referenceDate.month,
    referenceDate.day,
  );
  return baseDate.add(Duration(days: dueInDays));
}

String _formatExpectedCurrency(double amount, Locale locale) {
  return NumberFormat.currency(
    locale: locale.toString(),
    symbol: '€',
    decimalDigits: 2,
  ).format(amount);
}

void _setTestSurfaceSize(
  WidgetTester tester, {
  required double width,
  required double height,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _TestAuthSessionState extends ChangeNotifier implements AuthSessionState {
  _TestAuthSessionState({
    this.isAuthenticatedValue = false,
    this.displayNameValue,
    this.userEmailValue,
  });

  final bool isAuthenticatedValue;
  final String? displayNameValue;
  final String? userEmailValue;

  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Credentials? get credentials => null;

  @override
  String? get backendError => null;

  @override
  String? get displayName => displayNameValue;

  @override
  String get greeting {
    final name = displayNameValue;
    if (name == null || name.isEmpty) {
      return 'Hi there';
    }
    return 'Hi, $name';
  }

  @override
  bool get isAuthenticated => isAuthenticatedValue;

  @override
  bool get isLoading => false;

  @override
  String? get userEmail => userEmailValue;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isTokenValid(String token) async => true;

  @override
  Future<void> login() async {
    loginCalls += 1;
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
  }
}
