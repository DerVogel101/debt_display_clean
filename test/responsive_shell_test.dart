import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:debt_display/generated/debt.pb.dart';
import 'package:debt_display/state/auth_session_state.dart';
import 'package:debt_display/state/bill_list_state.dart';
import 'package:debt_display/state/navigation_state.dart';
import 'package:debt_display/state/theme_state.dart';
import 'package:debt_display/theme/app_themes.dart';
import 'package:debt_display/ui/app_sections.dart';
import 'package:debt_display/ui/bills_section.dart';
import 'package:debt_display/ui/app_shell.dart';
import 'package:debt_display/services/debt_backend_service.dart';
import 'package:dio/dio.dart';
import 'package:fixnum/fixnum.dart';
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

  testWidgets('home dashboard bill list button opens bills destination', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);
    final navigationState = NavigationState();

    await tester.pumpWidget(
      _buildHomeSectionTestApp(
        authState: _TestAuthSessionState(),
        navigationState: navigationState,
        referenceDate: _fixedReferenceDate,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-bill-list-button')));
    await tester.pump();

    expect(navigationState.selectedDestination, AppDestination.bills);
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

  testWidgets(
    'home dashboard generates placeholder due dates from reference date',
    (tester) async {
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
    },
  );

  testWidgets('mobile bottom navigation shows home, bills, and menu', (
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
      find.descendant(of: navigationBar, matching: find.text('Bills')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigationBar, matching: find.text('Menu')),
      findsOneWidget,
    );
  });

  testWidgets('menu section includes bills navigation action', (tester) async {
    final navigationState = NavigationState()
      ..selectDestination(AppDestination.menu);
    _setTestSurfaceSize(tester, width: 430, height: 900);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(),
        navigationState: navigationState,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Open the full bills view with filters, sorting, and pagination controls.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.text(
        'Open the full bills view with filters, sorting, and pagination controls.',
      ),
    );
    await tester.pumpAndSettle();

    expect(navigationState.selectedDestination, AppDestination.bills);
  });

  testWidgets('bills view shows login prompt when unauthenticated', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: _TestAuthSessionState(),
        billListState: BillListState(
          debtBackendService: _FakeDebtBackendService(
            onListReceipts: (_) => ReceiptsResponse(success: true),
          ),
        ),
      ),
    );

    expect(find.text('Log in to view bills'), findsOneWidget);
    expect(find.byKey(const ValueKey('bills-login-button')), findsOneWidget);
  });

  testWidgets('bills filter changes reload and reset pagination to page 1', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final fakeService = _FakeDebtBackendService(
      availableTags: const [],
      onListReceipts: (request) {
        final response = ReceiptsResponse(success: true);
        if (request.hasIsPaid() && request.isPaid) {
          response.receipts.add(
            _testReceipt(
              id: 91,
              title: 'Paid only',
              amountOwed: 12,
              isPaid: true,
            ),
          );
          return response;
        }
        if (request.hasPageToken() && request.pageToken == 'page-2') {
          response.receipts.add(
            _testReceipt(id: 2, title: 'Page 2 receipt', amountOwed: 24),
          );
          return response;
        }
        response.receipts.add(
          _testReceipt(id: 1, title: 'Page 1 receipt', amountOwed: 18),
        );
        response.nextPageToken = 'page-2';
        return response;
      },
    );
    final billListState = BillListState(debtBackendService: fakeService);

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        billListState: billListState,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page 1 receipt'), findsOneWidget);
    expect(find.byKey(const ValueKey('bills-page-indicator')), findsOneWidget);
    expect(find.text('Page 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bills-page-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('Page 2 receipt'), findsOneWidget);
    expect(find.text('Page 2'), findsOneWidget);

    await tester.tap(find.text('Paid'));
    await tester.pumpAndSettle();

    expect(find.text('Paid only'), findsOneWidget);
    expect(find.text('Page 1'), findsOneWidget);
    expect(fakeService.requests.last.hasPageToken(), isFalse);
    expect(fakeService.requests.last.hasIsPaid(), isTrue);
    expect(fakeService.requests.last.isPaid, isTrue);
  });

  testWidgets('bills pagination works across id, total, and due-date sorts', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final fakeService = _FakeDebtBackendService(
      availableTags: const [],
      onListReceipts: (request) {
        final response = ReceiptsResponse(success: true);
        final orderBy = request.orderBy;
        final pageToken = request.hasPageToken() ? request.pageToken : null;

        if (orderBy == ReceiptOrderBy.RECEIPT_ORDER_BY_COST_TOTAL) {
          if (pageToken == 'total-page-2') {
            response.receipts.add(
              _testReceipt(id: 22, title: 'Total page 2', amountOwed: 70),
            );
          } else {
            response.receipts.add(
              _testReceipt(id: 21, title: 'Total page 1', amountOwed: 20),
            );
            response.nextPageToken = 'total-page-2';
          }
          return response;
        }

        if (orderBy == ReceiptOrderBy.RECEIPT_ORDER_BY_DUE_DATE) {
          if (pageToken == 'due-page-2') {
            response.receipts.add(
              _testReceipt(
                id: 32,
                title: 'Due page 2',
                amountOwed: 40,
                dueDate: '2026-05-07T00:00:00Z',
              ),
            );
          } else {
            response.receipts.add(
              _testReceipt(
                id: 31,
                title: 'Due page 1',
                amountOwed: 25,
                dueDate: '2026-05-04T00:00:00Z',
              ),
            );
            response.nextPageToken = 'due-page-2';
          }
          return response;
        }

        if (pageToken == 'id-page-2') {
          response.receipts.add(
            _testReceipt(id: 12, title: 'ID page 2', amountOwed: 15),
          );
        } else {
          response.receipts.add(
            _testReceipt(id: 11, title: 'ID page 1', amountOwed: 10),
          );
          response.nextPageToken = 'id-page-2';
        }
        return response;
      },
    );
    final billListState = BillListState(debtBackendService: fakeService);

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        billListState: billListState,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ID page 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bills-page-next-button')));
    await tester.pumpAndSettle();
    expect(find.text('ID page 2'), findsOneWidget);

    await _selectDropdownItem(
      tester,
      const ValueKey('bills-sort-dropdown'),
      'Total',
    );
    await tester.pumpAndSettle();
    expect(find.text('Total page 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bills-page-next-button')));
    await tester.pumpAndSettle();
    expect(find.text('Total page 2'), findsOneWidget);

    await _selectDropdownItem(
      tester,
      const ValueKey('bills-sort-dropdown'),
      'Due date',
    );
    await tester.pumpAndSettle();
    expect(find.text('Due page 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bills-page-next-button')));
    await tester.pumpAndSettle();
    expect(find.text('Due page 2'), findsOneWidget);
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

    expect(navigationBar.selectedIndex, 2);
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
  BillListState? billListState,
  Locale locale = const Locale('en', 'US'),
}) {
  final resolvedBillListState =
      billListState ??
      BillListState(
        debtBackendService: _FakeDebtBackendService(
          onListReceipts: (_) => ReceiptsResponse(success: true),
        ),
      );
  resolvedBillListState.updateAuthSession(authState);

  return MaterialApp(
    locale: locale,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: _supportedLocales,
    theme: buildLightTheme(),
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSessionState>.value(value: authState),
        ChangeNotifierProvider<NavigationState>.value(value: navigationState),
        ChangeNotifierProvider<ThemeState>(create: (_) => ThemeState()),
        ChangeNotifierProvider<BillListState>.value(
          value: resolvedBillListState,
        ),
      ],
      child: const ResponsiveShell(),
    ),
  );
}

Widget _buildHomeSectionTestApp({
  required _TestAuthSessionState authState,
  NavigationState? navigationState,
  Locale locale = const Locale('en', 'US'),
  DateTime? referenceDate,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: _supportedLocales,
    theme: buildLightTheme(),
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSessionState>.value(value: authState),
        ChangeNotifierProvider<NavigationState>.value(
          value: navigationState ?? NavigationState(),
        ),
      ],
      child: Scaffold(
        body: SingleChildScrollView(
          child: HomeSection(isDesktop: false, referenceDate: referenceDate),
        ),
      ),
    ),
  );
}

Widget _buildBillsSectionTestApp({
  required _TestAuthSessionState authState,
  required BillListState billListState,
  Locale locale = const Locale('en', 'US'),
}) {
  billListState.updateAuthSession(authState);

  return MaterialApp(
    locale: locale,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: _supportedLocales,
    theme: buildLightTheme(),
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSessionState>.value(value: authState),
        ChangeNotifierProvider<BillListState>.value(value: billListState),
      ],
      child: const Scaffold(
        body: SingleChildScrollView(child: BillsSection(isDesktop: false)),
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

Future<void> _selectDropdownItem(
  WidgetTester tester,
  Key fieldKey,
  String itemLabel,
) async {
  await tester.tap(find.byKey(fieldKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text(itemLabel).last);
  await tester.pumpAndSettle();
}

Receipt _testReceipt({
  required int id,
  required String title,
  required double amountOwed,
  bool isPaid = false,
  int ownerId = 10,
  String? dueDate,
}) {
  return Receipt(
    id: Int64(id),
    title: title,
    amountOwed: amountOwed,
    isPaid: isPaid,
    currency: 'EUR',
    ownerId: Int64(ownerId),
    recipientName: 'Shared group',
    dueDate: dueDate,
  );
}

class _FakeDebtBackendService extends DebtBackendService {
  _FakeDebtBackendService({
    required this.onListReceipts,
    this.availableTags = const [],
  }) : super(dio: Dio());

  final List<TagIndex> availableTags;
  final ReceiptsResponse Function(ReceiptListRequest request) onListReceipts;
  final List<ReceiptListRequest> requests = <ReceiptListRequest>[];

  @override
  Future<ReceiptsResponse> listReceipts(
    String accessToken,
    ReceiptListRequest request,
  ) async {
    final clonedRequest = request.deepCopy();
    requests.add(clonedRequest);
    return onListReceipts(clonedRequest);
  }

  @override
  Future<TagsResponse> listTags(String accessToken) async {
    final response = TagsResponse(success: true);
    response.tags.addAll(availableTags.map((tag) => tag.deepCopy()));
    return response;
  }
}

class _TestAuthSessionState extends ChangeNotifier implements AuthSessionState {
  _TestAuthSessionState({
    this.isAuthenticatedValue = false,
    this.displayNameValue,
    this.userEmailValue,
    this.accessTokenValue,
    this.userIdValue,
  });

  final bool isAuthenticatedValue;
  final String? displayNameValue;
  final String? userEmailValue;
  final String? accessTokenValue;
  final int? userIdValue;

  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Credentials? get credentials => null;

  @override
  String? get backendError => null;

  @override
  String? get accessToken => accessTokenValue;

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
  int? get userId => userIdValue;

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
