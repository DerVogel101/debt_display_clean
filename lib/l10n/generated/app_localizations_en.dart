// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'debt_display';

  @override
  String get brandTitle => 'Debt Display';

  @override
  String get brandSubtitle => 'Shared debt and receipts';

  @override
  String get destinationHome => 'Home';

  @override
  String get destinationBills => 'Bills';

  @override
  String get destinationCharts => 'Charts';

  @override
  String get destinationCreateBill => 'Create Bill';

  @override
  String get destinationRecipientGroups => 'Recipient groups';

  @override
  String get destinationProfile => 'Profile';

  @override
  String get destinationPrivacyPolicy => 'Privacy policy';

  @override
  String get destinationMenu => 'Menu';

  @override
  String get openNavigationTooltip => 'Open navigation';

  @override
  String get login => 'Log in';

  @override
  String get logout => 'Log out';

  @override
  String get user => 'User';

  @override
  String get hiThere => 'Hi there';

  @override
  String hiName(Object name) {
    return 'Hi, $name';
  }

  @override
  String get loadingSession => 'Restoring session...';

  @override
  String backendAuthFailed(Object message) {
    return 'Backend authentication failed: $message';
  }

  @override
  String get themeLight => 'Light';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeDark => 'Dark';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceDescription =>
      'Choose a light, auto, or dark theme mode. Dark mode uses your saved palette, with Dracula as the default fallback.';

  @override
  String get darkPalette => 'Dark palette';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageDescription =>
      'Use your device language automatically, or save a manual English or German override.';

  @override
  String get languageAuto => 'Auto';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get recentOutstandingBills => 'Recent outstanding bills';

  @override
  String get viewBills => 'View Bills';

  @override
  String get view => 'View';

  @override
  String get create => 'Create';

  @override
  String get createBill => 'Create Bill';

  @override
  String get homeAuthenticatedDescription =>
      'The newest unpaid bills you own or take part in.';

  @override
  String get homeLoggedOutDescription =>
      'Log in to load the bills you own or share with other participants.';

  @override
  String get loginToViewBills => 'Log in to view bills';

  @override
  String get noUnpaidBills => 'No unpaid bills right now.';

  @override
  String get totalStillOwed => 'Total still owed';

  @override
  String get totalStillOwedDescription =>
      'Combined balance across all unpaid bills you take part in.';

  @override
  String unpaidBillsNeedShare(int count) {
    return '$count unpaid bills need your share';
  }

  @override
  String get noDueDate => 'No due date';

  @override
  String dueDateLabel(Object date) {
    return 'Due $date';
  }

  @override
  String get personalBill => 'Personal bill';

  @override
  String get deletedUser => 'Deleted User';

  @override
  String get deletedAccount => 'Deleted account';

  @override
  String get menuDescription =>
      'Use this overflow area for profile access and appearance settings, especially on mobile where the bottom bar stays compact.';

  @override
  String get menuHomeDescription =>
      'Return to the unpaid bill dashboard and overview.';

  @override
  String get menuBillsDescription =>
      'Open the full bills view with filters, sorting, and pagination controls.';

  @override
  String get menuChartsDescription =>
      'Review paid, open, and overdue shares by date and tag.';

  @override
  String get menuCreateBillDescription =>
      'Create a bill with tags, splits, notes, and uploaded receipt files.';

  @override
  String get menuRecipientGroupsDescription =>
      'Create shared recipient groups and manage who can receive split bills.';

  @override
  String get menuProfileLoggedOutDescription =>
      'Open your account details to sign in and inspect your user data.';

  @override
  String get menuProfileLoggedInDescription =>
      'Review the synced account profile and active session details.';

  @override
  String get menuPrivacyPolicyDescription =>
      'Read the privacy policy and stored consent details.';

  @override
  String get privacyPolicyTitle => 'Privacy policy';

  @override
  String get privacyPolicyIntro =>
      'Please read and accept the privacy policy before using Debt Display.';

  @override
  String get privacyPolicyLoadFailed => 'Could not load the privacy policy.';

  @override
  String get acceptPrivacyPolicy => 'Accept and continue';

  @override
  String get revokePrivacyConsent => 'Revoke consent';

  @override
  String get sourceCodeTitle => 'Source code';

  @override
  String get sourceCodeDescription =>
      'Open the public GitHub repository for this application.';

  @override
  String get loginToContinue => 'Log in to continue';

  @override
  String get profileLoggedOutTitle => 'Your profile';

  @override
  String get profileLoggedOutDescription =>
      'Log in to inspect your synced profile and active session details.';

  @override
  String get accountProfileTitle => 'Account profile';

  @override
  String get signedInAs => 'Signed in as';

  @override
  String get emailLabel => 'Email';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get nicknameLabel => 'Nickname';

  @override
  String get userIdLabel => 'User ID';

  @override
  String get notAvailable => 'N/A';

  @override
  String get sessionDetailsTitle => 'Session details';

  @override
  String get billsDescription =>
      'Browse every receipt you can access as owner, participant, or both.';

  @override
  String get refresh => 'Refresh';

  @override
  String get filters => 'Filters';

  @override
  String filtersCount(int count) {
    return 'Filters ($count)';
  }

  @override
  String get role => 'Role';

  @override
  String get both => 'Both';

  @override
  String get owner => 'Owner';

  @override
  String get member => 'Member';

  @override
  String get participant => 'Participant';

  @override
  String get paymentStatus => 'Payment status';

  @override
  String get all => 'All';

  @override
  String get paid => 'Paid';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get tags => 'Tags';

  @override
  String get tagsFilterHelper =>
      'Each selected tag must be present on a receipt.';

  @override
  String get noTagsAvailable => 'No tags available yet.';

  @override
  String get sortBy => 'Sort by';

  @override
  String get direction => 'Direction';

  @override
  String get pageSize => 'Page size';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Apply';

  @override
  String get id => 'ID';

  @override
  String get total => 'Total';

  @override
  String get myShare => 'My share';

  @override
  String get stillOwed => 'Still owed';

  @override
  String get dueDate => 'Due date';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get visibleReceipts => 'Visible receipts';

  @override
  String pageNumber(int page) {
    return 'Page $page';
  }

  @override
  String get noBillsMatch => 'No bills match the current filters.';

  @override
  String get participants => 'Participants';

  @override
  String couldNotLoadBills(Object message) {
    return 'Could not load bills. $message';
  }

  @override
  String get payments => 'Payments';

  @override
  String get ownerPaid => 'Owner paid';

  @override
  String shareAmount(Object amount) {
    return 'Share $amount';
  }

  @override
  String userPaid(Object user) {
    return '$user paid';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get deleteBill => 'Delete bill';

  @override
  String get deleteBillQuestion => 'Delete bill?';

  @override
  String deleteBillContent(Object title) {
    return 'Delete \"$title\" permanently.';
  }

  @override
  String get billDeleted => 'Bill deleted.';

  @override
  String get couldNotDeleteBill => 'Could not delete bill.';

  @override
  String get open => 'Open';

  @override
  String get previewUnavailable => 'Preview unavailable';

  @override
  String get couldNotOpenFile => 'Could not open file.';

  @override
  String get paymentOwnerExceeded =>
      'Owner paid amount cannot exceed owner share.';

  @override
  String get paymentInvalidOwner => 'Enter a valid owner paid amount.';

  @override
  String get paymentInvalidRecipient => 'Enter valid recipient paid amounts.';

  @override
  String get paymentRecipientExceeded =>
      'Recipient paid amounts cannot exceed their shares.';

  @override
  String get couldNotSavePayments => 'Could not save payments.';

  @override
  String get participantHeader => 'Participant';

  @override
  String get shareHeader => 'Share';

  @override
  String get paidHeader => 'Paid';

  @override
  String get leftHeader => 'Left';

  @override
  String get oneFileIncluded => '1 file included';

  @override
  String filesIncluded(int count) {
    return '$count files included';
  }

  @override
  String get createBillDescription =>
      'Create a shared bill, split it by group member, and attach receipts.';

  @override
  String get refreshBillFormData => 'Refresh bill form data';

  @override
  String get notes => 'Notes';

  @override
  String get pickEmoji => 'Pick emoji';

  @override
  String get pickTagColor => 'Pick tag color';

  @override
  String get sharesMustAddTo100 => 'Shares must add up to 100%.';

  @override
  String get billCreated => 'Bill created.';

  @override
  String get loginToCreateBills => 'Log in to create bills';

  @override
  String get basics => 'Basics';

  @override
  String get details => 'Details';

  @override
  String get title => 'Title';

  @override
  String get titleRequired => 'Title is required.';

  @override
  String get titleTooLong => 'Title must be 256 characters or fewer.';

  @override
  String get shortDescription => 'Short description';

  @override
  String get descriptionTooLong =>
      'Description must be 256 characters or fewer.';

  @override
  String get amount => 'Amount';

  @override
  String get validAmountRequired => 'Enter a valid amount.';

  @override
  String get currency => 'Currency';

  @override
  String get searchRecommendedTags => 'Search recommended tags';

  @override
  String get noRecommendedTags => 'No recommended tags yet.';

  @override
  String get noTagsMatch => 'No tags match.';

  @override
  String get pickTagEmoji => 'Pick tag emoji';

  @override
  String get newTag => 'New tag';

  @override
  String get add => 'Add';

  @override
  String get groupAndShares => 'Group and shares';

  @override
  String get group => 'Group';

  @override
  String get complete100 => '100% complete';

  @override
  String needPercent(Object percent) {
    return 'Need +$percent%';
  }

  @override
  String reducePercent(Object percent) {
    return 'Reduce $percent%';
  }

  @override
  String get files => 'Files';

  @override
  String get upload => 'Upload';

  @override
  String get takePicture => 'Take picture';

  @override
  String get takePictureMobileOnly =>
      'Take picture is available on mobile browsers so iOS can open the native camera flow.';

  @override
  String get filename => 'Filename';

  @override
  String get removeFile => 'Remove file';

  @override
  String get recipientGroupsDescription =>
      'Create shared recipient groups and manage who can receive split bills.';

  @override
  String get loginToManageGroups => 'Log in to manage groups';

  @override
  String get noRecipientGroups => 'No recipient groups yet.';

  @override
  String get editGroup => 'Edit group';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get deleteRecipientGroupQuestion => 'Delete recipient group?';

  @override
  String deleteRecipientGroupContent(Object name) {
    return 'Delete $name? Existing bills will no longer point to it.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get createRecipientGroup => 'Create recipient group';

  @override
  String get editRecipientGroup => 'Edit recipient group';

  @override
  String get groupName => 'Group name';

  @override
  String get description => 'Description';

  @override
  String get members => 'Members';

  @override
  String get noMembersSelected => 'No members selected';

  @override
  String get findUser => 'Find user';

  @override
  String get findUserHelper => 'Type at least 3 characters from name or email.';

  @override
  String get addMember => 'Add member';

  @override
  String get noMembers => 'No members';

  @override
  String get chartsDescription =>
      'Track your paid, open, and overdue shares across visible receipts.';

  @override
  String get loginToViewCharts => 'Log in to view charts';

  @override
  String get chartDateRange => 'Date range';

  @override
  String get chartAllTime => 'All time';

  @override
  String get chartLast30Days => 'Last 30 days';

  @override
  String get chartLast90Days => 'Last 90 days';

  @override
  String get chartThisYear => 'This year';

  @override
  String get chartCustom => 'Custom';

  @override
  String get chartFromDate => 'From';

  @override
  String get chartToDate => 'To';

  @override
  String get chartPickDate => 'Pick date';

  @override
  String get chartClearDate => 'Clear';

  @override
  String get chartDebtBreakdown => 'Debt breakdown';

  @override
  String get chartTagBreakdown => 'Tag breakdown';

  @override
  String get chartNoData => 'No chart data for this range.';

  @override
  String get chartNoTags => 'No tags available for this range.';

  @override
  String get chartPaidShare => 'Paid share';

  @override
  String get chartOpenShare => 'Open share';

  @override
  String get chartOverdueOpenShare => 'Overdue open share';

  @override
  String get chartSelectTags => 'Tags';

  @override
  String chartReceiptsCount(int count) {
    return '$count receipts';
  }

  @override
  String couldNotLoadCharts(Object message) {
    return 'Could not load charts. $message';
  }
}
