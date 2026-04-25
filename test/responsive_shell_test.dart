import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:debt_display/state/navigation_state.dart';
import 'package:debt_display/theme/app_themes.dart';
import 'package:debt_display/ui/app_sections.dart';
import 'package:debt_display/ui/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('home dashboard shows five placeholder bills and total owed', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    await tester.pumpWidget(
      _buildHomeSectionTestApp(authState: _TestAuthSessionState()),
    );

    expect(find.text('Recent outstanding bills'), findsOneWidget);
    expect(find.textContaining('Due '), findsNWidgets(5));
    expect(find.text('Due 02.05.26'), findsOneWidget);
    expect(find.text('Studio rent top-up'), findsOneWidget);
    expect(find.text('Quarterly electricity bill'), findsOneWidget);
    expect(find.text('Spring grocery split'), findsOneWidget);
    expect(find.text('Weekend train tickets'), findsOneWidget);
    expect(find.text('Internet renewal'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Open bill list'), findsOneWidget);
    expect(find.text('Total still owed'), findsOneWidget);
    expect(find.text('1.357,63€'), findsOneWidget);
  });

  testWidgets('home dashboard bill list button shows a placeholder snackbar', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    await tester.pumpWidget(
      _buildHomeSectionTestApp(authState: _TestAuthSessionState()),
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
        _buildHomeSectionTestApp(authState: _TestAuthSessionState()),
      );

      expect(find.text('+5'), findsOneWidget);
    },
  );

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

Widget _buildHomeSectionTestApp({required _TestAuthSessionState authState}) {
  return MaterialApp(
    theme: buildLightTheme(),
    home: ChangeNotifierProvider<AuthSessionState>.value(
      value: authState,
      child: const Scaffold(
        body: SingleChildScrollView(child: HomeSection(isDesktop: false)),
      ),
    ),
  );
}

Widget _buildResponsiveShellTestApp({
  required _TestAuthSessionState authState,
  required NavigationState navigationState,
}) {
  return MaterialApp(
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
