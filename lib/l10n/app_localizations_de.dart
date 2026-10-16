// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Market Mate';

  @override
  String get loginWelcome => 'Willkommen bei Market Mate';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get loginEmailRequired => 'Bitte gib deine E-Mail ein';

  @override
  String get loginEmailInvalid => 'Bitte gib eine gültige E-Mail ein';

  @override
  String get loginPasswordRequired => 'Bitte gib dein Passwort ein';

  @override
  String get loginButton => 'Anmelden';

  @override
  String get loginNoAccount => 'Noch kein Konto? Jetzt registrieren';

  @override
  String get loginForgotPassword => 'Passwort vergessen?';

  @override
  String get signInWithApple => 'Mit Apple anmelden';

  @override
  String get registerTitle => 'Registrieren';

  @override
  String get registerPasswordLabel => 'Passwort (mind. 6 Zeichen)';

  @override
  String get registerButton => 'Konto erstellen';

  @override
  String get forgotTitle => 'Passwort vergessen';

  @override
  String get forgotIntro =>
      'Gib deine E-Mail ein – wir schicken dir einen Link zum Zurücksetzen.';

  @override
  String get forgotSent => 'E-Mail zum Zurücksetzen wurde gesendet.';

  @override
  String get forgotButton => 'Link senden';

  @override
  String get profileSetupTitle => 'Profil einrichten';

  @override
  String get profileSetupIntro =>
      'Willkommen! Wie sollen dich deine Freunde im Team sehen?';

  @override
  String get nameLabel => 'Name';

  @override
  String get chooseAvatar => 'Wähle einen Avatar';

  @override
  String get profileSetupMissing =>
      'Bitte gib einen Namen ein und wähle einen Avatar.';

  @override
  String saveFailed(Object error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String get profileSetupStart => 'Los geht’s';

  @override
  String profileLoadFailed(Object error) {
    return 'Dein Profil konnte nicht geladen werden.\n$error';
  }

  @override
  String signInFailedWithError(Object error) {
    return 'Anmeldung fehlgeschlagen.\n$error';
  }

  @override
  String get unknownUser => 'Unbekannt';

  @override
  String get menuProfile => 'Profil';

  @override
  String get menuSettings => 'Einstellungen';

  @override
  String get menuAdmin => 'Admin';

  @override
  String get menuSignOut => 'Abmelden';

  @override
  String get navInfo => 'Infos';

  @override
  String get navMap => 'Karte';

  @override
  String get navTeam => 'Team';

  @override
  String get authErrorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get authErrorInvalidEmail => 'Diese E-Mail-Adresse ist ungültig.';

  @override
  String get authErrorUserDisabled => 'Dieses Konto wurde deaktiviert.';

  @override
  String get authErrorWrongCredentials => 'E-Mail oder Passwort ist falsch.';

  @override
  String get authErrorEmailInUse =>
      'Für diese E-Mail gibt es schon ein Konto. Melde dich an.';

  @override
  String get authErrorWeakPassword =>
      'Das Passwort ist zu schwach – bitte mindestens 6 Zeichen.';

  @override
  String get authErrorTooManyRequests => 'Zu viele Versuche. Bitte warte kurz.';

  @override
  String get authErrorNetwork => 'Keine Internetverbindung.';

  @override
  String get authErrorOtherCredential =>
      'Für diese E-Mail gibt es schon ein Konto mit Passwort. Melde dich damit an.';

  @override
  String get authErrorFallback => 'Anmeldung fehlgeschlagen.';

  @override
  String get pageOpenFailed => 'Seite konnte nicht geöffnet werden.';

  @override
  String get locationAllowed => 'Erlaubt, während die App genutzt wird';

  @override
  String get locationNotYet => 'Noch nicht erlaubt';

  @override
  String get locationDenied =>
      'Nicht erlaubt – in den iOS-Einstellungen änderbar';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get languageSystem => 'Wie auf dem Gerät';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English (Englisch)';

  @override
  String get settingsPrivacy => 'Datenschutz';

  @override
  String get settingsLocation => 'Standort';

  @override
  String settingsLocationInfo(Object status) {
    return '$status\nZeigt deine Position auf der Marktkarte. Der Standort wird nicht gespeichert.';
  }

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get imprint => 'Impressum';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String appVersion(Object version) {
    return 'Version $version';
  }

  @override
  String get profileSaved => 'Profil gespeichert.';

  @override
  String get deleteAccountTitle => 'Konto löschen?';

  @override
  String get deleteAccountText =>
      'Dein Profil, deine Favoriten und deine Teammitgliedschaften werden gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get deleteForever => 'Endgültig löschen';

  @override
  String get accountDeleted => 'Dein Konto wurde gelöscht.';

  @override
  String get reauthTitle => 'Bitte erneut anmelden';

  @override
  String get reauthText =>
      'Aus Sicherheitsgründen musst du dich kurz neu anmelden. Lösche das Konto danach bitte noch einmal.';

  @override
  String get ok => 'OK';

  @override
  String deleteFailed(Object error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get profileTitle => 'Profil';

  @override
  String get changeAvatar => 'Avatar ändern';

  @override
  String get save => 'Speichern';

  @override
  String get signOut => 'Abmelden';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get catGluehwein => 'Glühwein & Heißgetränke';

  @override
  String get catFoodSavory => 'Herzhaftes';

  @override
  String get catFoodSweet => 'Süßes & Gebäck';

  @override
  String get catCrafts => 'Handwerk & Geschenke';

  @override
  String get catDecoration => 'Weihnachtsdeko';

  @override
  String get catKids => 'Für Kinder';

  @override
  String get catStage => 'Bühne & Programm';

  @override
  String get catService => 'Service';

  @override
  String get catOther => 'Sonstiges';

  @override
  String get postTypeNews => 'Neuigkeit';

  @override
  String get postTypeOpening => 'Eröffnung';

  @override
  String get postTypeTip => 'Tipp';

  @override
  String get postTypeEvent => 'Programm';

  @override
  String get favoriteRemove => 'Aus Favoriten entfernen';

  @override
  String get favoriteAdd => 'Merken';

  @override
  String get infoDates => 'Zeitraum';

  @override
  String get infoOpeningHours => 'Öffnungszeiten';

  @override
  String get infoEntry => 'Eintritt';

  @override
  String get infoOrganizer => 'Veranstalter';

  @override
  String get infoStands => 'Stände';

  @override
  String get infoAbout => 'Über den Markt';

  @override
  String get infoTip => 'Unser Tipp';

  @override
  String joinFailed(Object error) {
    return 'Beitreten fehlgeschlagen: $error';
  }

  @override
  String get toMarketMap => 'Zur Marktkarte';

  @override
  String get planLoadFailed => 'Der Lageplan konnte nicht geladen werden.';

  @override
  String get standsLoadFailed => 'Die Stände konnten nicht geladen werden.';

  @override
  String get standSearchHint => 'Stand suchen, z. B. Crêpes';

  @override
  String get planHide => 'Lageplan ausblenden';

  @override
  String get planShow => 'Lageplan einblenden';

  @override
  String get showWholeMarket => 'Ganzen Markt zeigen';

  @override
  String standsPullUp(int count) {
    return '$count Stände – nach oben ziehen für die Liste';
  }

  @override
  String standsFiltered(int visible, int total) {
    return '$visible von $total Ständen';
  }

  @override
  String get noStandMatches => 'Kein Stand passt zur Suche.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String teamLoadFailed(Object error) {
    return 'Team konnte nicht geladen werden.\n$error';
  }

  @override
  String get teamCreateTitle => 'Team gründen';

  @override
  String get teamNameLabel => 'Teamname';

  @override
  String get teamNameHint => 'z. B. Glühwein-Crew';

  @override
  String get teamCreateAction => 'Gründen';

  @override
  String teamCreateFailed(Object error) {
    return 'Team konnte nicht gegründet werden: $error';
  }

  @override
  String get teamJoinTitle => 'Team beitreten';

  @override
  String get teamCodeLabel => 'Team-Code';

  @override
  String get teamCodeHint => '6 Zeichen, z. B. K7Q2XM';

  @override
  String get teamJoinAction => 'Beitreten';

  @override
  String teamWelcome(Object name) {
    return 'Willkommen im Team „$name“!';
  }

  @override
  String get teamNotFound => 'Kein Team mit diesem Code gefunden.';

  @override
  String get teamOtherMarket => 'Dieses Team gehört zu einem anderen Markt.';

  @override
  String get teamIntroTitle => 'Gemeinsam über den Markt';

  @override
  String get teamIntroText =>
      'Gründe ein Team und teile den Code mit deinen Freunden – oder tritt mit einem Code bei.';

  @override
  String get teamJoinWithCode => 'Mit Code beitreten';

  @override
  String get teamLeaveTitle => 'Team verlassen?';

  @override
  String get teamLeaveLast =>
      'Du bist das letzte Mitglied – das Team wird dann gelöscht.';

  @override
  String get teamLeaveRejoin =>
      'Du kannst später mit dem Code wieder beitreten.';

  @override
  String get teamLeaveAction => 'Verlassen';

  @override
  String teamLeaveFailed(Object error) {
    return 'Verlassen fehlgeschlagen: $error';
  }

  @override
  String get teamCopyCode => 'Code kopieren';

  @override
  String get teamCodeCopied => 'Code kopiert – schick ihn deinen Freunden.';

  @override
  String teamMembers(int count) {
    return 'Mitglieder ($count)';
  }

  @override
  String teamMembersLoadFailed(Object error) {
    return 'Mitglieder konnten nicht geladen werden: $error';
  }

  @override
  String teamMemberYou(Object name) {
    return '$name (du)';
  }

  @override
  String get teamFounder => 'Gründer';

  @override
  String get teamShareLocation => 'Standort mit dem Team teilen';

  @override
  String get comingSoon => 'Kommt bald';

  @override
  String get teamLeave => 'Team verlassen';

  @override
  String bannerToday(Object label) {
    return 'Heute: $label';
  }

  @override
  String bannerTomorrow(Object label) {
    return 'Morgen: $label';
  }

  @override
  String bannerMilestoneOn(Object label, DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$label am $dateString';
  }

  @override
  String countdownToday(Object label) {
    return 'Heute ist $label';
  }

  @override
  String countdownTomorrow(Object label) {
    return 'Morgen ist $label';
  }

  @override
  String countdownDays(Object label) {
    return 'Tage bis $label';
  }

  @override
  String get statusOver => 'Vorbei';

  @override
  String get statusOpensToday => 'Öffnet heute';

  @override
  String get statusOpensTomorrow => 'Öffnet morgen';

  @override
  String statusOpensInDays(int days) {
    return 'Öffnet in $days Tagen';
  }

  @override
  String statusFrom(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Ab $dateString';
  }

  @override
  String get statusLastDay => 'Letzter Tag';

  @override
  String get statusUntilTomorrow => 'Läuft · noch bis morgen';

  @override
  String statusDaysLeft(int days) {
    return 'Läuft · noch $days Tage';
  }

  @override
  String newsOpensToday(Object name) {
    return '$name öffnet heute';
  }

  @override
  String newsOpensSoon(Object name) {
    return '$name öffnet bald';
  }

  @override
  String newsLastDays(Object name) {
    return 'Letzte Chance: $name';
  }

  @override
  String newsIsNew(Object name) {
    return 'Neu in Market Mate: $name';
  }

  @override
  String get relToday => 'heute';

  @override
  String get relYesterday => 'gestern';

  @override
  String relDaysAgo(int days) {
    return 'vor $days Tagen';
  }

  @override
  String get pillFavorite => 'Favorit';

  @override
  String standsCount(int count) {
    return '$count Stände';
  }

  @override
  String get toMarket => 'Zum Markt';

  @override
  String get readMore => 'Mehr erfahren';

  @override
  String get marketsLoadFailed => 'Die Märkte konnten nicht geladen werden.';

  @override
  String get homeFavorites => 'Deine Favoriten';

  @override
  String get homeNews => 'Neuigkeiten';

  @override
  String get noMarkets => 'Noch keine Märkte vorhanden.';

  @override
  String get homeRunning => 'Läuft gerade';

  @override
  String get homeUpcoming => 'Demnächst';

  @override
  String get homePast => 'Vergangene Märkte';

  @override
  String get appleSignInFailed =>
      'Anmeldung mit Apple fehlgeschlagen. Bitte versuche es erneut.';
}
