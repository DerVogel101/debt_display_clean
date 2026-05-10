// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'debt_display';

  @override
  String get brandTitle => 'Debt Display';

  @override
  String get brandSubtitle => 'Geteilte Schulden und Belege';

  @override
  String get destinationHome => 'Start';

  @override
  String get destinationBills => 'Rechnungen';

  @override
  String get destinationCharts => 'Diagramme';

  @override
  String get destinationCreateBill => 'Rechnung erstellen';

  @override
  String get destinationRecipientGroups => 'Empfängergruppen';

  @override
  String get destinationProfile => 'Profil';

  @override
  String get destinationPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get destinationMenu => 'Menü';

  @override
  String get openNavigationTooltip => 'Navigation öffnen';

  @override
  String get login => 'Anmelden';

  @override
  String get logout => 'Abmelden';

  @override
  String get user => 'Benutzer';

  @override
  String get hiThere => 'Hallo';

  @override
  String hiName(Object name) {
    return 'Hallo, $name';
  }

  @override
  String get loadingSession => 'Sitzung wird wiederhergestellt...';

  @override
  String backendAuthFailed(Object message) {
    return 'Backend-Authentifizierung fehlgeschlagen: $message';
  }

  @override
  String get themeLight => 'Hell';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get appearanceTitle => 'Darstellung';

  @override
  String get appearanceDescription =>
      'Wähle hellen, automatischen oder dunklen Modus. Der dunkle Modus nutzt deine gespeicherte Palette, mit Dracula als Standard.';

  @override
  String get darkPalette => 'Dunkle Palette';

  @override
  String get languageTitle => 'Sprache';

  @override
  String get languageDescription =>
      'Nutze automatisch deine Gerätesprache oder speichere Englisch oder Deutsch manuell.';

  @override
  String get languageAuto => 'Auto';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get recentOutstandingBills => 'Aktuelle offene Rechnungen';

  @override
  String get viewBills => 'Rechnungen anzeigen';

  @override
  String get view => 'Anzeigen';

  @override
  String get create => 'Erstellen';

  @override
  String get createBill => 'Rechnung erstellen';

  @override
  String get homeAuthenticatedDescription =>
      'Die neuesten unbezahlten Rechnungen, die dir gehören oder an denen du beteiligt bist.';

  @override
  String get homeLoggedOutDescription =>
      'Melde dich an, um Rechnungen zu laden, die dir gehören oder die du mit anderen teilst.';

  @override
  String get loginToViewBills => 'Anmelden, um Rechnungen zu sehen';

  @override
  String get noUnpaidBills => 'Gerade keine offenen Rechnungen.';

  @override
  String get totalStillOwed => 'Noch offen gesamt';

  @override
  String get totalStillOwedDescription =>
      'Kombinierter Saldo aller unbezahlten Rechnungen, an denen du beteiligt bist.';

  @override
  String unpaidBillsNeedShare(int count) {
    return '$count unbezahlte Rechnungen brauchen deinen Anteil';
  }

  @override
  String get noDueDate => 'Kein Fälligkeitsdatum';

  @override
  String dueDateLabel(Object date) {
    return 'Fällig $date';
  }

  @override
  String get personalBill => 'Persönliche Rechnung';

  @override
  String get deletedUser => 'Gelöschter Benutzer';

  @override
  String get deletedAccount => 'Gelöschtes Konto';

  @override
  String get menuDescription =>
      'Nutze diesen Bereich für Profilzugriff und Darstellungseinstellungen, besonders auf Mobilgeräten mit kompakter Navigationsleiste.';

  @override
  String get menuHomeDescription => 'Zurück zur Übersicht offener Rechnungen.';

  @override
  String get menuBillsDescription =>
      'Öffne die komplette Rechnungsansicht mit Filtern, Sortierung und Seitensteuerung.';

  @override
  String get menuChartsDescription =>
      'Prüfe bezahlte, offene und überfällige Anteile nach Datum und Tag.';

  @override
  String get menuCreateBillDescription =>
      'Erstelle eine Rechnung mit Tags, Aufteilung, Notizen und Belegdateien.';

  @override
  String get menuRecipientGroupsDescription =>
      'Erstelle geteilte Empfängergruppen und verwalte, wer Rechnungen erhalten kann.';

  @override
  String get menuProfileLoggedOutDescription =>
      'Öffne deine Kontodetails, um dich anzumelden und deine Nutzerdaten zu prüfen.';

  @override
  String get menuProfileLoggedInDescription =>
      'Prüfe synchronisiertes Kontoprofil und aktive Sitzungsdetails.';

  @override
  String get menuPrivacyPolicyDescription =>
      'Lies die Datenschutzerklärung und die gespeicherte Zustimmung.';

  @override
  String get privacyPolicyTitle => 'Datenschutzerklärung';

  @override
  String get privacyPolicyIntro =>
      'Bitte lies und akzeptiere die Datenschutzerklärung, bevor du Debt Display nutzt.';

  @override
  String get privacyPolicyLoadFailed =>
      'Die Datenschutzerklärung konnte nicht geladen werden.';

  @override
  String get acceptPrivacyPolicy => 'Akzeptieren und fortfahren';

  @override
  String get revokePrivacyConsent => 'Zustimmung widerrufen';

  @override
  String get sourceCodeTitle => 'Quellcode';

  @override
  String get sourceCodeDescription =>
      'Öffne das öffentliche GitHub-Repository dieser Anwendung.';

  @override
  String get loginToContinue => 'Anmelden, um fortzufahren';

  @override
  String get profileLoggedOutTitle => 'Dein Profil';

  @override
  String get profileLoggedOutDescription =>
      'Melde dich an, um dein synchronisiertes Profil und aktive Sitzungsdetails zu prüfen.';

  @override
  String get accountProfileTitle => 'Kontoprofil';

  @override
  String get signedInAs => 'Angemeldet als';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get displayNameLabel => 'Anzeigename';

  @override
  String get nicknameLabel => 'Spitzname';

  @override
  String get userIdLabel => 'Benutzer-ID';

  @override
  String get notAvailable => 'k. A.';

  @override
  String get sessionDetailsTitle => 'Sitzungsdetails';

  @override
  String get billsDescription =>
      'Durchsuche alle Belege, auf die du als Besitzer, Teilnehmer oder beides Zugriff hast.';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get filters => 'Filter';

  @override
  String filtersCount(int count) {
    return 'Filter ($count)';
  }

  @override
  String get role => 'Rolle';

  @override
  String get both => 'Beides';

  @override
  String get owner => 'Besitzer';

  @override
  String get member => 'Mitglied';

  @override
  String get participant => 'Teilnehmer';

  @override
  String get paymentStatus => 'Zahlungsstatus';

  @override
  String get all => 'Alle';

  @override
  String get paid => 'Bezahlt';

  @override
  String get unpaid => 'Unbezahlt';

  @override
  String get tags => 'Tags';

  @override
  String get tagsFilterHelper =>
      'Jeder ausgewählte Tag muss auf einem Beleg vorhanden sein.';

  @override
  String get noTagsAvailable => 'Noch keine Tags verfügbar.';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get direction => 'Richtung';

  @override
  String get pageSize => 'Seitengröße';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get apply => 'Anwenden';

  @override
  String get id => 'ID';

  @override
  String get total => 'Gesamt';

  @override
  String get myShare => 'Mein Anteil';

  @override
  String get stillOwed => 'Noch offen';

  @override
  String get dueDate => 'Fälligkeit';

  @override
  String get ascending => 'Aufsteigend';

  @override
  String get descending => 'Absteigend';

  @override
  String get previous => 'Zurück';

  @override
  String get next => 'Weiter';

  @override
  String get visibleReceipts => 'Sichtbare Belege';

  @override
  String pageNumber(int page) {
    return 'Seite $page';
  }

  @override
  String get noBillsMatch =>
      'Keine Rechnungen passen zu den aktuellen Filtern.';

  @override
  String get participants => 'Teilnehmer';

  @override
  String couldNotLoadBills(Object message) {
    return 'Rechnungen konnten nicht geladen werden. $message';
  }

  @override
  String get payments => 'Zahlungen';

  @override
  String get ownerPaid => 'Besitzer bezahlt';

  @override
  String shareAmount(Object amount) {
    return 'Anteil $amount';
  }

  @override
  String userPaid(Object user) {
    return '$user bezahlt';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get deleteBill => 'Rechnung löschen';

  @override
  String get deleteBillQuestion => 'Rechnung löschen?';

  @override
  String deleteBillContent(Object title) {
    return '\"$title\" dauerhaft löschen.';
  }

  @override
  String get billDeleted => 'Rechnung gelöscht.';

  @override
  String get couldNotDeleteBill => 'Rechnung konnte nicht gelöscht werden.';

  @override
  String get open => 'Öffnen';

  @override
  String get previewUnavailable => 'Vorschau nicht verfügbar';

  @override
  String get couldNotOpenFile => 'Datei konnte nicht geöffnet werden.';

  @override
  String get paymentOwnerExceeded =>
      'Bezahlter Besitzerbetrag darf den Besitzeranteil nicht überschreiten.';

  @override
  String get paymentInvalidOwner =>
      'Gib einen gültigen bezahlten Besitzerbetrag ein.';

  @override
  String get paymentInvalidRecipient =>
      'Gib gültige bezahlte Empfängerbeträge ein.';

  @override
  String get paymentRecipientExceeded =>
      'Bezahlte Empfängerbeträge dürfen ihre Anteile nicht überschreiten.';

  @override
  String get couldNotSavePayments =>
      'Zahlungen konnten nicht gespeichert werden.';

  @override
  String get participantHeader => 'Teilnehmer';

  @override
  String get shareHeader => 'Anteil';

  @override
  String get paidHeader => 'Bezahlt';

  @override
  String get leftHeader => 'Offen';

  @override
  String get oneFileIncluded => '1 Datei enthalten';

  @override
  String filesIncluded(int count) {
    return '$count Dateien enthalten';
  }

  @override
  String get createBillDescription =>
      'Erstelle eine geteilte Rechnung, teile sie nach Gruppenmitgliedern auf und hänge Belege an.';

  @override
  String get refreshBillFormData => 'Rechnungsformular aktualisieren';

  @override
  String get notes => 'Notizen';

  @override
  String get pickEmoji => 'Emoji wählen';

  @override
  String get pickTagColor => 'Tag-Farbe wählen';

  @override
  String get sharesMustAddTo100 => 'Anteile müssen 100 % ergeben.';

  @override
  String get billCreated => 'Rechnung erstellt.';

  @override
  String get loginToCreateBills => 'Anmelden, um Rechnungen zu erstellen';

  @override
  String get basics => 'Grunddaten';

  @override
  String get details => 'Details';

  @override
  String get title => 'Titel';

  @override
  String get titleRequired => 'Titel ist erforderlich.';

  @override
  String get titleTooLong => 'Titel darf höchstens 256 Zeichen lang sein.';

  @override
  String get shortDescription => 'Kurzbeschreibung';

  @override
  String get descriptionTooLong =>
      'Beschreibung darf höchstens 256 Zeichen lang sein.';

  @override
  String get amount => 'Betrag';

  @override
  String get validAmountRequired => 'Gib einen gültigen Betrag ein.';

  @override
  String get currency => 'Währung';

  @override
  String get searchRecommendedTags => 'Empfohlene Tags suchen';

  @override
  String get noRecommendedTags => 'Noch keine empfohlenen Tags.';

  @override
  String get noTagsMatch => 'Keine passenden Tags.';

  @override
  String get pickTagEmoji => 'Tag-Emoji wählen';

  @override
  String get newTag => 'Neuer Tag';

  @override
  String get add => 'Hinzufügen';

  @override
  String get groupAndShares => 'Gruppe und Anteile';

  @override
  String get group => 'Gruppe';

  @override
  String get complete100 => '100 % komplett';

  @override
  String needPercent(Object percent) {
    return 'Braucht +$percent%';
  }

  @override
  String reducePercent(Object percent) {
    return '$percent% reduzieren';
  }

  @override
  String get files => 'Dateien';

  @override
  String get upload => 'Hochladen';

  @override
  String get takePicture => 'Foto aufnehmen';

  @override
  String get takePictureMobileOnly =>
      'Foto aufnehmen ist in mobilen Browsern verfügbar, damit iOS die native Kamera öffnen kann.';

  @override
  String get filename => 'Dateiname';

  @override
  String get removeFile => 'Datei entfernen';

  @override
  String get recipientGroupsDescription =>
      'Erstelle geteilte Empfängergruppen und verwalte, wer geteilte Rechnungen erhalten kann.';

  @override
  String get loginToManageGroups => 'Anmelden, um Gruppen zu verwalten';

  @override
  String get noRecipientGroups => 'Noch keine Empfängergruppen.';

  @override
  String get editGroup => 'Gruppe bearbeiten';

  @override
  String get deleteGroup => 'Gruppe löschen';

  @override
  String get deleteRecipientGroupQuestion => 'Empfängergruppe löschen?';

  @override
  String deleteRecipientGroupContent(Object name) {
    return '$name löschen? Bestehende Rechnungen zeigen dann nicht mehr darauf.';
  }

  @override
  String get delete => 'Löschen';

  @override
  String get createRecipientGroup => 'Empfängergruppe erstellen';

  @override
  String get editRecipientGroup => 'Empfängergruppe bearbeiten';

  @override
  String get groupName => 'Gruppenname';

  @override
  String get description => 'Beschreibung';

  @override
  String get members => 'Mitglieder';

  @override
  String get noMembersSelected => 'Keine Mitglieder ausgewählt';

  @override
  String get findUser => 'Benutzer suchen';

  @override
  String get findUserHelper =>
      'Tippe mindestens 3 Zeichen aus Name oder E-Mail.';

  @override
  String get addMember => 'Mitglied hinzufügen';

  @override
  String get noMembers => 'Keine Mitglieder';

  @override
  String get chartsDescription =>
      'Verfolge deine bezahlten, offenen und überfälligen Anteile über sichtbare Belege.';

  @override
  String get loginToViewCharts => 'Anmelden, um Diagramme zu sehen';

  @override
  String get chartDateRange => 'Zeitraum';

  @override
  String get chartAllTime => 'Alle Zeit';

  @override
  String get chartLast30Days => 'Letzte 30 Tage';

  @override
  String get chartLast90Days => 'Letzte 90 Tage';

  @override
  String get chartThisYear => 'Dieses Jahr';

  @override
  String get chartCustom => 'Benutzerdefiniert';

  @override
  String get chartFromDate => 'Von';

  @override
  String get chartToDate => 'Bis';

  @override
  String get chartPickDate => 'Datum wählen';

  @override
  String get chartClearDate => 'Leeren';

  @override
  String get chartDebtBreakdown => 'Schuldenübersicht';

  @override
  String get chartTagBreakdown => 'Tag-Übersicht';

  @override
  String get chartNoData => 'Keine Diagrammdaten für diesen Zeitraum.';

  @override
  String get chartNoTags => 'Keine Tags für diesen Zeitraum verfügbar.';

  @override
  String get chartPaidShare => 'Bezahlter Anteil';

  @override
  String get chartOpenShare => 'Offener Anteil';

  @override
  String get chartOverdueOpenShare => 'Überfälliger offener Anteil';

  @override
  String get chartSelectTags => 'Tags';

  @override
  String chartReceiptsCount(int count) {
    return '$count Belege';
  }

  @override
  String couldNotLoadCharts(Object message) {
    return 'Diagramme konnten nicht geladen werden. $message';
  }
}
