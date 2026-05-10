import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:debt_display/generated/debt.pb.dart';
import 'package:debt_display/l10n/generated/app_localizations.dart';
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
import 'package:debt_display/theme/app_themes.dart';
import 'package:debt_display/ui/app_sections.dart';
import 'package:debt_display/ui/bills_section.dart';
import 'package:debt_display/ui/charts_section.dart';
import 'package:debt_display/ui/app_shell.dart';
import 'package:debt_display/ui/privacy_policy.dart';
import 'package:debt_display/services/debt_backend_service.dart';
import 'package:debt_display/services/file_viewer_io.dart';
import 'package:dio/dio.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _supportedLocales = [Locale('en'), Locale('de')];
final _fixedReferenceDate = DateTime(2026, 4, 25);

void main() {
  tearDown(() {
    debugSetPendingFileWindowFactory(null);
  });

  test('language state loads auto by default and persists overrides', () async {
    SharedPreferences.setMockInitialValues({});
    final state = LanguageState();
    await state.load();

    expect(state.languageMode, AppLanguageMode.auto);
    expect(state.locale, isNull);

    await state.setLanguageMode(AppLanguageMode.german);
    expect(state.locale, const Locale('de'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('language.mode'), 'german');
  });

  test('language state restores saved English override', () async {
    SharedPreferences.setMockInitialValues({'language.mode': 'english'});
    final state = LanguageState();
    await state.load();

    expect(state.languageMode, AppLanguageMode.english);
    expect(state.locale, const Locale('en'));
  });

  testWidgets('home dashboard renders localized English and German labels', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    await tester.pumpWidget(
      _buildHomeSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        locale: const Locale('en', 'US'),
        referenceDate: _fixedReferenceDate,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent outstanding bills'), findsOneWidget);

    await tester.pumpWidget(
      _buildHomeSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        locale: const Locale('de', 'DE'),
        referenceDate: _fixedReferenceDate,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aktuelle offene Rechnungen'), findsOneWidget);
  });

  testWidgets('language setting changes state and persists selection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final languageState = LanguageState();
    final navigationState = NavigationState()
      ..selectDestination(AppDestination.menu);
    _setTestSurfaceSize(tester, width: 430, height: 900);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(),
        navigationState: navigationState,
        languageState: languageState,
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Deutsch'));

    expect(languageState.languageMode, AppLanguageMode.german);
    expect(languageState.locale, const Locale('de'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('language.mode'), 'german');
  });

  testWidgets('home dashboard formats amounts and dates for en_US locale', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    await tester.pumpWidget(
      _buildHomeSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        locale: const Locale('en', 'US'),
        referenceDate: _fixedReferenceDate,
      ),
    );
    await tester.pumpAndSettle();

    final materialLocalizations = _homeMaterialLocalizations(tester);
    final expectedDue = materialLocalizations.formatShortDate(
      _placeholderDueDate(_fixedReferenceDate, 1),
    );
    final expectedAmount = _formatExpectedCurrency(
      411.45,
      const Locale('en', 'US'),
    );
    final expectedFirstRemaining = _formatExpectedCurrency(
      55,
      const Locale('en', 'US'),
    );
    final expectedFirstTotal = _formatExpectedCurrency(
      120,
      const Locale('en', 'US'),
    );

    expect(find.text('Recent outstanding bills'), findsOneWidget);
    expect(find.textContaining('Due '), findsNWidgets(3));
    expect(find.text('Due $expectedDue'), findsOneWidget);
    expect(find.text('Studio rent top-up'), findsOneWidget);
    expect(find.text('Quarterly electricity bill'), findsOneWidget);
    expect(find.text('Spring grocery split'), findsOneWidget);
    expect(find.text('Weekend train tickets'), findsNothing);
    expect(find.text('Internet renewal'), findsNothing);
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Total still owed'), findsOneWidget);
    expect(find.text(expectedAmount), findsOneWidget);
    expect(find.text('Still owed'), findsNWidgets(3));
    expect(find.text('Total'), findsNWidgets(3));
    expect(find.text(expectedFirstRemaining), findsOneWidget);
    expect(find.text(expectedFirstTotal), findsOneWidget);
  });

  testWidgets('home dashboard formats amounts and dates for de_DE locale', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    await tester.pumpWidget(
      _buildHomeSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        locale: const Locale('de', 'DE'),
        referenceDate: _fixedReferenceDate,
      ),
    );
    await tester.pumpAndSettle();

    final materialLocalizations = _homeMaterialLocalizations(tester);
    final expectedDue = materialLocalizations.formatShortDate(
      _placeholderDueDate(_fixedReferenceDate, 1),
    );
    final expectedAmount = _formatExpectedCurrency(
      411.45,
      const Locale('de', 'DE'),
    );

    expect(find.text('Fällig $expectedDue'), findsOneWidget);
    expect(find.text(expectedAmount), findsOneWidget);
  });

  testWidgets('home dashboard bill list button opens bills destination', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);
    final navigationState = NavigationState();

    await tester.pumpWidget(
      _buildHomeSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        navigationState: navigationState,
        referenceDate: _fixedReferenceDate,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-bill-list-button')));
    await tester.pump();

    expect(navigationState.selectedDestination, AppDestination.bills);
  });

  testWidgets('home dashboard create button opens bill creation', (
    tester,
  ) async {
    final navigationState = NavigationState();
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    await tester.pumpWidget(
      _buildHomeSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        navigationState: navigationState,
        referenceDate: _fixedReferenceDate,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-bill-create-button')));
    await tester.pumpAndSettle();

    expect(navigationState.selectedDestination, AppDestination.createBill);
  });

  testWidgets(
    'home dashboard collapses hidden bill tags into an overflow chip',
    (tester) async {
      _setTestSurfaceSize(tester, width: 320, height: 1000);

      await tester.pumpWidget(
        _buildHomeSectionTestApp(
          authState: _TestAuthSessionState(
            isAuthenticatedValue: true,
            accessTokenValue: 'token-1',
            userIdValue: 10,
          ),
          referenceDate: _fixedReferenceDate,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+4'), findsOneWidget);
    },
  );

  testWidgets('home dashboard loads real due dates from home state', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final referenceDate = DateTime(2030, 1, 10);
    await tester.pumpWidget(
      _buildHomeSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        locale: const Locale('en', 'US'),
        referenceDate: referenceDate,
      ),
    );
    await tester.pumpAndSettle();

    final materialLocalizations = _homeMaterialLocalizations(tester);
    const dueOffsets = [1, 2, 3];
    for (final dueOffset in dueOffsets) {
      final expectedDue = materialLocalizations.formatShortDate(
        _placeholderDueDate(referenceDate, dueOffset),
      );
      expect(find.text('Due $expectedDue'), findsOneWidget);
    }
  });

  testWidgets('mobile bottom navigation shows home, view, create, and menu', (
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
      find.descendant(of: navigationBar, matching: find.text('View')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigationBar, matching: find.text('Create')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigationBar, matching: find.text('Menu')),
      findsOneWidget,
    );
  });

  testWidgets('privacy gate blocks app content until accepted', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setTestSurfaceSize(tester, width: 430, height: 900);
    final privacyConsentState = PrivacyConsentState.test(
      hasAcceptedCurrentVersion: false,
    );

    await tester.pumpWidget(
      _buildPrivacyGateTestApp(
        privacyConsentState: privacyConsentState,
        child: const Text('Protected app content'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Protected app content'), findsNothing);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('privacy-accept-button')),
    );

    expect(privacyConsentState.hasAcceptedCurrentVersion, isTrue);
    expect(find.text('Protected app content'), findsOneWidget);
  });

  testWidgets('saved privacy consent skips the gate', (tester) async {
    _setTestSurfaceSize(tester, width: 430, height: 900);

    await tester.pumpWidget(
      _buildPrivacyGateTestApp(
        privacyConsentState: PrivacyConsentState.test(),
        child: const Text('Protected app content'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Protected app content'), findsOneWidget);
    expect(find.text('Accept and continue'), findsNothing);
  });

  testWidgets('menu section includes charts navigation action', (tester) async {
    final navigationState = NavigationState()
      ..selectDestination(AppDestination.menu);
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(),
        navigationState: navigationState,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Review paid, open, and overdue shares by date and tag.'),
      findsOneWidget,
    );

    await _tapVisible(tester, find.text('Charts'));

    expect(navigationState.selectedDestination, AppDestination.charts);
  });

  testWidgets('menu exposes privacy policy and source code actions', (
    tester,
  ) async {
    final navigationState = NavigationState()
      ..selectDestination(AppDestination.menu);
    _setTestSurfaceSize(tester, width: 430, height: 1100);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(),
        navigationState: navigationState,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Source code'), findsOneWidget);
    expect(find.byKey(const ValueKey('source-code-menu-tile')), findsOneWidget);

    final privacyTile = find.byKey(const ValueKey('menu-privacyPolicy-tile'));
    await tester.ensureVisible(privacyTile);
    await tester.pump();
    await tester.tap(privacyTile);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(navigationState.selectedDestination, AppDestination.privacyPolicy);
    expect(
      find.byKey(const ValueKey('privacy-source-code-button')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('privacy-revoke-button')), findsOneWidget);
  });

  testWidgets('privacy policy screen can revoke consent and show gate', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setTestSurfaceSize(tester, width: 430, height: 900);
    final privacyConsentState = PrivacyConsentState.test();

    await tester.pumpWidget(
      _buildPrivacyGateTestApp(
        privacyConsentState: privacyConsentState,
        child: const SingleChildScrollView(child: PrivacyPolicySection()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final revokeButton = find.byKey(const ValueKey('privacy-revoke-button'));
    await tester.ensureVisible(revokeButton);
    await tester.pump();
    await tester.tap(revokeButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(privacyConsentState.hasAcceptedCurrentVersion, isFalse);
    expect(find.byKey(const ValueKey('privacy-accept-button')), findsOneWidget);
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

  testWidgets('menu section includes bill creation action', (tester) async {
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

    expect(find.text('Create Bill'), findsOneWidget);
    await _tapVisible(tester, find.text('Create Bill'));

    expect(navigationState.selectedDestination, AppDestination.createBill);
  });

  testWidgets('menu section opens recipient group management', (tester) async {
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

    await _tapVisible(
      tester,
      find.text(
        'Create shared recipient groups and manage who can receive split bills.',
      ),
    );

    expect(navigationState.selectedDestination, AppDestination.recipientGroups);
  });

  testWidgets('desktop burger menu includes recipient groups destination', (
    tester,
  ) async {
    final navigationState = NavigationState();
    _setTestSurfaceSize(tester, width: 1000, height: 900);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(),
        navigationState: navigationState,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recipient groups'));
    await tester.pumpAndSettle();

    expect(navigationState.selectedDestination, AppDestination.recipientGroups);
  });

  testWidgets('menu recipient groups card shows login action when logged out', (
    tester,
  ) async {
    final authState = _TestAuthSessionState();
    final navigationState = NavigationState()
      ..selectDestination(AppDestination.recipientGroups);
    _setTestSurfaceSize(tester, width: 430, height: 900);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: authState,
        navigationState: navigationState,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recipient groups'), findsWidgets);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('recipient-groups-login-button')),
    );

    expect(authState.loginCalls, 1);
  });

  testWidgets('authenticated menu loads recipient groups', (tester) async {
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      recipients: [
        _testRecipient(
          id: 77,
          name: 'Roommates',
          ownerId: 10,
          members: [_testUser(id: 20, name: 'Alice', email: 'alice@test.dev')],
        ),
        _testRecipient(
          id: 78,
          name: 'Former trip',
          ownerId: 10,
          members: [
            _testUser(
              id: 21,
              name: '[DELETED]',
              email: '[DELETED]',
              deleted: true,
            ),
          ],
        ),
      ],
    );
    final navigationState = NavigationState()
      ..selectDestination(AppDestination.recipientGroups);
    _setTestSurfaceSize(tester, width: 430, height: 900);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token',
          userIdValue: 10,
        ),
        navigationState: navigationState,
        recipientGroupState: RecipientGroupState(
          debtBackendService: fakeService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeService.listRecipientsCalls, 1);
    expect(find.text('Roommates'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Deleted User'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('recipient-group-edit-77')),
      findsOneWidget,
    );
  });

  testWidgets('recipient user search waits for three characters', (
    tester,
  ) async {
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      onSearchUsers: (_) {
        final response = UsersResponse(success: true);
        response.users.add(
          _testUser(id: 20, name: 'Alice', email: 'alice@test.dev'),
        );
        return response;
      },
    );
    final navigationState = NavigationState()
      ..selectDestination(AppDestination.recipientGroups);
    _setTestSurfaceSize(tester, width: 430, height: 900);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token',
          userIdValue: 10,
        ),
        navigationState: navigationState,
        recipientGroupState: RecipientGroupState(
          debtBackendService: fakeService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('recipient-groups-create-button')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('recipient-user-search-field')),
      'Al',
    );
    await tester.pumpAndSettle();

    expect(fakeService.searchRequests, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('recipient-user-search-field')),
      'Ali',
    );
    await tester.pumpAndSettle();

    expect(fakeService.searchRequests.single.query, 'Ali');
    expect(
      find.byKey(const ValueKey('recipient-user-search-result-20')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('recipient-user-add-20')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('recipient-selected-member-20')),
      findsOneWidget,
    );
  });

  test('recipient group state ignores stale user search responses', () async {
    final searchCompleters = <String, Completer<UsersResponse>>{};
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      onSearchUsers: (request) {
        final completer = Completer<UsersResponse>();
        searchCompleters[request.query] = completer;
        return completer.future;
      },
    );
    final state = RecipientGroupState(debtBackendService: fakeService)
      ..updateAuthSession(
        _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token',
          userIdValue: 10,
        ),
      );

    final aliSearch = state.searchUsers('Ali');
    final bobSearch = state.searchUsers('Bob');

    searchCompleters['Bob']!.complete(
      UsersResponse(success: true)
        ..users.add(_testUser(id: 21, name: 'Bob', email: 'bob@test.dev')),
    );
    await bobSearch;

    expect(state.searchResults.map((user) => user.name), ['Bob']);

    searchCompleters['Ali']!.complete(
      UsersResponse(success: true)
        ..users.add(_testUser(id: 20, name: 'Alice', email: 'alice@test.dev')),
    );
    await aliSearch;

    expect(state.searchResults.map((user) => user.name), ['Bob']);
  });

  testWidgets('recipient group editor clears search results when reopened', (
    tester,
  ) async {
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      onSearchUsers: (_) {
        final response = UsersResponse(success: true);
        response.users.add(
          _testUser(id: 20, name: 'Alice', email: 'alice@test.dev'),
        );
        return response;
      },
    );
    final navigationState = NavigationState()
      ..selectDestination(AppDestination.recipientGroups);
    _setTestSurfaceSize(tester, width: 430, height: 900);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token',
          userIdValue: 10,
        ),
        navigationState: navigationState,
        recipientGroupState: RecipientGroupState(
          debtBackendService: fakeService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('recipient-groups-create-button')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('recipient-user-search-field')),
      'Ali',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('recipient-user-search-result-20')),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('recipient-groups-create-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('recipient-user-search-result-20')),
      findsNothing,
    );
  });

  testWidgets('recipient group create sends selected members', (tester) async {
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      onSearchUsers: (_) {
        final response = UsersResponse(success: true);
        response.users.add(
          _testUser(id: 20, name: 'Alice', email: 'alice@test.dev'),
        );
        return response;
      },
    );
    final navigationState = NavigationState()
      ..selectDestination(AppDestination.recipientGroups);
    _setTestSurfaceSize(tester, width: 430, height: 900);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token',
          userIdValue: 10,
        ),
        navigationState: navigationState,
        recipientGroupState: RecipientGroupState(
          debtBackendService: fakeService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('recipient-groups-create-button')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('recipient-group-name-field')),
      'Trip crew',
    );
    await tester.enterText(
      find.byKey(const ValueKey('recipient-group-description-field')),
      'Weekend expenses',
    );
    await tester.enterText(
      find.byKey(const ValueKey('recipient-user-search-field')),
      'Ali',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipient-user-add-20')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipient-group-save-button')));
    await tester.pumpAndSettle();

    expect(fakeService.createRecipientRequests, hasLength(1));
    final request = fakeService.createRecipientRequests.single;
    expect(request.name, 'Trip crew');
    expect(request.description, 'Weekend expenses');
    expect(request.memberIds.map((id) => id.toInt()), [20]);
    expect(find.text('Trip crew'), findsOneWidget);
  });

  testWidgets('recipient group edit removes member and delete confirms', (
    tester,
  ) async {
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      recipients: [
        _testRecipient(
          id: 77,
          name: 'Roommates',
          ownerId: 10,
          members: [
            _testUser(id: 20, name: 'Alice', email: 'alice@test.dev'),
            _testUser(id: 21, name: 'Bob', email: 'bob@test.dev'),
          ],
        ),
      ],
    );
    final navigationState = NavigationState()
      ..selectDestination(AppDestination.recipientGroups);
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token',
          userIdValue: 10,
        ),
        navigationState: navigationState,
        recipientGroupState: RecipientGroupState(
          debtBackendService: fakeService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('recipient-group-edit-77')),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('recipient-selected-member-remove-20')),
    );
    await tester.tap(find.byKey(const ValueKey('recipient-group-save-button')));
    await tester.pumpAndSettle();

    expect(fakeService.updateRecipientRequests, hasLength(1));
    expect(fakeService.removeMemberRequests.single.userId.toInt(), 20);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('recipient-group-delete-77')),
    );
    await tester.tap(
      find.byKey(const ValueKey('recipient-group-confirm-delete-button')),
    );
    await tester.pumpAndSettle();

    expect(fakeService.deleteRecipientRequests.single.recipientId.toInt(), 77);
    expect(find.text('Roommates'), findsNothing);
  });

  test('recipient group state clears data on auth change', () async {
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      recipients: [_testRecipient(id: 77, name: 'Roommates', ownerId: 10)],
    );
    final authState = _TestAuthSessionState(
      isAuthenticatedValue: true,
      accessTokenValue: 'token',
      userIdValue: 10,
    );
    final state = RecipientGroupState(debtBackendService: fakeService)
      ..updateAuthSession(authState);

    await state.ensureLoaded();
    expect(state.groups, hasLength(1));

    authState.updateSession(
      isAuthenticated: false,
      accessToken: null,
      userId: null,
    );
    state.updateAuthSession(authState);

    expect(state.groups, isEmpty);
    expect(state.errorMessage, isNull);
  });

  test('recipient group state keeps list when create fails', () async {
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      recipients: [_testRecipient(id: 77, name: 'Roommates', ownerId: 10)],
      createRecipientSucceeds: false,
      mutationErrorMessage: 'Create failed',
    );
    final state = RecipientGroupState(debtBackendService: fakeService)
      ..updateAuthSession(
        _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token',
          userIdValue: 10,
        ),
      );

    await state.ensureLoaded();
    final saved = await state.saveGroup(
      name: 'Trip crew',
      description: '',
      memberIds: const [],
    );

    expect(saved, isFalse);
    expect(state.groups.single.name, 'Roommates');
    expect(state.errorMessage, 'Create failed');
  });

  testWidgets(
    'bill creation defaults group shares and submits localized amount',
    (tester) async {
      final navigationState = NavigationState()
        ..selectDestination(AppDestination.createBill);
      _setTestSurfaceSize(tester, width: 430, height: 1400);
      final fakeService = _FakeDebtBackendService(
        availableTags: [
          TagIndex(id: Int64(1), icon: '🏠', text: 'Home', color: '#FFB74D'),
        ],
        recipients: [
          _testRecipient(
            id: 77,
            name: 'Roommates',
            ownerId: 10,
            members: [
              _testUser(id: 20, name: 'Alice', email: 'alice@test.dev'),
              _testUser(id: 30, name: 'Bob', email: 'bob@test.dev'),
            ],
          ),
        ],
        onListReceipts: (_) => ReceiptsResponse(success: true),
      );

      await tester.pumpWidget(
        _buildResponsiveShellTestApp(
          authState: _TestAuthSessionState(
            isAuthenticatedValue: true,
            accessTokenValue: 'token-1',
            userIdValue: 10,
          ),
          navigationState: navigationState,
          billCreationState: BillCreationState(debtBackendService: fakeService),
          recipientGroupState: RecipientGroupState(
            debtBackendService: fakeService,
          ),
          billListState: BillListState(debtBackendService: fakeService),
          locale: const Locale('de', 'DE'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('bill-create-title-field')),
        'Electricity',
      );
      await tester.enterText(
        find.byKey(const ValueKey('bill-create-description-field')),
        'April bill',
      );
      await tester.enterText(
        find.byKey(const ValueKey('bill-create-amount-field')),
        '123,45',
      );
      await _selectDropdownItem(
        tester,
        const ValueKey('bill-create-group-field'),
        'Roommates',
      );
      await tester.tap(find.widgetWithText(FilterChip, 'Home'));
      await tester.enterText(
        find.byKey(const ValueKey('bill-create-tag-text-field')),
        'Utilities',
      );
      await tester.tap(
        find.byKey(const ValueKey('bill-create-add-tag-button')),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('bill-create-submit-button')),
      );
      await tester.tap(find.byKey(const ValueKey('bill-create-submit-button')));
      await tester.pumpAndSettle();

      expect(fakeService.createReceiptRequests, hasLength(1));
      final request = fakeService.createReceiptRequests.single;
      expect(request.title, 'Electricity');
      expect(request.description, 'April bill');
      expect(request.amountOwed, 123.45);
      expect(request.currency, 'EUR');
      expect(request.recipientId.toInt(), 77);
      expect(request.split.ownerSharePercent, 0);
      expect(
        request.split.recipientShares.map((share) => share.sharePercent),
        everyElement(closeTo(50, 0.001)),
      );
      expect(fakeService.setReceiptTagRequests, hasLength(1));
      expect(fakeService.tagUpsertRequests.single.text, 'Utilities');
      expect(navigationState.selectedDestination, AppDestination.bills);
    },
  );

  testWidgets('bill creation validates required title and amount', (
    tester,
  ) async {
    final navigationState = NavigationState()
      ..selectDestination(AppDestination.createBill);
    _setTestSurfaceSize(tester, width: 430, height: 1200);
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
    );

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        navigationState: navigationState,
        billCreationState: BillCreationState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('bill-create-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('bill-create-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Title is required.'), findsOneWidget);
    expect(find.text('Enter a valid amount.'), findsOneWidget);
    expect(fakeService.createReceiptRequests, isEmpty);
  });

  test('bill creation rolls back when tag creation fails', () async {
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      onGetOrCreateTag: (_) =>
          TagResponse(success: false, message: 'Tag create failed'),
    );
    final state = BillCreationState(debtBackendService: fakeService);
    state.updateAuthSession(
      _TestAuthSessionState(
        isAuthenticatedValue: true,
        accessTokenValue: 'token-1',
        userIdValue: 10,
      ),
    );

    final saved = await state.saveBill(
      title: 'Power',
      description: '',
      amountOwed: 42,
      currency: 'EUR',
      recipientId: null,
      notes: '',
      ownerSharePercent: null,
      recipientShares: const [],
      tags: const [
        BillDraftTag(text: 'Utilities', icon: '⚡', color: '#FFD54F'),
      ],
      attachments: const [],
    );

    expect(saved, isNull);
    expect(state.errorMessage, 'Tag create failed');
    expect(fakeService.deleteReceiptRequests, hasLength(1));
    expect(fakeService.deleteReceiptRequests.single.receiptId.toInt(), 901);
  });

  test('bill creation rolls back when file upload fails', () async {
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      onUploadReceiptFile: (_) =>
          FileResponse(success: false, message: 'Upload failed'),
    );
    final state = BillCreationState(debtBackendService: fakeService);
    state.updateAuthSession(
      _TestAuthSessionState(
        isAuthenticatedValue: true,
        accessTokenValue: 'token-1',
        userIdValue: 10,
      ),
    );

    final saved = await state.saveBill(
      title: 'Power',
      description: '',
      amountOwed: 42,
      currency: 'EUR',
      recipientId: null,
      notes: '',
      ownerSharePercent: null,
      recipientShares: const [],
      tags: const [],
      attachments: [
        BillDraftAttachment(
          filename: 'receipt.pdf',
          bytes: Uint8List.fromList([1, 2, 3]),
          contentType: 'application/pdf',
        ),
      ],
    );

    expect(saved, isNull);
    expect(state.errorMessage, 'Upload failed');
    expect(fakeService.deleteReceiptRequests, hasLength(1));
    expect(fakeService.deleteReceiptRequests.single.receiptId.toInt(), 901);
  });

  test('bill creation reports when rollback fails', () async {
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      onGetOrCreateTag: (_) =>
          TagResponse(success: false, message: 'Tag create failed'),
      onDeleteReceipt: (_) =>
          ActionResponse(success: false, message: 'Delete failed'),
    );
    final state = BillCreationState(debtBackendService: fakeService);
    state.updateAuthSession(
      _TestAuthSessionState(
        isAuthenticatedValue: true,
        accessTokenValue: 'token-1',
        userIdValue: 10,
      ),
    );

    final saved = await state.saveBill(
      title: 'Power',
      description: '',
      amountOwed: 42,
      currency: 'EUR',
      recipientId: null,
      notes: '',
      ownerSharePercent: null,
      recipientShares: const [],
      tags: const [
        BillDraftTag(text: 'Utilities', icon: '⚡', color: '#FFD54F'),
      ],
      attachments: const [],
    );

    expect(saved, isNull);
    expect(
      state.errorMessage,
      'Tag create failed Cleanup failed, so the bill may already exist: Delete failed',
    );
  });

  testWidgets('bill creation stays on form when rollback path fails later', (
    tester,
  ) async {
    final navigationState = NavigationState()
      ..selectDestination(AppDestination.createBill);
    _setTestSurfaceSize(tester, width: 430, height: 1200);
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      onGetOrCreateTag: (_) =>
          TagResponse(success: false, message: 'Tag create failed'),
    );

    await tester.pumpWidget(
      _buildResponsiveShellTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        navigationState: navigationState,
        billCreationState: BillCreationState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('bill-create-title-field')),
      'Electricity',
    );
    await tester.enterText(
      find.byKey(const ValueKey('bill-create-amount-field')),
      '123.45',
    );
    await tester.enterText(
      find.byKey(const ValueKey('bill-create-tag-text-field')),
      'Utilities',
    );
    await tester.tap(find.byKey(const ValueKey('bill-create-add-tag-button')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('bill-create-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('bill-create-submit-button')));
    await tester.pumpAndSettle();

    expect(navigationState.selectedDestination, AppDestination.createBill);
    expect(find.text('Tag create failed'), findsOneWidget);
    expect(fakeService.deleteReceiptRequests, hasLength(1));
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

  testWidgets('bills view loads with an access token before user id resolves', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final fakeService = _FakeDebtBackendService(
      availableTags: const [],
      onListReceipts: (_) {
        final response = ReceiptsResponse(success: true);
        response.receipts.add(
          _testReceipt(id: 41, title: 'Token only receipt', amountOwed: 31),
        );
        return response;
      },
    );

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: null,
        ),
        billListState: BillListState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Token only receipt'), findsOneWidget);
    expect(fakeService.requests, hasLength(1));
  });

  testWidgets(
    'bills view shows description, tags, shares, and my split amount',
    (tester) async {
      _setTestSurfaceSize(tester, width: 430, height: 1000);

      final fakeService = _FakeDebtBackendService(
        availableTags: const [],
        onListReceipts: (_) {
          final response = ReceiptsResponse(success: true);
          response.receipts.add(
            _testReceipt(
              id: 42,
              title: 'Shared split receipt',
              description: 'One-line subtitle that fades when space is tight',
              amountOwed: 100,
              amountPaid: 55,
              tags: [
                TagIndex(
                  id: Int64(1),
                  icon: '🏠',
                  text: 'Home',
                  color: '#FFB74D',
                ),
              ],
              split: ReceiptSplit(
                ownerSharePercent: 40,
                ownerAmount: 40,
                ownerAmountPaid: 25,
                recipientShares: [
                  ReceiptRecipientShare(
                    userId: Int64(20),
                    sharePercent: 60,
                    amount: 60,
                    amountPaid: 30,
                    user: _testUser(
                      id: 20,
                      name: '[DELETED]',
                      email: '[DELETED]',
                      deleted: true,
                    ),
                  ),
                ],
              ),
            ),
          );
          return response;
        },
      );

      await tester.pumpWidget(
        _buildBillsSectionTestApp(
          authState: _TestAuthSessionState(
            isAuthenticatedValue: true,
            accessTokenValue: 'token-1',
            userIdValue: 10,
          ),
          billListState: BillListState(debtBackendService: fakeService),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('One-line subtitle that fades when space is tight'),
        findsOneWidget,
      );
      expect(find.text('🏠'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Shared group'), findsOneWidget);
      expect(find.textContaining('Alice'), findsNothing);
      expect(find.text('Unpaid'), findsOneWidget);
      expect(
        find.text(_formatExpectedCurrency(55, const Locale('en', 'US'))),
        findsNothing,
      );
      expect(find.textContaining('60%'), findsNothing);
      expect(find.textContaining('paid '), findsNothing);
      expect(find.byKey(const ValueKey('receipt-payments-42')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('receipt-row-42')));
      await tester.pumpAndSettle();

      expect(find.text('Paid'), findsWidgets);
      expect(
        find.text(_formatExpectedCurrency(25, const Locale('en', 'US'))),
        findsWidgets,
      );
      expect(find.textContaining('Deleted User'), findsOneWidget);
      expect(find.textContaining('60%'), findsOneWidget);
      expect(
        find.text(_formatExpectedCurrency(30, const Locale('en', 'US'))),
        findsWidgets,
      );
      expect(
        find.text(_formatExpectedCurrency(40, const Locale('en', 'US'))),
        findsWidgets,
      );
    },
  );

  testWidgets('bills view keeps trailing amount sized on narrow screens', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 320, height: 1000);

    const longTitle =
        'Very long shared household receipt title that should stay bounded';
    const longDescription =
        'A long one-line description that should not push the amount away';
    final expectedAmount = _formatExpectedCurrency(
      123.45,
      const Locale('en', 'US'),
    );
    final fakeService = _FakeDebtBackendService(
      availableTags: const [],
      onListReceipts: (_) {
        final response = ReceiptsResponse(success: true);
        response.receipts.add(
          _testReceipt(
            id: 44,
            title: longTitle,
            description: longDescription,
            amountOwed: 123.45,
            amountPaid: 12.30,
            split: ReceiptSplit(ownerSharePercent: 100, ownerAmount: 123.44),
          ),
        );
        return response;
      },
    );

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        billListState: BillListState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(longTitle), findsOneWidget);
    expect(find.text(expectedAmount), findsOneWidget);
  });

  testWidgets('bills view shows still owed and total trailing amounts', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final expectedRemaining = _formatExpectedCurrency(
      55,
      const Locale('en', 'US'),
    );
    final expectedTotal = _formatExpectedCurrency(
      120,
      const Locale('en', 'US'),
    );
    final fakeService = _FakeDebtBackendService(
      availableTags: const [],
      onListReceipts: (_) {
        final response = ReceiptsResponse(success: true);
        response.receipts.add(
          _testReceipt(
            id: 45,
            title: 'Remaining split receipt',
            amountOwed: 120,
            amountPaid: 25,
            split: ReceiptSplit(
              ownerSharePercent: 75,
              ownerAmount: 80,
              ownerAmountPaid: 25,
            ),
          ),
        );
        return response;
      },
    );

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        billListState: BillListState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Still owed'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text(expectedRemaining), findsOneWidget);
    expect(find.text(expectedTotal), findsOneWidget);
  });

  testWidgets('owner payment edit flow updates paid amount in bills view', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    var receipt = _testReceipt(
      id: 43,
      title: 'Editable split receipt',
      amountOwed: 100,
      amountPaid: 10,
      split: ReceiptSplit(
        ownerSharePercent: 40,
        ownerAmount: 40,
        ownerAmountPaid: 10,
        recipientShares: [
          ReceiptRecipientShare(
            userId: Int64(20),
            sharePercent: 60,
            amount: 60,
            amountPaid: 0,
            user: _testUser(id: 20, name: 'Alice', email: 'alice@test.dev'),
          ),
        ],
      ),
    );
    final fakeService = _FakeDebtBackendService(
      availableTags: const [],
      onListReceipts: (_) {
        final response = ReceiptsResponse(success: true);
        response.receipts.add(receipt.deepCopy());
        return response;
      },
      onSetReceiptPayments: (request) {
        final ownerPayment = request.payments.firstWhere(
          (payment) => !payment.hasUserId(),
        );
        final alicePayment = request.payments.firstWhere(
          (payment) => payment.userId.toInt() == 20,
        );
        receipt = receipt.deepCopy()
          ..amountPaid = ownerPayment.amountPaid + alicePayment.amountPaid
          ..split.ownerAmountPaid = ownerPayment.amountPaid
          ..split.recipientShares[0].amountPaid = alicePayment.amountPaid;
        return ReceiptResponse(success: true, receipt: receipt.deepCopy());
      },
    );

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        billListState: BillListState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('receipt-row-43')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('receipt-payments-43')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('receipt-payment-owner-field')),
      '25',
    );
    await tester.enterText(
      find.byKey(const ValueKey('receipt-payment-user-20-field')),
      '30',
    );
    await tester.tap(find.byKey(const ValueKey('receipt-payment-save-button')));
    await tester.pumpAndSettle();

    expect(fakeService.setPaymentRequests, hasLength(1));
    expect(fakeService.setPaymentRequests.single.receiptId.toInt(), 43);
    expect(
      find.text(_formatExpectedCurrency(25, const Locale('en', 'US'))),
      findsWidgets,
    );
    expect(
      find.text(_formatExpectedCurrency(30, const Locale('en', 'US'))),
      findsWidgets,
    );
  });

  testWidgets('bill detail dialog shows current participant paid amount', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final fakeService = _FakeDebtBackendService(
      availableTags: const [],
      onListReceipts: (_) {
        final response = ReceiptsResponse(success: true);
        response.receipts.add(
          _testReceipt(
            id: 46,
            title: 'Participant split receipt',
            amountOwed: 100,
            amountPaid: 55,
            split: ReceiptSplit(
              ownerSharePercent: 40,
              ownerAmount: 40,
              ownerAmountPaid: 25,
              recipientShares: [
                ReceiptRecipientShare(
                  userId: Int64(20),
                  sharePercent: 60,
                  amount: 60,
                  amountPaid: 30,
                  user: _testUser(
                    id: 20,
                    name: 'Alice',
                    email: 'alice@test.dev',
                  ),
                ),
              ],
            ),
          ),
        );
        return response;
      },
    );

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 20,
        ),
        billListState: BillListState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('receipt-row-46')));
    await tester.pumpAndSettle();

    expect(
      find.text(_formatExpectedCurrency(30, const Locale('en', 'US'))),
      findsWidgets,
    );
    expect(
      find.text(_formatExpectedCurrency(55, const Locale('en', 'US'))),
      findsNothing,
    );
  });

  testWidgets('non-web receipt file open uses pending window bytes flow', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final file = ReceiptFile(
      id: Int64(81),
      receiptId: Int64(47),
      originalFilename: 'statement.pdf',
      contentType: 'application/pdf',
    );
    final fakeService = _FakeDebtBackendService(
      availableTags: const [],
      onListReceipts: (_) {
        final response = ReceiptsResponse(success: true);
        response.receipts.add(
          _testReceipt(
            id: 47,
            title: 'Receipt with file',
            amountOwed: 10,
            files: [file],
          ),
        );
        return response;
      },
      onDownloadReceiptFile: (_) => ReceiptFileDownload(
        file: file.deepCopy(),
        bytes: Uint8List.fromList([7, 8, 9]),
        contentType: 'application/pdf',
      ),
    );

    Uint8List? openedBytes;
    String? openedContentType;
    String? openedFilename;
    debugSetPendingFileWindowFactory(
      () => PendingFileWindow(({
        required bytes,
        required contentType,
        required filename,
      }) async {
        openedBytes = bytes;
        openedContentType = contentType;
        openedFilename = filename;
      }),
    );

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        billListState: BillListState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('receipt-row-47')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('receipt-file-open-81')));
    await tester.pumpAndSettle();

    expect(openedBytes, Uint8List.fromList([7, 8, 9]));
    expect(openedContentType, 'application/pdf');
    expect(openedFilename, 'statement.pdf');
  });

  testWidgets('receipt file preview keeps one download future across rebuilds', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final file = ReceiptFile(
      id: Int64(83),
      receiptId: Int64(49),
      originalFilename: 'receipt.png',
      contentType: 'image/png',
    );
    final imageBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
    );
    var downloadCount = 0;
    final fakeService = _FakeDebtBackendService(
      availableTags: const [],
      onListReceipts: (_) {
        final response = ReceiptsResponse(success: true);
        response.receipts.add(
          _testReceipt(
            id: 49,
            title: 'Receipt with preview',
            amountOwed: 10,
            files: [file],
          ),
        );
        return response;
      },
      onDownloadReceiptFile: (_) {
        downloadCount += 1;
        return ReceiptFileDownload(
          file: file.deepCopy(),
          bytes: imageBytes,
          contentType: 'image/png',
        );
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

    await tester.tap(find.byKey(const ValueKey('receipt-row-49')));
    await tester.pumpAndSettle();
    expect(downloadCount, 1);

    await billListState.refresh();
    await tester.pumpAndSettle();

    expect(downloadCount, 1);
  });

  testWidgets('non-web receipt file open shows snackbar on open failure', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final file = ReceiptFile(
      id: Int64(82),
      receiptId: Int64(48),
      originalFilename: 'statement.pdf',
      contentType: 'application/pdf',
    );
    final fakeService = _FakeDebtBackendService(
      availableTags: const [],
      onListReceipts: (_) {
        final response = ReceiptsResponse(success: true);
        response.receipts.add(
          _testReceipt(
            id: 48,
            title: 'Receipt with file',
            amountOwed: 10,
            files: [file],
          ),
        );
        return response;
      },
      onDownloadReceiptFile: (_) => ReceiptFileDownload(
        file: file.deepCopy(),
        bytes: Uint8List.fromList([7, 8, 9]),
        contentType: 'application/pdf',
      ),
    );
    debugSetPendingFileWindowFactory(
      () => PendingFileWindow(({
        required bytes,
        required contentType,
        required filename,
      }) async {
        throw StateError('Open failed');
      }),
    );

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        billListState: BillListState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('receipt-row-48')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('receipt-file-open-82')));
    await tester.pump();

    expect(find.text('Could not open file.'), findsOneWidget);
  });

  testWidgets('bills filters are collapsed by default and toggle open/closed', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        billListState: BillListState(
          debtBackendService: _FakeDebtBackendService(
            availableTags: const [],
            onListReceipts: (_) => ReceiptsResponse(success: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('bills-filters-toggle-button')),
      findsOneWidget,
    );
    expect(find.text('Role'), findsNothing);
    expect(
      find.byKey(const ValueKey('bills-apply-filters-button')),
      findsNothing,
    );

    await _toggleBillsFilters(tester);
    expect(find.text('Role'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bills-apply-filters-button')),
      findsOneWidget,
    );

    await _toggleBillsFilters(tester);
    expect(find.text('Role'), findsNothing);
    expect(
      find.byKey(const ValueKey('bills-apply-filters-button')),
      findsNothing,
    );
  });

  testWidgets(
    'bills draft changes wait for apply and reset pagination to page 1',
    (tester) async {
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
      expect(
        find.byKey(const ValueKey('bills-page-indicator')),
        findsOneWidget,
      );
      expect(find.text('Page 1'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bills-page-next-button')));
      await tester.pumpAndSettle();

      expect(find.text('Page 2 receipt'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);
      expect(fakeService.requests, hasLength(2));

      await _toggleBillsFilters(tester);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('bills-payment-filter-control')),
          matching: find.text('Paid'),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeService.requests, hasLength(2));
      expect(find.text('Page 2'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('bills-apply-filters-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paid only'), findsOneWidget);
      expect(find.text('Page 1'), findsOneWidget);
      expect(fakeService.requests.last.hasPageToken(), isFalse);
      expect(fakeService.requests.last.hasIsPaid(), isTrue);
      expect(fakeService.requests.last.isPaid, isTrue);
    },
  );

  testWidgets('bills refresh keeps the current page token', (tester) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final fakeService = _FakeDebtBackendService(
      availableTags: const [],
      onListReceipts: (request) {
        final response = ReceiptsResponse(success: true);
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

    await tester.tap(find.byKey(const ValueKey('bills-page-next-button')));
    await tester.pumpAndSettle();
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 2 receipt'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('bills-refresh-button')),
    );
    await tester.tap(find.byKey(const ValueKey('bills-refresh-button')));
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 2 receipt'), findsOneWidget);
    expect(fakeService.requests.last.pageToken, 'page-2');
  });

  testWidgets('bills auth refresh keeps active filters when user id arrives', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final fakeService = _FakeDebtBackendService(
      availableTags: [
        TagIndex(id: Int64(5), icon: 'u', text: 'Utilities', color: '#123456'),
      ],
      onListReceipts: (request) {
        final response = ReceiptsResponse(success: true);
        response.receipts.add(
          _testReceipt(id: 51, title: 'Filtered receipt', amountOwed: 19),
        );
        return response;
      },
    );
    final authState = _TestAuthSessionState(
      isAuthenticatedValue: true,
      accessTokenValue: 'token-1',
      userIdValue: null,
    );

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: authState,
        billListState: BillListState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    await _toggleBillsFilters(tester);
    await _selectDropdownItem(
      tester,
      const ValueKey('bills-sort-dropdown'),
      'Total',
    );
    await tester.tap(find.text('Utilities'));
    await tester.pumpAndSettle();
    expect(fakeService.requests, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('bills-apply-filters-button')));
    await tester.pumpAndSettle();

    authState.updateSession(
      isAuthenticated: true,
      accessToken: 'token-1',
      userId: 10,
    );
    await tester.pumpAndSettle();

    expect(fakeService.requests.length, greaterThanOrEqualTo(3));
    expect(
      fakeService.requests.last.orderBy,
      ReceiptOrderBy.RECEIPT_ORDER_BY_COST_TOTAL,
    );
    expect(fakeService.requests.last.tagIds.map((tag) => tag.toInt()), [5]);
  });

  testWidgets('bills resets filters when a different user logs in', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final fakeService = _FakeDebtBackendService(
      availableTags: [
        TagIndex(id: Int64(5), icon: 'u', text: 'Utilities', color: '#123456'),
      ],
      onListReceipts: (request) {
        final response = ReceiptsResponse(success: true);
        response.receipts.add(
          _testReceipt(id: 61, title: 'Account receipt', amountOwed: 22),
        );
        if (!request.hasPageToken()) {
          response.nextPageToken = 'page-2';
        }
        return response;
      },
    );
    final authState = _TestAuthSessionState(
      isAuthenticatedValue: true,
      accessTokenValue: 'token-a',
      userIdValue: 10,
    );

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: authState,
        billListState: BillListState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    await _toggleBillsFilters(tester);
    await _selectDropdownItem(
      tester,
      const ValueKey('bills-sort-dropdown'),
      'Total',
    );
    await _selectDropdownItem(
      tester,
      const ValueKey('bills-page-size-dropdown'),
      '50',
    );
    await tester.tap(find.text('Utilities'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bills-apply-filters-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('bills-page-next-button')),
    );
    await tester.tap(find.byKey(const ValueKey('bills-page-next-button')));
    await tester.pumpAndSettle();

    authState.updateSession(
      isAuthenticated: false,
      accessToken: null,
      userId: null,
    );
    await tester.pump();

    authState.updateSession(
      isAuthenticated: true,
      accessToken: 'token-b',
      userId: 20,
    );
    await tester.pumpAndSettle();

    expect(
      fakeService.requests.last.orderBy,
      ReceiptOrderBy.RECEIPT_ORDER_BY_ID,
    );
    expect(fakeService.requests.last.limit, 20);
    expect(fakeService.requests.last.tagIds, isEmpty);
    expect(fakeService.requests.last.hasPageToken(), isFalse);
  });

  testWidgets('bills collapse discards unapplied draft edits', (tester) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final fakeService = _FakeDebtBackendService(
      availableTags: const [],
      onListReceipts: (_) {
        final response = ReceiptsResponse(success: true);
        response.receipts.add(
          _testReceipt(
            id: 72,
            title: 'Applied default receipt',
            amountOwed: 27,
          ),
        );
        return response;
      },
    );

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        billListState: BillListState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    await _toggleBillsFilters(tester);
    await _selectDropdownItem(
      tester,
      const ValueKey('bills-sort-dropdown'),
      'Total',
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('bills-sort-dropdown')),
        matching: find.text('Total'),
      ),
      findsOneWidget,
    );
    expect(fakeService.requests, hasLength(1));

    await _toggleBillsFilters(tester);
    await _toggleBillsFilters(tester);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('bills-sort-dropdown')),
        matching: find.text('ID'),
      ),
      findsOneWidget,
    );
    expect(fakeService.requests, hasLength(1));
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

    await _toggleBillsFilters(tester);
    await _selectDropdownItem(
      tester,
      const ValueKey('bills-sort-dropdown'),
      'Total',
    );
    await tester.tap(find.byKey(const ValueKey('bills-apply-filters-button')));
    await tester.pumpAndSettle();
    expect(find.text('Total page 1'), findsOneWidget);
    await _toggleBillsFilters(tester);
    await tester.tap(find.byKey(const ValueKey('bills-page-next-button')));
    await tester.pumpAndSettle();
    expect(find.text('Total page 2'), findsOneWidget);

    await _toggleBillsFilters(tester);
    await _selectDropdownItem(
      tester,
      const ValueKey('bills-sort-dropdown'),
      'Due date',
    );
    await tester.tap(find.byKey(const ValueKey('bills-apply-filters-button')));
    await tester.pumpAndSettle();
    expect(find.text('Due page 1'), findsOneWidget);
    await _toggleBillsFilters(tester);
    await tester.tap(find.byKey(const ValueKey('bills-page-next-button')));
    await tester.pumpAndSettle();
    expect(find.text('Due page 2'), findsOneWidget);
  });

  testWidgets('bills sort dropdown sends still owed order', (tester) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final fakeService = _FakeDebtBackendService(
      availableTags: const [],
      onListReceipts: (request) {
        final response = ReceiptsResponse(success: true);
        response.receipts.add(
          _testReceipt(id: 81, title: 'Sort candidate', amountOwed: 27),
        );
        return response;
      },
    );

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        billListState: BillListState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    await _toggleBillsFilters(tester);
    await _selectDropdownItem(
      tester,
      const ValueKey('bills-sort-dropdown'),
      'Still owed',
    );
    await tester.tap(find.byKey(const ValueKey('bills-apply-filters-button')));
    await tester.pumpAndSettle();

    expect(
      fakeService.requests.last.orderBy,
      ReceiptOrderBy.RECEIPT_ORDER_BY_REMAINING_FOR_USER,
    );
  });

  testWidgets(
    'bills draft reset restores controls without triggering a request',
    (tester) async {
      _setTestSurfaceSize(tester, width: 430, height: 1000);

      final fakeService = _FakeDebtBackendService(
        availableTags: const [],
        onListReceipts: (request) {
          final response = ReceiptsResponse(success: true);
          response.receipts.add(
            _testReceipt(id: 71, title: 'Reset candidate', amountOwed: 27),
          );
          return response;
        },
      );

      await tester.pumpWidget(
        _buildBillsSectionTestApp(
          authState: _TestAuthSessionState(
            isAuthenticatedValue: true,
            accessTokenValue: 'token-1',
            userIdValue: 10,
          ),
          billListState: BillListState(debtBackendService: fakeService),
        ),
      );
      await tester.pumpAndSettle();

      await _toggleBillsFilters(tester);
      await _selectDropdownItem(
        tester,
        const ValueKey('bills-sort-dropdown'),
        'Total',
      );
      await _selectDropdownItem(
        tester,
        const ValueKey('bills-page-size-dropdown'),
        '50',
      );
      expect(fakeService.requests, hasLength(1));

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('bills-sort-dropdown')),
          matching: find.text('Total'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('bills-page-size-dropdown')),
          matching: find.text('50'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('bills-draft-reset-button')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('bills-sort-dropdown')),
          matching: find.text('ID'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('bills-page-size-dropdown')),
          matching: find.text('20'),
        ),
        findsOneWidget,
      );
      expect(fakeService.requests, hasLength(1));
    },
  );

  testWidgets('bills view tolerates malformed backend tag colors', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);

    final fakeService = _FakeDebtBackendService(
      availableTags: const [],
      onListReceipts: (_) {
        final response = ReceiptsResponse(success: true);
        response.receipts.add(
          _testReceipt(
            id: 81,
            title: 'Malformed tag color receipt',
            amountOwed: 14,
            tags: [
              TagIndex(
                id: Int64(8),
                icon: '!',
                text: 'Broken color',
                color: 'blue',
              ),
            ],
          ),
        );
        return response;
      },
    );

    await tester.pumpWidget(
      _buildBillsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
          userIdValue: 10,
        ),
        billListState: BillListState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Malformed tag color receipt'), findsOneWidget);
    expect(find.text('Broken color'), findsOneWidget);
  });

  testWidgets('charts view loads default tag selection and renders charts', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1200);
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      chartSummary: _chartSummary(),
    );
    final chartState = ChartState(debtBackendService: fakeService);

    await tester.pumpWidget(
      _buildChartsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
        ),
        chartState: chartState,
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeService.chartRequests, hasLength(1));
    expect(chartState.selectedTagIds, {1, 2});
    expect(find.byKey(const ValueKey('charts-pie-chart')), findsOneWidget);
    expect(find.byKey(const ValueKey('charts-bar-chart')), findsOneWidget);
  });

  testWidgets('charts date preset changes summary request', (tester) async {
    _setTestSurfaceSize(tester, width: 430, height: 1200);
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      chartSummary: _chartSummary(),
    );

    await tester.pumpWidget(
      _buildChartsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
        ),
        chartState: ChartState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Last 30 days'));
    await tester.pumpAndSettle();

    expect(fakeService.chartRequests, hasLength(2));
    expect(fakeService.chartRequests.last.hasCreatedAtFrom(), isTrue);
    expect(fakeService.chartRequests.last.hasCreatedAtTo(), isTrue);
  });

  testWidgets('charts custom date controls fit on narrow mobile screens', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 320, height: 1000);
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      chartSummary: _chartSummary(),
    );

    await tester.pumpWidget(
      _buildChartsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
        ),
        chartState: ChartState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('charts-from-date-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('charts-to-date-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('charts cancelled custom date pick keeps existing range', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1200);
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      chartSummary: _chartSummary(),
    );
    final chartState = ChartState(debtBackendService: fakeService);
    final existingFrom = DateTime(2026, 5, 1);

    await tester.pumpWidget(
      _buildChartsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
        ),
        chartState: chartState,
      ),
    );
    await tester.pumpAndSettle();
    await chartState.setCustomDateRange(from: existingFrom);
    await tester.pumpAndSettle();
    final requestCount = fakeService.chartRequests.length;

    await tester.tap(find.byKey(const ValueKey('charts-from-date-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(chartState.customFrom, existingFrom);
    expect(fakeService.chartRequests, hasLength(requestCount));
  });

  testWidgets('charts keep the final selected tag active', (tester) async {
    _setTestSurfaceSize(tester, width: 430, height: 1200);
    final rentTag = _chartTag(1, 'Rent');
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      chartSummary: ReceiptChartSummaryResponse(
        success: true,
        totals: ReceiptChartStatusTotals(paidShare: 30, openShare: 15),
        availableTags: [rentTag],
        defaultTagIds: [rentTag.id],
        tagBuckets: [
          ReceiptChartTagBucket(
            tag: rentTag,
            paidShare: 30,
            openShare: 15,
            receiptCount: 2,
          ),
        ],
      ),
    );
    final chartState = ChartState(debtBackendService: fakeService);

    await tester.pumpWidget(
      _buildChartsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
        ),
        chartState: chartState,
      ),
    );
    await tester.pumpAndSettle();
    final requestCount = fakeService.chartRequests.length;

    await tester.tap(find.byKey(const ValueKey('charts-tag-chip-1')));
    await tester.pumpAndSettle();

    expect(chartState.selectedTagIds, {1});
    expect(fakeService.chartRequests, hasLength(requestCount));
  });

  testWidgets('charts view shows empty state without chart data', (
    tester,
  ) async {
    _setTestSurfaceSize(tester, width: 430, height: 1000);
    final fakeService = _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
      chartSummary: ReceiptChartSummaryResponse(success: true),
    );

    await tester.pumpWidget(
      _buildChartsSectionTestApp(
        authState: _TestAuthSessionState(
          isAuthenticatedValue: true,
          accessTokenValue: 'token-1',
        ),
        chartState: ChartState(debtBackendService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No chart data for this range.'), findsNWidgets(2));
  });

  testWidgets(
    'charts tag summary uses theme error color for overdue severity',
    (tester) async {
      _setTestSurfaceSize(tester, width: 430, height: 1200);
      final fakeService = _FakeDebtBackendService(
        onListReceipts: (_) => ReceiptsResponse(success: true),
        chartSummary: _chartSummary(
          buckets: [
            ReceiptChartTagBucket(
              tag: _chartTag(1, 'Rent'),
              paidShare: 10,
              openShare: 0,
              overdueOpenShare: 25,
              receiptCount: 1,
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        _buildChartsSectionTestApp(
          authState: _TestAuthSessionState(
            isAuthenticatedValue: true,
            accessTokenValue: 'token-1',
          ),
          chartState: ChartState(debtBackendService: fakeService),
        ),
      );
      await tester.pumpAndSettle();

      final severityAvatar = tester.widget<CircleAvatar>(
        find.byWidgetPredicate(
          (widget) =>
              widget is CircleAvatar &&
              widget.foregroundColor == buildLightTheme().colorScheme.error,
        ),
      );

      expect(
        severityAvatar.foregroundColor,
        buildLightTheme().colorScheme.error,
      );
    },
  );

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

    expect(navigationBar.selectedIndex, 3);
  });

  testWidgets(
    'mobile recipient groups state maps to the menu bottom-nav selection',
    (tester) async {
      final navigationState = NavigationState()
        ..selectDestination(AppDestination.recipientGroups);
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

      expect(navigationBar.selectedIndex, 3);
    },
  );

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

Future<void> _toggleBillsFilters(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('bills-filters-toggle-button')));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Widget _buildResponsiveShellTestApp({
  required _TestAuthSessionState authState,
  required NavigationState navigationState,
  BillListState? billListState,
  BillCreationState? billCreationState,
  ChartState? chartState,
  HomeBillState? homeBillState,
  LanguageState? languageState,
  RecipientGroupState? recipientGroupState,
  Locale locale = const Locale('en', 'US'),
}) {
  final resolvedBillListState =
      billListState ??
      BillListState(
        debtBackendService: _FakeDebtBackendService(
          onListReceipts: (_) => ReceiptsResponse(success: true),
        ),
      );
  final resolvedRecipientGroupState =
      recipientGroupState ??
      RecipientGroupState(
        debtBackendService: _FakeDebtBackendService(
          onListReceipts: (_) => ReceiptsResponse(success: true),
        ),
      );
  final resolvedBillCreationState =
      billCreationState ??
      BillCreationState(
        debtBackendService: _FakeDebtBackendService(
          onListReceipts: (_) => ReceiptsResponse(success: true),
        ),
      );
  final resolvedHomeBillState =
      homeBillState ??
      HomeBillState(
        debtBackendService: _FakeDebtBackendService(
          onListReceipts: (_) => ReceiptsResponse(success: true),
        ),
      );
  final resolvedChartState =
      chartState ??
      ChartState(
        debtBackendService: _FakeDebtBackendService(
          onListReceipts: (_) => ReceiptsResponse(success: true),
          chartSummary: ReceiptChartSummaryResponse(success: true),
        ),
      );

  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: _supportedLocales,
    theme: buildLightTheme(),
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSessionState>.value(value: authState),
        ChangeNotifierProvider<NavigationState>.value(value: navigationState),
        ChangeNotifierProvider<ThemeState>(create: (_) => ThemeState()),
        ChangeNotifierProvider<LanguageState>.value(
          value: languageState ?? LanguageState(),
        ),
        ChangeNotifierProxyProvider<AuthSessionState, BillListState>(
          create: (_) => resolvedBillListState,
          update: (_, authSessionState, billListState) =>
              (billListState ?? resolvedBillListState)
                ..updateAuthSession(authSessionState),
        ),
        ChangeNotifierProxyProvider<AuthSessionState, BillCreationState>(
          create: (_) => resolvedBillCreationState,
          update: (_, authSessionState, billCreationState) =>
              (billCreationState ?? resolvedBillCreationState)
                ..updateAuthSession(authSessionState),
        ),
        ChangeNotifierProxyProvider<AuthSessionState, HomeBillState>(
          create: (_) => resolvedHomeBillState,
          update: (_, authSessionState, homeBillState) =>
              (homeBillState ?? resolvedHomeBillState)
                ..updateAuthSession(authSessionState),
        ),
        ChangeNotifierProxyProvider<AuthSessionState, ChartState>(
          create: (_) => resolvedChartState,
          update: (_, authSessionState, chartState) =>
              (chartState ?? resolvedChartState)
                ..updateAuthSession(authSessionState),
        ),
        ChangeNotifierProxyProvider<AuthSessionState, RecipientGroupState>(
          create: (_) => resolvedRecipientGroupState,
          update: (_, authSessionState, recipientGroupState) =>
              (recipientGroupState ?? resolvedRecipientGroupState)
                ..updateAuthSession(authSessionState),
        ),
      ],
      child: const ResponsiveShell(),
    ),
  );
}

Widget _buildPrivacyGateTestApp({
  required PrivacyConsentState privacyConsentState,
  required Widget child,
}) {
  return MaterialApp(
    locale: const Locale('en', 'US'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: _supportedLocales,
    theme: buildLightTheme(),
    home: ChangeNotifierProvider<PrivacyConsentState>.value(
      value: privacyConsentState,
      child: PrivacyConsentGate(child: child),
    ),
  );
}

Widget _buildHomeSectionTestApp({
  required _TestAuthSessionState authState,
  NavigationState? navigationState,
  Locale locale = const Locale('en', 'US'),
  DateTime? referenceDate,
}) {
  final homeBillState = HomeBillState(
    debtBackendService: _FakeDebtBackendService(
      unpaidSummaryTotal: 411.45,
      unpaidSummaryCount: 4,
      onListReceipts: (_) => ReceiptsResponse(
        success: true,
        receipts: _homeTestReceipts(referenceDate ?? _fixedReferenceDate),
      ),
    ),
  );
  final billListState = BillListState(
    debtBackendService: _FakeDebtBackendService(
      onListReceipts: (_) => ReceiptsResponse(success: true),
    ),
  );
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: _supportedLocales,
    theme: buildLightTheme(),
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSessionState>.value(value: authState),
        ChangeNotifierProvider<NavigationState>.value(
          value: navigationState ?? NavigationState(),
        ),
        ChangeNotifierProxyProvider<AuthSessionState, HomeBillState>(
          create: (_) => homeBillState,
          update: (_, authSessionState, state) =>
              (state ?? homeBillState)..updateAuthSession(authSessionState),
        ),
        ChangeNotifierProxyProvider<AuthSessionState, BillListState>(
          create: (_) => billListState,
          update: (_, authSessionState, state) =>
              (state ?? billListState)..updateAuthSession(authSessionState),
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
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: _supportedLocales,
    theme: buildLightTheme(),
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSessionState>.value(value: authState),
        ChangeNotifierProxyProvider<AuthSessionState, BillListState>(
          create: (_) => billListState,
          update: (_, authSessionState, state) =>
              (state ?? billListState)..updateAuthSession(authSessionState),
        ),
      ],
      child: const Scaffold(
        body: SingleChildScrollView(child: BillsSection(isDesktop: false)),
      ),
    ),
  );
}

Widget _buildChartsSectionTestApp({
  required _TestAuthSessionState authState,
  required ChartState chartState,
  Locale locale = const Locale('en', 'US'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: _supportedLocales,
    theme: buildLightTheme(),
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSessionState>.value(value: authState),
        ChangeNotifierProxyProvider<AuthSessionState, ChartState>(
          create: (_) => chartState,
          update: (_, authSessionState, state) =>
              (state ?? chartState)..updateAuthSession(authSessionState),
        ),
      ],
      child: const Scaffold(
        body: SingleChildScrollView(child: ChartsSection(isDesktop: false)),
      ),
    ),
  );
}

MaterialLocalizations _homeMaterialLocalizations(WidgetTester tester) {
  return MaterialLocalizations.of(tester.element(find.byType(HomeSection)));
}

List<Receipt> _homeTestReceipts(DateTime referenceDate) {
  final amounts = [120.00, 101.45, 100.00, 90.00];
  final titles = [
    'Studio rent top-up',
    'Quarterly electricity bill',
    'Spring grocery split',
    'Weekend train tickets',
  ];
  return [
    for (var index = 0; index < amounts.length; index++)
      _testReceipt(
        id: 100 + index,
        title: titles[index],
        amountOwed: amounts[index],
        dueDate: _placeholderDueDate(
          referenceDate,
          index + 1,
        ).toIso8601String(),
        split: index == 0
            ? ReceiptSplit(
                ownerSharePercent: 66.67,
                ownerAmount: 80,
                ownerAmountPaid: 25,
                recipientShares: [
                  ReceiptRecipientShare(
                    userId: Int64(20),
                    sharePercent: 33.33,
                    amount: 40,
                    amountPaid: 0,
                    user: _testUser(
                      id: 20,
                      name: 'Alice',
                      email: 'alice@test.dev',
                    ),
                  ),
                ],
              )
            : null,
        tags: [
          TagIndex(
            id: Int64(10 + index),
            icon: '🏷️',
            text: 'Home tag ${index + 1}',
            color: '#64B5F6',
          ),
          if (index == 0)
            TagIndex(
              id: Int64(99),
              icon: '⚠️',
              text: 'Long recommendation tag',
              color: '#E57373',
            ),
          if (index == 0)
            TagIndex(
              id: Int64(100),
              icon: '💡',
              text: 'Shared utilities',
              color: '#BA68C8',
            ),
          if (index == 0)
            TagIndex(
              id: Int64(101),
              icon: '🧾',
              text: 'April household',
              color: '#4DB6AC',
            ),
        ],
      ),
  ];
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

TagIndex _chartTag(int id, String text) {
  return TagIndex(id: Int64(id), icon: '#', text: text, color: '#667EEA');
}

ReceiptChartSummaryResponse _chartSummary({
  List<ReceiptChartTagBucket>? buckets,
}) {
  final tags = [_chartTag(1, 'Rent'), _chartTag(2, 'Utilities')];
  final resolvedBuckets =
      buckets ??
      [
        ReceiptChartTagBucket(
          tag: tags[0],
          paidShare: 30,
          openShare: 15,
          overdueOpenShare: 0,
          receiptCount: 2,
        ),
        ReceiptChartTagBucket(
          tag: tags[1],
          paidShare: 10,
          openShare: 20,
          overdueOpenShare: 5,
          receiptCount: 1,
        ),
      ];
  return ReceiptChartSummaryResponse(
    success: true,
    totals: ReceiptChartStatusTotals(
      paidShare: 40,
      openShare: 35,
      overdueOpenShare: 5,
    ),
    tagBuckets: resolvedBuckets,
    availableTags: tags,
    defaultTagIds: tags.map((tag) => tag.id),
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
  double? amountPaid,
  bool isPaid = false,
  int ownerId = 10,
  String? dueDate,
  String? description,
  List<TagIndex> tags = const [],
  List<ReceiptFile> files = const [],
  ReceiptSplit? split,
}) {
  final receipt = Receipt(
    id: Int64(id),
    title: title,
    amountOwed: amountOwed,
    isPaid: isPaid,
    currency: 'EUR',
    ownerId: Int64(ownerId),
    recipient: Recipient(
      id: Int64(77),
      name: 'Shared group',
      ownerId: Int64(ownerId),
      createdAt: '2026-05-05T00:00:00Z',
    ),
    dueDate: dueDate,
    tags: tags,
    files: files,
  );
  if (description != null) {
    receipt.description = description;
  }
  if (amountPaid != null) {
    receipt.amountPaid = amountPaid;
  }
  if (split != null) {
    receipt.split = split;
  }
  return receipt;
}

User _testUser({
  required int id,
  required String name,
  required String email,
  bool deleted = false,
}) {
  return User(
    id: Int64(id),
    sub: 'auth0|$id',
    name: name,
    email: email,
    deleted: deleted,
  );
}

Recipient _testRecipient({
  required int id,
  required String name,
  required int ownerId,
  String? description,
  List<User> members = const [],
}) {
  final recipient = Recipient(
    id: Int64(id),
    name: name,
    ownerId: Int64(ownerId),
    createdAt: '2026-05-05T00:00:00Z',
  );
  if (description != null) {
    recipient.description = description;
  }
  recipient.members.addAll(members.map((member) => member.deepCopy()));
  recipient.memberIds.addAll(members.map((member) => member.id));
  return recipient;
}

class _FakeDebtBackendService extends DebtBackendService {
  _FakeDebtBackendService({
    required this.onListReceipts,
    this.availableTags = const [],
    this.chartSummary,
    this.unpaidSummaryTotal = 0,
    this.unpaidSummaryCount = 0,
    List<Recipient>? recipients,
    this.onSearchUsers,
    this.onSetReceiptPayments,
    this.onGetOrCreateTag,
    // ignore: unused_element_parameter
    this.onSetReceiptTags,
    this.onUploadReceiptFile,
    this.onDeleteReceipt,
    this.onDownloadReceiptFile,
    this.createRecipientSucceeds = true,
    this.mutationErrorMessage = 'Mutation failed',
  }) : super(dio: Dio()) {
    if (recipients != null) {
      this.recipients.addAll(
        recipients.map((recipient) => recipient.deepCopy()),
      );
    }
  }

  final List<TagIndex> availableTags;
  final ReceiptChartSummaryResponse? chartSummary;
  final double unpaidSummaryTotal;
  final int unpaidSummaryCount;
  final ReceiptsResponse Function(ReceiptListRequest request) onListReceipts;
  final FutureOr<UsersResponse> Function(UserSearchRequest request)?
  onSearchUsers;
  final ReceiptResponse Function(SetReceiptPaymentsRequest request)?
  onSetReceiptPayments;
  final FutureOr<TagResponse> Function(TagUpsertRequest request)?
  onGetOrCreateTag;
  final FutureOr<ActionResponse> Function(SetReceiptTagsRequest request)?
  onSetReceiptTags;
  final FutureOr<FileResponse> Function(
    ({int receiptId, String filename, Uint8List bytes, String? contentType}),
  )?
  onUploadReceiptFile;
  final FutureOr<ActionResponse> Function(ReceiptLookupRequest request)?
  onDeleteReceipt;
  final FutureOr<ReceiptFileDownload> Function(ReceiptFile file)?
  onDownloadReceiptFile;
  final bool createRecipientSucceeds;
  final String mutationErrorMessage;
  final List<Recipient> recipients = <Recipient>[];
  final List<ReceiptListRequest> requests = <ReceiptListRequest>[];
  final List<ReceiptChartSummaryRequest> chartRequests =
      <ReceiptChartSummaryRequest>[];
  final List<UserSearchRequest> searchRequests = <UserSearchRequest>[];
  final List<CreateRecipientRequest> createRecipientRequests =
      <CreateRecipientRequest>[];
  final List<UpdateRecipientRequest> updateRecipientRequests =
      <UpdateRecipientRequest>[];
  final List<RecipientMemberRequest> addMemberRequests =
      <RecipientMemberRequest>[];
  final List<RecipientMemberRequest> removeMemberRequests =
      <RecipientMemberRequest>[];
  final List<RecipientLookupRequest> deleteRecipientRequests =
      <RecipientLookupRequest>[];
  final List<SetReceiptPaymentsRequest> setPaymentRequests =
      <SetReceiptPaymentsRequest>[];
  final List<CreateReceiptRequest> createReceiptRequests =
      <CreateReceiptRequest>[];
  final List<ReceiptLookupRequest> deleteReceiptRequests =
      <ReceiptLookupRequest>[];
  final List<TagUpsertRequest> tagUpsertRequests = <TagUpsertRequest>[];
  final List<SetReceiptTagsRequest> setReceiptTagRequests =
      <SetReceiptTagsRequest>[];
  final List<({int receiptId, String filename, Uint8List bytes})>
  uploadedFiles = <({int receiptId, String filename, Uint8List bytes})>[];
  int listRecipientsCalls = 0;

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
  Future<ReceiptUnpaidSummaryResponse> getUnpaidReceiptSummary(
    String accessToken,
  ) async {
    return ReceiptUnpaidSummaryResponse(
      success: true,
      unpaidShareTotal: unpaidSummaryTotal,
      unpaidBillCount: unpaidSummaryCount,
    );
  }

  @override
  Future<ReceiptChartSummaryResponse> getReceiptChartSummary(
    String accessToken,
    ReceiptChartSummaryRequest request,
  ) async {
    final clonedRequest = request.deepCopy();
    chartRequests.add(clonedRequest);
    return chartSummary?.deepCopy() ??
        ReceiptChartSummaryResponse(success: true);
  }

  @override
  Future<TagsResponse> listTags(String accessToken) async {
    final response = TagsResponse(success: true);
    response.tags.addAll(availableTags.map((tag) => tag.deepCopy()));
    return response;
  }

  @override
  Future<TagsResponse> listRecommendedTags(String accessToken) async {
    final response = TagsResponse(success: true);
    response.tags.addAll(availableTags.map((tag) => tag.deepCopy()));
    return response;
  }

  @override
  Future<UsersResponse> searchUsers(
    String accessToken,
    UserSearchRequest request,
  ) async {
    final clonedRequest = request.deepCopy();
    searchRequests.add(clonedRequest);
    if (onSearchUsers != null) {
      return await onSearchUsers!(clonedRequest);
    }
    return UsersResponse(success: true);
  }

  @override
  Future<ReceiptResponse> setReceiptPayments(
    String accessToken,
    SetReceiptPaymentsRequest request,
  ) async {
    final clonedRequest = request.deepCopy();
    setPaymentRequests.add(clonedRequest);
    if (onSetReceiptPayments != null) {
      return onSetReceiptPayments!(clonedRequest);
    }
    return ReceiptResponse(success: true);
  }

  @override
  Future<ReceiptResponse> createReceipt(
    String accessToken,
    CreateReceiptRequest request,
  ) async {
    final clonedRequest = request.deepCopy();
    createReceiptRequests.add(clonedRequest);
    return ReceiptResponse(
      success: true,
      receipt: _testReceipt(
        id: 900 + createReceiptRequests.length,
        title: clonedRequest.title,
        amountOwed: clonedRequest.amountOwed,
      ),
    );
  }

  @override
  Future<RecipientsResponse> listRecipients(String accessToken) async {
    listRecipientsCalls += 1;
    final response = RecipientsResponse(success: true);
    response.recipients.addAll(
      recipients.map((recipient) => recipient.deepCopy()),
    );
    return response;
  }

  @override
  Future<TagResponse> getOrCreateTag(
    String accessToken,
    TagUpsertRequest request,
  ) async {
    final clonedRequest = request.deepCopy();
    tagUpsertRequests.add(clonedRequest);
    if (onGetOrCreateTag != null) {
      return await onGetOrCreateTag!(clonedRequest);
    }
    return TagResponse(
      success: true,
      tag: TagIndex(
        id: Int64(300 + tagUpsertRequests.length),
        text: clonedRequest.text,
        icon: clonedRequest.icon,
        color: clonedRequest.color,
      ),
    );
  }

  @override
  Future<ActionResponse> setReceiptTags(
    String accessToken,
    SetReceiptTagsRequest request,
  ) async {
    final clonedRequest = request.deepCopy();
    setReceiptTagRequests.add(clonedRequest);
    if (onSetReceiptTags != null) {
      return await onSetReceiptTags!(clonedRequest);
    }
    return ActionResponse(success: true);
  }

  @override
  Future<FileResponse> uploadReceiptFile(
    String accessToken, {
    required int receiptId,
    required String filename,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final clonedBytes = Uint8List.fromList(bytes);
    uploadedFiles.add((
      receiptId: receiptId,
      filename: filename,
      bytes: clonedBytes,
    ));
    if (onUploadReceiptFile != null) {
      return await onUploadReceiptFile!((
        receiptId: receiptId,
        filename: filename,
        bytes: clonedBytes,
        contentType: contentType,
      ));
    }
    return FileResponse(
      success: true,
      file: ReceiptFile(
        id: Int64(400 + uploadedFiles.length),
        receiptId: Int64(receiptId),
        originalFilename: filename,
        contentType: contentType,
        sizeBytes: Int64(bytes.length),
      ),
    );
  }

  @override
  Future<ActionResponse> deleteReceipt(
    String accessToken,
    ReceiptLookupRequest request,
  ) async {
    final clonedRequest = request.deepCopy();
    deleteReceiptRequests.add(clonedRequest);
    if (onDeleteReceipt != null) {
      return await onDeleteReceipt!(clonedRequest);
    }
    return ActionResponse(success: true);
  }

  @override
  Future<ReceiptFileDownload> downloadReceiptFile(
    String accessToken,
    ReceiptFile file,
  ) async {
    final clonedFile = file.deepCopy();
    if (onDownloadReceiptFile != null) {
      return await onDownloadReceiptFile!(clonedFile);
    }
    return ReceiptFileDownload(
      file: clonedFile,
      bytes: Uint8List(0),
      contentType: clonedFile.hasContentType()
          ? clonedFile.contentType
          : 'application/octet-stream',
    );
  }

  @override
  Future<RecipientResponse> createRecipient(
    String accessToken,
    CreateRecipientRequest request,
  ) async {
    final clonedRequest = request.deepCopy();
    createRecipientRequests.add(clonedRequest);
    if (!createRecipientSucceeds) {
      return RecipientResponse(success: false, message: mutationErrorMessage);
    }
    final recipient = Recipient(
      id: Int64(100 + recipients.length),
      name: clonedRequest.name,
      ownerId: Int64(10),
      createdAt: '2026-05-05T00:00:00Z',
    );
    if (clonedRequest.hasDescription()) {
      recipient.description = clonedRequest.description;
    }
    recipient.memberIds.addAll(clonedRequest.memberIds);
    recipients.add(recipient);
    return RecipientResponse(success: true, recipient: recipient.deepCopy());
  }

  @override
  Future<RecipientResponse> updateRecipient(
    String accessToken,
    UpdateRecipientRequest request,
  ) async {
    final clonedRequest = request.deepCopy();
    updateRecipientRequests.add(clonedRequest);
    final index = recipients.indexWhere(
      (recipient) => recipient.id == clonedRequest.recipientId,
    );
    if (index >= 0) {
      if (clonedRequest.hasName()) {
        recipients[index].name = clonedRequest.name;
      }
      if (clonedRequest.hasDescription()) {
        recipients[index].description = clonedRequest.description;
      }
      return RecipientResponse(
        success: true,
        recipient: recipients[index].deepCopy(),
      );
    }
    return RecipientResponse(success: false, message: 'Recipient not found');
  }

  @override
  Future<ActionResponse> addRecipientMember(
    String accessToken,
    RecipientMemberRequest request,
  ) async {
    final clonedRequest = request.deepCopy();
    addMemberRequests.add(clonedRequest);
    final group = _findRecipient(clonedRequest.recipientId);
    group?.memberIds.add(clonedRequest.userId);
    return ActionResponse(success: true);
  }

  @override
  Future<ActionResponse> removeRecipientMember(
    String accessToken,
    RecipientMemberRequest request,
  ) async {
    final clonedRequest = request.deepCopy();
    removeMemberRequests.add(clonedRequest);
    final group = _findRecipient(clonedRequest.recipientId);
    group?.memberIds.remove(clonedRequest.userId);
    group?.members.removeWhere((user) => user.id == clonedRequest.userId);
    return ActionResponse(success: true);
  }

  @override
  Future<ActionResponse> deleteRecipient(
    String accessToken,
    RecipientLookupRequest request,
  ) async {
    final clonedRequest = request.deepCopy();
    deleteRecipientRequests.add(clonedRequest);
    recipients.removeWhere(
      (recipient) => recipient.id == clonedRequest.recipientId,
    );
    return ActionResponse(success: true);
  }

  Recipient? _findRecipient(Int64 recipientId) {
    for (final recipient in recipients) {
      if (recipient.id == recipientId) {
        return recipient;
      }
    }
    return null;
  }
}

class _TestAuthSessionState extends ChangeNotifier implements AuthSessionState {
  _TestAuthSessionState({
    bool isAuthenticatedValue = false,
    String? displayNameValue,
    String? userEmailValue,
    String? accessTokenValue,
    int? userIdValue,
  }) : _isAuthenticatedValue = isAuthenticatedValue,
       _displayNameValue = displayNameValue,
       _userEmailValue = userEmailValue,
       _accessTokenValue = accessTokenValue,
       _userIdValue = userIdValue;

  bool _isAuthenticatedValue;
  String? _displayNameValue;
  String? _userEmailValue;
  String? _accessTokenValue;
  int? _userIdValue;

  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Credentials? get credentials => null;

  @override
  String? get backendError => null;

  @override
  String? get accessToken => _accessTokenValue;

  @override
  String? get displayName => _displayNameValue;

  @override
  String get greeting {
    final name = _displayNameValue;
    if (name == null || name.isEmpty) {
      return 'Hi there';
    }
    return 'Hi, $name';
  }

  @override
  bool get isAuthenticated => _isAuthenticatedValue;

  @override
  bool get isLoading => false;

  @override
  int? get userId => _userIdValue;

  @override
  String? get userEmail => _userEmailValue;

  void updateSession({
    required bool isAuthenticated,
    required String? accessToken,
    required int? userId,
    String? displayName,
    String? userEmail,
  }) {
    _isAuthenticatedValue = isAuthenticated;
    _accessTokenValue = accessToken;
    _userIdValue = userId;
    _displayNameValue = displayName;
    _userEmailValue = userEmail;
    notifyListeners();
  }

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
