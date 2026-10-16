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
/// import 'l10n/app_localizations.dart';
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
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Market Mate'**
  String get appTitle;

  /// No description provided for @loginWelcome.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei Market Mate'**
  String get loginWelcome;

  /// No description provided for @emailLabel.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get passwordLabel;

  /// No description provided for @loginEmailRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib deine E-Mail ein'**
  String get loginEmailRequired;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib eine gültige E-Mail ein'**
  String get loginEmailInvalid;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib dein Passwort ein'**
  String get loginPasswordRequired;

  /// No description provided for @loginButton.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get loginButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Konto? Jetzt registrieren'**
  String get loginNoAccount;

  /// No description provided for @loginForgotPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort vergessen?'**
  String get loginForgotPassword;

  /// No description provided for @signInWithApple.
  ///
  /// In de, this message translates to:
  /// **'Mit Apple anmelden'**
  String get signInWithApple;

  /// No description provided for @registerTitle.
  ///
  /// In de, this message translates to:
  /// **'Registrieren'**
  String get registerTitle;

  /// No description provided for @registerPasswordLabel.
  ///
  /// In de, this message translates to:
  /// **'Passwort (mind. 6 Zeichen)'**
  String get registerPasswordLabel;

  /// No description provided for @registerButton.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellen'**
  String get registerButton;

  /// No description provided for @forgotTitle.
  ///
  /// In de, this message translates to:
  /// **'Passwort vergessen'**
  String get forgotTitle;

  /// No description provided for @forgotIntro.
  ///
  /// In de, this message translates to:
  /// **'Gib deine E-Mail ein – wir schicken dir einen Link zum Zurücksetzen.'**
  String get forgotIntro;

  /// No description provided for @forgotSent.
  ///
  /// In de, this message translates to:
  /// **'E-Mail zum Zurücksetzen wurde gesendet.'**
  String get forgotSent;

  /// No description provided for @forgotButton.
  ///
  /// In de, this message translates to:
  /// **'Link senden'**
  String get forgotButton;

  /// No description provided for @profileSetupTitle.
  ///
  /// In de, this message translates to:
  /// **'Profil einrichten'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupIntro.
  ///
  /// In de, this message translates to:
  /// **'Willkommen! Wie sollen dich deine Freunde im Team sehen?'**
  String get profileSetupIntro;

  /// No description provided for @nameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @chooseAvatar.
  ///
  /// In de, this message translates to:
  /// **'Wähle einen Avatar'**
  String get chooseAvatar;

  /// No description provided for @profileSetupMissing.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Namen ein und wähle einen Avatar.'**
  String get profileSetupMissing;

  /// No description provided for @saveFailed.
  ///
  /// In de, this message translates to:
  /// **'Speichern fehlgeschlagen: {error}'**
  String saveFailed(Object error);

  /// No description provided for @profileSetupStart.
  ///
  /// In de, this message translates to:
  /// **'Los geht’s'**
  String get profileSetupStart;

  /// No description provided for @profileLoadFailed.
  ///
  /// In de, this message translates to:
  /// **'Dein Profil konnte nicht geladen werden.\n{error}'**
  String profileLoadFailed(Object error);

  /// No description provided for @signInFailedWithError.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung fehlgeschlagen.\n{error}'**
  String signInFailedWithError(Object error);

  /// No description provided for @unknownUser.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get unknownUser;

  /// No description provided for @menuProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get menuProfile;

  /// No description provided for @menuSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get menuSettings;

  /// No description provided for @menuAdmin.
  ///
  /// In de, this message translates to:
  /// **'Admin'**
  String get menuAdmin;

  /// No description provided for @menuSignOut.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get menuSignOut;

  /// No description provided for @navInfo.
  ///
  /// In de, this message translates to:
  /// **'Infos'**
  String get navInfo;

  /// No description provided for @navMap.
  ///
  /// In de, this message translates to:
  /// **'Karte'**
  String get navMap;

  /// No description provided for @navTeam.
  ///
  /// In de, this message translates to:
  /// **'Team'**
  String get navTeam;

  /// No description provided for @authErrorGeneric.
  ///
  /// In de, this message translates to:
  /// **'Etwas ist schiefgelaufen. Bitte versuche es erneut.'**
  String get authErrorGeneric;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In de, this message translates to:
  /// **'Diese E-Mail-Adresse ist ungültig.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In de, this message translates to:
  /// **'Dieses Konto wurde deaktiviert.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorWrongCredentials.
  ///
  /// In de, this message translates to:
  /// **'E-Mail oder Passwort ist falsch.'**
  String get authErrorWrongCredentials;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In de, this message translates to:
  /// **'Für diese E-Mail gibt es schon ein Konto. Melde dich an.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In de, this message translates to:
  /// **'Das Passwort ist zu schwach – bitte mindestens 6 Zeichen.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Versuche. Bitte warte kurz.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNetwork.
  ///
  /// In de, this message translates to:
  /// **'Keine Internetverbindung.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorOtherCredential.
  ///
  /// In de, this message translates to:
  /// **'Für diese E-Mail gibt es schon ein Konto mit Passwort. Melde dich damit an.'**
  String get authErrorOtherCredential;

  /// No description provided for @authErrorFallback.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung fehlgeschlagen.'**
  String get authErrorFallback;

  /// No description provided for @pageOpenFailed.
  ///
  /// In de, this message translates to:
  /// **'Seite konnte nicht geöffnet werden.'**
  String get pageOpenFailed;

  /// No description provided for @locationAllowed.
  ///
  /// In de, this message translates to:
  /// **'Erlaubt, während die App genutzt wird'**
  String get locationAllowed;

  /// No description provided for @locationNotYet.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht erlaubt'**
  String get locationNotYet;

  /// No description provided for @locationDenied.
  ///
  /// In de, this message translates to:
  /// **'Nicht erlaubt – in den iOS-Einstellungen änderbar'**
  String get locationDenied;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In de, this message translates to:
  /// **'Wie auf dem Gerät'**
  String get languageSystem;

  /// No description provided for @languageGerman.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageEnglish.
  ///
  /// In de, this message translates to:
  /// **'English (Englisch)'**
  String get languageEnglish;

  /// No description provided for @settingsPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get settingsPrivacy;

  /// No description provided for @settingsLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort'**
  String get settingsLocation;

  /// No description provided for @settingsLocationInfo.
  ///
  /// In de, this message translates to:
  /// **'{status}\nZeigt deine Position auf der Marktkarte. Der Standort wird nicht gespeichert.'**
  String settingsLocationInfo(Object status);

  /// No description provided for @privacyPolicy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutzerklärung'**
  String get privacyPolicy;

  /// No description provided for @imprint.
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get imprint;

  /// No description provided for @settingsAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto'**
  String get settingsAccount;

  /// No description provided for @editProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil bearbeiten'**
  String get editProfile;

  /// No description provided for @appVersion.
  ///
  /// In de, this message translates to:
  /// **'Version {version}'**
  String appVersion(Object version);

  /// No description provided for @profileSaved.
  ///
  /// In de, this message translates to:
  /// **'Profil gespeichert.'**
  String get profileSaved;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountText.
  ///
  /// In de, this message translates to:
  /// **'Dein Profil, deine Favoriten und deine Teammitgliedschaften werden gelöscht. Das lässt sich nicht rückgängig machen.'**
  String get deleteAccountText;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @deleteForever.
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get deleteForever;

  /// No description provided for @accountDeleted.
  ///
  /// In de, this message translates to:
  /// **'Dein Konto wurde gelöscht.'**
  String get accountDeleted;

  /// No description provided for @reauthTitle.
  ///
  /// In de, this message translates to:
  /// **'Bitte erneut anmelden'**
  String get reauthTitle;

  /// No description provided for @reauthText.
  ///
  /// In de, this message translates to:
  /// **'Aus Sicherheitsgründen musst du dich kurz neu anmelden. Lösche das Konto danach bitte noch einmal.'**
  String get reauthText;

  /// No description provided for @ok.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @deleteFailed.
  ///
  /// In de, this message translates to:
  /// **'Löschen fehlgeschlagen: {error}'**
  String deleteFailed(Object error);

  /// No description provided for @profileTitle.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @changeAvatar.
  ///
  /// In de, this message translates to:
  /// **'Avatar ändern'**
  String get changeAvatar;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @signOut.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get deleteAccount;

  /// No description provided for @catGluehwein.
  ///
  /// In de, this message translates to:
  /// **'Glühwein & Heißgetränke'**
  String get catGluehwein;

  /// No description provided for @catFoodSavory.
  ///
  /// In de, this message translates to:
  /// **'Herzhaftes'**
  String get catFoodSavory;

  /// No description provided for @catFoodSweet.
  ///
  /// In de, this message translates to:
  /// **'Süßes & Gebäck'**
  String get catFoodSweet;

  /// No description provided for @catCrafts.
  ///
  /// In de, this message translates to:
  /// **'Handwerk & Geschenke'**
  String get catCrafts;

  /// No description provided for @catDecoration.
  ///
  /// In de, this message translates to:
  /// **'Weihnachtsdeko'**
  String get catDecoration;

  /// No description provided for @catKids.
  ///
  /// In de, this message translates to:
  /// **'Für Kinder'**
  String get catKids;

  /// No description provided for @catStage.
  ///
  /// In de, this message translates to:
  /// **'Bühne & Programm'**
  String get catStage;

  /// No description provided for @catService.
  ///
  /// In de, this message translates to:
  /// **'Service'**
  String get catService;

  /// No description provided for @catOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get catOther;

  /// No description provided for @postTypeNews.
  ///
  /// In de, this message translates to:
  /// **'Neuigkeit'**
  String get postTypeNews;

  /// No description provided for @postTypeOpening.
  ///
  /// In de, this message translates to:
  /// **'Eröffnung'**
  String get postTypeOpening;

  /// No description provided for @postTypeTip.
  ///
  /// In de, this message translates to:
  /// **'Tipp'**
  String get postTypeTip;

  /// No description provided for @postTypeEvent.
  ///
  /// In de, this message translates to:
  /// **'Programm'**
  String get postTypeEvent;

  /// No description provided for @favoriteRemove.
  ///
  /// In de, this message translates to:
  /// **'Aus Favoriten entfernen'**
  String get favoriteRemove;

  /// No description provided for @favoriteAdd.
  ///
  /// In de, this message translates to:
  /// **'Merken'**
  String get favoriteAdd;

  /// No description provided for @infoDates.
  ///
  /// In de, this message translates to:
  /// **'Zeitraum'**
  String get infoDates;

  /// No description provided for @infoOpeningHours.
  ///
  /// In de, this message translates to:
  /// **'Öffnungszeiten'**
  String get infoOpeningHours;

  /// No description provided for @infoEntry.
  ///
  /// In de, this message translates to:
  /// **'Eintritt'**
  String get infoEntry;

  /// No description provided for @infoOrganizer.
  ///
  /// In de, this message translates to:
  /// **'Veranstalter'**
  String get infoOrganizer;

  /// No description provided for @infoStands.
  ///
  /// In de, this message translates to:
  /// **'Stände'**
  String get infoStands;

  /// No description provided for @infoAbout.
  ///
  /// In de, this message translates to:
  /// **'Über den Markt'**
  String get infoAbout;

  /// No description provided for @infoTip.
  ///
  /// In de, this message translates to:
  /// **'Unser Tipp'**
  String get infoTip;

  /// No description provided for @joinFailed.
  ///
  /// In de, this message translates to:
  /// **'Beitreten fehlgeschlagen: {error}'**
  String joinFailed(Object error);

  /// No description provided for @toMarketMap.
  ///
  /// In de, this message translates to:
  /// **'Zur Marktkarte'**
  String get toMarketMap;

  /// No description provided for @planLoadFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Lageplan konnte nicht geladen werden.'**
  String get planLoadFailed;

  /// No description provided for @standsLoadFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Stände konnten nicht geladen werden.'**
  String get standsLoadFailed;

  /// No description provided for @standSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Stand suchen, z. B. Crêpes'**
  String get standSearchHint;

  /// No description provided for @planHide.
  ///
  /// In de, this message translates to:
  /// **'Lageplan ausblenden'**
  String get planHide;

  /// No description provided for @planShow.
  ///
  /// In de, this message translates to:
  /// **'Lageplan einblenden'**
  String get planShow;

  /// No description provided for @showWholeMarket.
  ///
  /// In de, this message translates to:
  /// **'Ganzen Markt zeigen'**
  String get showWholeMarket;

  /// No description provided for @standsPullUp.
  ///
  /// In de, this message translates to:
  /// **'{count} Stände – nach oben ziehen für die Liste'**
  String standsPullUp(int count);

  /// No description provided for @standsFiltered.
  ///
  /// In de, this message translates to:
  /// **'{visible} von {total} Ständen'**
  String standsFiltered(int visible, int total);

  /// No description provided for @noStandMatches.
  ///
  /// In de, this message translates to:
  /// **'Kein Stand passt zur Suche.'**
  String get noStandMatches;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get retry;

  /// No description provided for @teamLoadFailed.
  ///
  /// In de, this message translates to:
  /// **'Team konnte nicht geladen werden.\n{error}'**
  String teamLoadFailed(Object error);

  /// No description provided for @teamCreateTitle.
  ///
  /// In de, this message translates to:
  /// **'Team gründen'**
  String get teamCreateTitle;

  /// No description provided for @teamNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Teamname'**
  String get teamNameLabel;

  /// No description provided for @teamNameHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Glühwein-Crew'**
  String get teamNameHint;

  /// No description provided for @teamCreateAction.
  ///
  /// In de, this message translates to:
  /// **'Gründen'**
  String get teamCreateAction;

  /// No description provided for @teamCreateFailed.
  ///
  /// In de, this message translates to:
  /// **'Team konnte nicht gegründet werden: {error}'**
  String teamCreateFailed(Object error);

  /// No description provided for @teamJoinTitle.
  ///
  /// In de, this message translates to:
  /// **'Team beitreten'**
  String get teamJoinTitle;

  /// No description provided for @teamCodeLabel.
  ///
  /// In de, this message translates to:
  /// **'Team-Code'**
  String get teamCodeLabel;

  /// No description provided for @teamCodeHint.
  ///
  /// In de, this message translates to:
  /// **'6 Zeichen, z. B. K7Q2XM'**
  String get teamCodeHint;

  /// No description provided for @teamJoinAction.
  ///
  /// In de, this message translates to:
  /// **'Beitreten'**
  String get teamJoinAction;

  /// No description provided for @teamWelcome.
  ///
  /// In de, this message translates to:
  /// **'Willkommen im Team „{name}“!'**
  String teamWelcome(Object name);

  /// No description provided for @teamNotFound.
  ///
  /// In de, this message translates to:
  /// **'Kein Team mit diesem Code gefunden.'**
  String get teamNotFound;

  /// No description provided for @teamOtherMarket.
  ///
  /// In de, this message translates to:
  /// **'Dieses Team gehört zu einem anderen Markt.'**
  String get teamOtherMarket;

  /// No description provided for @teamIntroTitle.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsam über den Markt'**
  String get teamIntroTitle;

  /// No description provided for @teamIntroText.
  ///
  /// In de, this message translates to:
  /// **'Gründe ein Team und teile den Code mit deinen Freunden – oder tritt mit einem Code bei.'**
  String get teamIntroText;

  /// No description provided for @teamJoinWithCode.
  ///
  /// In de, this message translates to:
  /// **'Mit Code beitreten'**
  String get teamJoinWithCode;

  /// No description provided for @teamLeaveTitle.
  ///
  /// In de, this message translates to:
  /// **'Team verlassen?'**
  String get teamLeaveTitle;

  /// No description provided for @teamLeaveLast.
  ///
  /// In de, this message translates to:
  /// **'Du bist das letzte Mitglied – das Team wird dann gelöscht.'**
  String get teamLeaveLast;

  /// No description provided for @teamLeaveRejoin.
  ///
  /// In de, this message translates to:
  /// **'Du kannst später mit dem Code wieder beitreten.'**
  String get teamLeaveRejoin;

  /// No description provided for @teamLeaveAction.
  ///
  /// In de, this message translates to:
  /// **'Verlassen'**
  String get teamLeaveAction;

  /// No description provided for @teamLeaveFailed.
  ///
  /// In de, this message translates to:
  /// **'Verlassen fehlgeschlagen: {error}'**
  String teamLeaveFailed(Object error);

  /// No description provided for @teamCopyCode.
  ///
  /// In de, this message translates to:
  /// **'Code kopieren'**
  String get teamCopyCode;

  /// No description provided for @teamCodeCopied.
  ///
  /// In de, this message translates to:
  /// **'Code kopiert – schick ihn deinen Freunden.'**
  String get teamCodeCopied;

  /// No description provided for @teamMembers.
  ///
  /// In de, this message translates to:
  /// **'Mitglieder ({count})'**
  String teamMembers(int count);

  /// No description provided for @teamMembersLoadFailed.
  ///
  /// In de, this message translates to:
  /// **'Mitglieder konnten nicht geladen werden: {error}'**
  String teamMembersLoadFailed(Object error);

  /// No description provided for @teamMemberYou.
  ///
  /// In de, this message translates to:
  /// **'{name} (du)'**
  String teamMemberYou(Object name);

  /// No description provided for @teamFounder.
  ///
  /// In de, this message translates to:
  /// **'Gründer'**
  String get teamFounder;

  /// No description provided for @teamShareLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort mit dem Team teilen'**
  String get teamShareLocation;

  /// No description provided for @comingSoon.
  ///
  /// In de, this message translates to:
  /// **'Kommt bald'**
  String get comingSoon;

  /// No description provided for @teamLeave.
  ///
  /// In de, this message translates to:
  /// **'Team verlassen'**
  String get teamLeave;

  /// No description provided for @bannerToday.
  ///
  /// In de, this message translates to:
  /// **'Heute: {label}'**
  String bannerToday(Object label);

  /// No description provided for @bannerTomorrow.
  ///
  /// In de, this message translates to:
  /// **'Morgen: {label}'**
  String bannerTomorrow(Object label);

  /// No description provided for @bannerMilestoneOn.
  ///
  /// In de, this message translates to:
  /// **'{label} am {date}'**
  String bannerMilestoneOn(Object label, DateTime date);

  /// No description provided for @countdownToday.
  ///
  /// In de, this message translates to:
  /// **'Heute ist {label}'**
  String countdownToday(Object label);

  /// No description provided for @countdownTomorrow.
  ///
  /// In de, this message translates to:
  /// **'Morgen ist {label}'**
  String countdownTomorrow(Object label);

  /// No description provided for @countdownDays.
  ///
  /// In de, this message translates to:
  /// **'Tage bis {label}'**
  String countdownDays(Object label);

  /// No description provided for @statusOver.
  ///
  /// In de, this message translates to:
  /// **'Vorbei'**
  String get statusOver;

  /// No description provided for @statusOpensToday.
  ///
  /// In de, this message translates to:
  /// **'Öffnet heute'**
  String get statusOpensToday;

  /// No description provided for @statusOpensTomorrow.
  ///
  /// In de, this message translates to:
  /// **'Öffnet morgen'**
  String get statusOpensTomorrow;

  /// No description provided for @statusOpensInDays.
  ///
  /// In de, this message translates to:
  /// **'Öffnet in {days} Tagen'**
  String statusOpensInDays(int days);

  /// No description provided for @statusFrom.
  ///
  /// In de, this message translates to:
  /// **'Ab {date}'**
  String statusFrom(DateTime date);

  /// No description provided for @statusLastDay.
  ///
  /// In de, this message translates to:
  /// **'Letzter Tag'**
  String get statusLastDay;

  /// No description provided for @statusUntilTomorrow.
  ///
  /// In de, this message translates to:
  /// **'Läuft · noch bis morgen'**
  String get statusUntilTomorrow;

  /// No description provided for @statusDaysLeft.
  ///
  /// In de, this message translates to:
  /// **'Läuft · noch {days} Tage'**
  String statusDaysLeft(int days);

  /// No description provided for @newsOpensToday.
  ///
  /// In de, this message translates to:
  /// **'{name} öffnet heute'**
  String newsOpensToday(Object name);

  /// No description provided for @newsOpensSoon.
  ///
  /// In de, this message translates to:
  /// **'{name} öffnet bald'**
  String newsOpensSoon(Object name);

  /// No description provided for @newsLastDays.
  ///
  /// In de, this message translates to:
  /// **'Letzte Chance: {name}'**
  String newsLastDays(Object name);

  /// No description provided for @newsIsNew.
  ///
  /// In de, this message translates to:
  /// **'Neu in Market Mate: {name}'**
  String newsIsNew(Object name);

  /// No description provided for @relToday.
  ///
  /// In de, this message translates to:
  /// **'heute'**
  String get relToday;

  /// No description provided for @relYesterday.
  ///
  /// In de, this message translates to:
  /// **'gestern'**
  String get relYesterday;

  /// No description provided for @relDaysAgo.
  ///
  /// In de, this message translates to:
  /// **'vor {days} Tagen'**
  String relDaysAgo(int days);

  /// No description provided for @pillFavorite.
  ///
  /// In de, this message translates to:
  /// **'Favorit'**
  String get pillFavorite;

  /// No description provided for @standsCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Stände'**
  String standsCount(int count);

  /// No description provided for @toMarket.
  ///
  /// In de, this message translates to:
  /// **'Zum Markt'**
  String get toMarket;

  /// No description provided for @readMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr erfahren'**
  String get readMore;

  /// No description provided for @marketsLoadFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Märkte konnten nicht geladen werden.'**
  String get marketsLoadFailed;

  /// No description provided for @homeFavorites.
  ///
  /// In de, this message translates to:
  /// **'Deine Favoriten'**
  String get homeFavorites;

  /// No description provided for @homeNews.
  ///
  /// In de, this message translates to:
  /// **'Neuigkeiten'**
  String get homeNews;

  /// No description provided for @noMarkets.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Märkte vorhanden.'**
  String get noMarkets;

  /// No description provided for @homeRunning.
  ///
  /// In de, this message translates to:
  /// **'Läuft gerade'**
  String get homeRunning;

  /// No description provided for @homeUpcoming.
  ///
  /// In de, this message translates to:
  /// **'Demnächst'**
  String get homeUpcoming;

  /// No description provided for @homePast.
  ///
  /// In de, this message translates to:
  /// **'Vergangene Märkte'**
  String get homePast;

  /// No description provided for @appleSignInFailed.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung mit Apple fehlgeschlagen. Bitte versuche es erneut.'**
  String get appleSignInFailed;
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
      'that was used.');
}
