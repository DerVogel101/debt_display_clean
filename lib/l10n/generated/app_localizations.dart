import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'debt_display'**
  String get appTitle;

  /// No description provided for @brandTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt Display'**
  String get brandTitle;

  /// No description provided for @brandSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shared debt and receipts'**
  String get brandSubtitle;

  /// No description provided for @destinationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get destinationHome;

  /// No description provided for @destinationBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get destinationBills;

  /// No description provided for @destinationCreateBill.
  ///
  /// In en, this message translates to:
  /// **'Create Bill'**
  String get destinationCreateBill;

  /// No description provided for @destinationRecipientGroups.
  ///
  /// In en, this message translates to:
  /// **'Recipient groups'**
  String get destinationRecipientGroups;

  /// No description provided for @destinationProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get destinationProfile;

  /// No description provided for @destinationMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get destinationMenu;

  /// No description provided for @openNavigationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open navigation'**
  String get openNavigationTooltip;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @hiThere.
  ///
  /// In en, this message translates to:
  /// **'Hi there'**
  String get hiThere;

  /// No description provided for @hiName.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String hiName(Object name);

  /// No description provided for @loadingSession.
  ///
  /// In en, this message translates to:
  /// **'Restoring session...'**
  String get loadingSession;

  /// No description provided for @backendAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Backend authentication failed: {message}'**
  String backendAuthFailed(Object message);

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a light, auto, or dark theme mode. Dark mode uses your saved palette, with Dracula as the default fallback.'**
  String get appearanceDescription;

  /// No description provided for @darkPalette.
  ///
  /// In en, this message translates to:
  /// **'Dark palette'**
  String get darkPalette;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Use your device language automatically, or save a manual English or German override.'**
  String get languageDescription;

  /// No description provided for @languageAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get languageAuto;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @recentOutstandingBills.
  ///
  /// In en, this message translates to:
  /// **'Recent outstanding bills'**
  String get recentOutstandingBills;

  /// No description provided for @viewBills.
  ///
  /// In en, this message translates to:
  /// **'View Bills'**
  String get viewBills;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createBill.
  ///
  /// In en, this message translates to:
  /// **'Create Bill'**
  String get createBill;

  /// No description provided for @homeAuthenticatedDescription.
  ///
  /// In en, this message translates to:
  /// **'The newest unpaid bills you own or take part in.'**
  String get homeAuthenticatedDescription;

  /// No description provided for @homeLoggedOutDescription.
  ///
  /// In en, this message translates to:
  /// **'Log in to load the bills you own or share with other participants.'**
  String get homeLoggedOutDescription;

  /// No description provided for @loginToViewBills.
  ///
  /// In en, this message translates to:
  /// **'Log in to view bills'**
  String get loginToViewBills;

  /// No description provided for @noUnpaidBills.
  ///
  /// In en, this message translates to:
  /// **'No unpaid bills right now.'**
  String get noUnpaidBills;

  /// No description provided for @totalStillOwed.
  ///
  /// In en, this message translates to:
  /// **'Total still owed'**
  String get totalStillOwed;

  /// No description provided for @totalStillOwedDescription.
  ///
  /// In en, this message translates to:
  /// **'Combined balance across all unpaid bills you take part in.'**
  String get totalStillOwedDescription;

  /// No description provided for @unpaidBillsNeedShare.
  ///
  /// In en, this message translates to:
  /// **'{count} unpaid bills need your share'**
  String unpaidBillsNeedShare(int count);

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueDateLabel(Object date);

  /// No description provided for @personalBill.
  ///
  /// In en, this message translates to:
  /// **'Personal bill'**
  String get personalBill;

  /// No description provided for @deletedUser.
  ///
  /// In en, this message translates to:
  /// **'Deleted User'**
  String get deletedUser;

  /// No description provided for @deletedAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleted account'**
  String get deletedAccount;

  /// No description provided for @menuDescription.
  ///
  /// In en, this message translates to:
  /// **'Use this overflow area for profile access and appearance settings, especially on mobile where the bottom bar stays compact.'**
  String get menuDescription;

  /// No description provided for @menuHomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Return to the unpaid bill dashboard and overview.'**
  String get menuHomeDescription;

  /// No description provided for @menuBillsDescription.
  ///
  /// In en, this message translates to:
  /// **'Open the full bills view with filters, sorting, and pagination controls.'**
  String get menuBillsDescription;

  /// No description provided for @menuCreateBillDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a bill with tags, splits, notes, and uploaded receipt files.'**
  String get menuCreateBillDescription;

  /// No description provided for @menuRecipientGroupsDescription.
  ///
  /// In en, this message translates to:
  /// **'Create shared recipient groups and manage who can receive split bills.'**
  String get menuRecipientGroupsDescription;

  /// No description provided for @menuProfileLoggedOutDescription.
  ///
  /// In en, this message translates to:
  /// **'Open your account details to sign in and inspect your user data.'**
  String get menuProfileLoggedOutDescription;

  /// No description provided for @menuProfileLoggedInDescription.
  ///
  /// In en, this message translates to:
  /// **'Review the synced account profile and active session details.'**
  String get menuProfileLoggedInDescription;

  /// No description provided for @loginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue'**
  String get loginToContinue;

  /// No description provided for @profileLoggedOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileLoggedOutTitle;

  /// No description provided for @profileLoggedOutDescription.
  ///
  /// In en, this message translates to:
  /// **'Log in to inspect your synced profile and active session details.'**
  String get profileLoggedOutDescription;

  /// No description provided for @accountProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Account profile'**
  String get accountProfileTitle;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get signedInAs;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @nicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nicknameLabel;

  /// No description provided for @userIdLabel.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userIdLabel;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @sessionDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Session details'**
  String get sessionDetailsTitle;

  /// No description provided for @billsDescription.
  ///
  /// In en, this message translates to:
  /// **'Browse every receipt you can access as owner, participant, or both.'**
  String get billsDescription;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filtersCount.
  ///
  /// In en, this message translates to:
  /// **'Filters ({count})'**
  String filtersCount(int count);

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @both.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get both;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @participant.
  ///
  /// In en, this message translates to:
  /// **'Participant'**
  String get participant;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get paymentStatus;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tagsFilterHelper.
  ///
  /// In en, this message translates to:
  /// **'Each selected tag must be present on a receipt.'**
  String get tagsFilterHelper;

  /// No description provided for @noTagsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tags available yet.'**
  String get noTagsAvailable;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @direction.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get direction;

  /// No description provided for @pageSize.
  ///
  /// In en, this message translates to:
  /// **'Page size'**
  String get pageSize;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @myShare.
  ///
  /// In en, this message translates to:
  /// **'My share'**
  String get myShare;

  /// No description provided for @stillOwed.
  ///
  /// In en, this message translates to:
  /// **'Still owed'**
  String get stillOwed;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @visibleReceipts.
  ///
  /// In en, this message translates to:
  /// **'Visible receipts'**
  String get visibleReceipts;

  /// No description provided for @pageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String pageNumber(int page);

  /// No description provided for @noBillsMatch.
  ///
  /// In en, this message translates to:
  /// **'No bills match the current filters.'**
  String get noBillsMatch;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @couldNotLoadBills.
  ///
  /// In en, this message translates to:
  /// **'Could not load bills. {message}'**
  String couldNotLoadBills(Object message);

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @ownerPaid.
  ///
  /// In en, this message translates to:
  /// **'Owner paid'**
  String get ownerPaid;

  /// No description provided for @shareAmount.
  ///
  /// In en, this message translates to:
  /// **'Share {amount}'**
  String shareAmount(Object amount);

  /// No description provided for @userPaid.
  ///
  /// In en, this message translates to:
  /// **'{user} paid'**
  String userPaid(Object user);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @previewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable'**
  String get previewUnavailable;

  /// No description provided for @couldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open file.'**
  String get couldNotOpenFile;

  /// No description provided for @paymentOwnerExceeded.
  ///
  /// In en, this message translates to:
  /// **'Owner paid amount cannot exceed owner share.'**
  String get paymentOwnerExceeded;

  /// No description provided for @paymentInvalidOwner.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid owner paid amount.'**
  String get paymentInvalidOwner;

  /// No description provided for @paymentInvalidRecipient.
  ///
  /// In en, this message translates to:
  /// **'Enter valid recipient paid amounts.'**
  String get paymentInvalidRecipient;

  /// No description provided for @paymentRecipientExceeded.
  ///
  /// In en, this message translates to:
  /// **'Recipient paid amounts cannot exceed their shares.'**
  String get paymentRecipientExceeded;

  /// No description provided for @couldNotSavePayments.
  ///
  /// In en, this message translates to:
  /// **'Could not save payments.'**
  String get couldNotSavePayments;

  /// No description provided for @participantHeader.
  ///
  /// In en, this message translates to:
  /// **'Participant'**
  String get participantHeader;

  /// No description provided for @shareHeader.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareHeader;

  /// No description provided for @paidHeader.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidHeader;

  /// No description provided for @leftHeader.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get leftHeader;

  /// No description provided for @oneFileIncluded.
  ///
  /// In en, this message translates to:
  /// **'1 file included'**
  String get oneFileIncluded;

  /// No description provided for @filesIncluded.
  ///
  /// In en, this message translates to:
  /// **'{count} files included'**
  String filesIncluded(int count);

  /// No description provided for @createBillDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a shared bill, split it by group member, and attach receipts.'**
  String get createBillDescription;

  /// No description provided for @refreshBillFormData.
  ///
  /// In en, this message translates to:
  /// **'Refresh bill form data'**
  String get refreshBillFormData;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @pickEmoji.
  ///
  /// In en, this message translates to:
  /// **'Pick emoji'**
  String get pickEmoji;

  /// No description provided for @pickTagColor.
  ///
  /// In en, this message translates to:
  /// **'Pick tag color'**
  String get pickTagColor;

  /// No description provided for @sharesMustAddTo100.
  ///
  /// In en, this message translates to:
  /// **'Shares must add up to 100%.'**
  String get sharesMustAddTo100;

  /// No description provided for @billCreated.
  ///
  /// In en, this message translates to:
  /// **'Bill created.'**
  String get billCreated;

  /// No description provided for @loginToCreateBills.
  ///
  /// In en, this message translates to:
  /// **'Log in to create bills'**
  String get loginToCreateBills;

  /// No description provided for @basics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get basics;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required.'**
  String get titleRequired;

  /// No description provided for @titleTooLong.
  ///
  /// In en, this message translates to:
  /// **'Title must be 256 characters or fewer.'**
  String get titleTooLong;

  /// No description provided for @shortDescription.
  ///
  /// In en, this message translates to:
  /// **'Short description'**
  String get shortDescription;

  /// No description provided for @descriptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Description must be 256 characters or fewer.'**
  String get descriptionTooLong;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @validAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get validAmountRequired;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @searchRecommendedTags.
  ///
  /// In en, this message translates to:
  /// **'Search recommended tags'**
  String get searchRecommendedTags;

  /// No description provided for @noRecommendedTags.
  ///
  /// In en, this message translates to:
  /// **'No recommended tags yet.'**
  String get noRecommendedTags;

  /// No description provided for @noTagsMatch.
  ///
  /// In en, this message translates to:
  /// **'No tags match.'**
  String get noTagsMatch;

  /// No description provided for @pickTagEmoji.
  ///
  /// In en, this message translates to:
  /// **'Pick tag emoji'**
  String get pickTagEmoji;

  /// No description provided for @newTag.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get newTag;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @groupAndShares.
  ///
  /// In en, this message translates to:
  /// **'Group and shares'**
  String get groupAndShares;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @complete100.
  ///
  /// In en, this message translates to:
  /// **'100% complete'**
  String get complete100;

  /// No description provided for @needPercent.
  ///
  /// In en, this message translates to:
  /// **'Need +{percent}%'**
  String needPercent(Object percent);

  /// No description provided for @reducePercent.
  ///
  /// In en, this message translates to:
  /// **'Reduce {percent}%'**
  String reducePercent(Object percent);

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @takePicture.
  ///
  /// In en, this message translates to:
  /// **'Take picture'**
  String get takePicture;

  /// No description provided for @takePictureMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Take picture is available on mobile browsers so iOS can open the native camera flow.'**
  String get takePictureMobileOnly;

  /// No description provided for @filename.
  ///
  /// In en, this message translates to:
  /// **'Filename'**
  String get filename;

  /// No description provided for @removeFile.
  ///
  /// In en, this message translates to:
  /// **'Remove file'**
  String get removeFile;

  /// No description provided for @recipientGroupsDescription.
  ///
  /// In en, this message translates to:
  /// **'Create shared recipient groups and manage who can receive split bills.'**
  String get recipientGroupsDescription;

  /// No description provided for @loginToManageGroups.
  ///
  /// In en, this message translates to:
  /// **'Log in to manage groups'**
  String get loginToManageGroups;

  /// No description provided for @noRecipientGroups.
  ///
  /// In en, this message translates to:
  /// **'No recipient groups yet.'**
  String get noRecipientGroups;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @deleteRecipientGroupQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete recipient group?'**
  String get deleteRecipientGroupQuestion;

  /// No description provided for @deleteRecipientGroupContent.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? Existing bills will no longer point to it.'**
  String deleteRecipientGroupContent(Object name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @createRecipientGroup.
  ///
  /// In en, this message translates to:
  /// **'Create recipient group'**
  String get createRecipientGroup;

  /// No description provided for @editRecipientGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit recipient group'**
  String get editRecipientGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @noMembersSelected.
  ///
  /// In en, this message translates to:
  /// **'No members selected'**
  String get noMembersSelected;

  /// No description provided for @findUser.
  ///
  /// In en, this message translates to:
  /// **'Find user'**
  String get findUser;

  /// No description provided for @findUserHelper.
  ///
  /// In en, this message translates to:
  /// **'Type at least 3 characters from name or email.'**
  String get findUserHelper;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMember;

  /// No description provided for @noMembers.
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get noMembers;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
