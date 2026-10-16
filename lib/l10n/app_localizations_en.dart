// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Market Mate';

  @override
  String get loginWelcome => 'Welcome to Market Mate';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginEmailRequired => 'Please enter your email';

  @override
  String get loginEmailInvalid => 'Please enter a valid email';

  @override
  String get loginPasswordRequired => 'Please enter your password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get loginNoAccount => 'No account yet? Sign up';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get registerTitle => 'Sign up';

  @override
  String get registerPasswordLabel => 'Password (at least 6 characters)';

  @override
  String get registerButton => 'Create account';

  @override
  String get forgotTitle => 'Forgot password';

  @override
  String get forgotIntro =>
      'Enter your email and we’ll send you a link to reset your password.';

  @override
  String get forgotSent => 'Reset email sent.';

  @override
  String get forgotButton => 'Send link';

  @override
  String get profileSetupTitle => 'Set up your profile';

  @override
  String get profileSetupIntro =>
      'Welcome! How should your friends see you in a team?';

  @override
  String get nameLabel => 'Name';

  @override
  String get chooseAvatar => 'Choose an avatar';

  @override
  String get profileSetupMissing => 'Please enter a name and choose an avatar.';

  @override
  String saveFailed(Object error) {
    return 'Saving failed: $error';
  }

  @override
  String get profileSetupStart => 'Let’s go';

  @override
  String profileLoadFailed(Object error) {
    return 'Your profile could not be loaded.\n$error';
  }

  @override
  String signInFailedWithError(Object error) {
    return 'Sign-in failed.\n$error';
  }

  @override
  String get unknownUser => 'Unknown';

  @override
  String get menuProfile => 'Profile';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuAdmin => 'Admin';

  @override
  String get menuSignOut => 'Sign out';

  @override
  String get navInfo => 'Info';

  @override
  String get navMap => 'Map';

  @override
  String get navTeam => 'Team';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get authErrorInvalidEmail => 'This email address is invalid.';

  @override
  String get authErrorUserDisabled => 'This account has been disabled.';

  @override
  String get authErrorWrongCredentials => 'Email or password is incorrect.';

  @override
  String get authErrorEmailInUse =>
      'There is already an account for this email. Please sign in.';

  @override
  String get authErrorWeakPassword =>
      'The password is too weak – please use at least 6 characters.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please wait a moment.';

  @override
  String get authErrorNetwork => 'No internet connection.';

  @override
  String get authErrorOtherCredential =>
      'There is already an account with a password for this email. Please sign in with it.';

  @override
  String get authErrorFallback => 'Sign-in failed.';

  @override
  String get pageOpenFailed => 'The page could not be opened.';

  @override
  String get locationAllowed => 'Allowed while using the app';

  @override
  String get locationNotYet => 'Not allowed yet';

  @override
  String get locationDenied => 'Not allowed – change it in iOS Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'Same as device';

  @override
  String get languageGerman => 'Deutsch (German)';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsLocation => 'Location';

  @override
  String settingsLocationInfo(Object status) {
    return '$status\nShows where you are on the market map. Your location is not stored.';
  }

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get imprint => 'Imprint';

  @override
  String get settingsAccount => 'Account';

  @override
  String get editProfile => 'Edit profile';

  @override
  String appVersion(Object version) {
    return 'Version $version';
  }

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountText =>
      'Your profile, favourites and team memberships will be deleted. This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteForever => 'Delete forever';

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String get reauthTitle => 'Please sign in again';

  @override
  String get reauthText =>
      'For security reasons you need to sign in again. Then delete the account once more.';

  @override
  String get ok => 'OK';

  @override
  String deleteFailed(Object error) {
    return 'Deleting failed: $error';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get changeAvatar => 'Change avatar';

  @override
  String get save => 'Save';

  @override
  String get signOut => 'Sign out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get catGluehwein => 'Mulled wine & hot drinks';

  @override
  String get catFoodSavory => 'Savoury food';

  @override
  String get catFoodSweet => 'Sweets & pastries';

  @override
  String get catCrafts => 'Crafts & gifts';

  @override
  String get catDecoration => 'Christmas decorations';

  @override
  String get catKids => 'For kids';

  @override
  String get catStage => 'Stage & events';

  @override
  String get catService => 'Services';

  @override
  String get catOther => 'Other';

  @override
  String get postTypeNews => 'News';

  @override
  String get postTypeOpening => 'Opening';

  @override
  String get postTypeTip => 'Tip';

  @override
  String get postTypeEvent => 'Programme';

  @override
  String get favoriteRemove => 'Remove from favourites';

  @override
  String get favoriteAdd => 'Save';

  @override
  String get infoDates => 'Dates';

  @override
  String get infoOpeningHours => 'Opening hours';

  @override
  String get infoEntry => 'Entry';

  @override
  String get infoOrganizer => 'Organiser';

  @override
  String get infoStands => 'Stands';

  @override
  String get infoAbout => 'About the market';

  @override
  String get infoTip => 'Our tip';

  @override
  String joinFailed(Object error) {
    return 'Joining failed: $error';
  }

  @override
  String get toMarketMap => 'Open market map';

  @override
  String get planLoadFailed => 'The site plan could not be loaded.';

  @override
  String get standsLoadFailed => 'The stands could not be loaded.';

  @override
  String get standSearchHint => 'Search stands, e.g. crêpes';

  @override
  String get planHide => 'Hide site plan';

  @override
  String get planShow => 'Show site plan';

  @override
  String get showWholeMarket => 'Show whole market';

  @override
  String standsPullUp(int count) {
    return '$count stands – pull up for the list';
  }

  @override
  String standsFiltered(int visible, int total) {
    return '$visible of $total stands';
  }

  @override
  String get noStandMatches => 'No stand matches your search.';

  @override
  String get retry => 'Try again';

  @override
  String teamLoadFailed(Object error) {
    return 'The team could not be loaded.\n$error';
  }

  @override
  String get teamCreateTitle => 'Start a team';

  @override
  String get teamNameLabel => 'Team name';

  @override
  String get teamNameHint => 'e.g. Mulled Wine Crew';

  @override
  String get teamCreateAction => 'Create';

  @override
  String teamCreateFailed(Object error) {
    return 'The team could not be created: $error';
  }

  @override
  String get teamJoinTitle => 'Join a team';

  @override
  String get teamCodeLabel => 'Team code';

  @override
  String get teamCodeHint => '6 characters, e.g. K7Q2XM';

  @override
  String get teamJoinAction => 'Join';

  @override
  String teamWelcome(Object name) {
    return 'Welcome to team “$name”!';
  }

  @override
  String get teamNotFound => 'No team found with this code.';

  @override
  String get teamOtherMarket => 'This team belongs to another market.';

  @override
  String get teamIntroTitle => 'Explore the market together';

  @override
  String get teamIntroText =>
      'Start a team and share the code with your friends – or join one with a code.';

  @override
  String get teamJoinWithCode => 'Join with code';

  @override
  String get teamLeaveTitle => 'Leave team?';

  @override
  String get teamLeaveLast =>
      'You are the last member – the team will be deleted.';

  @override
  String get teamLeaveRejoin => 'You can rejoin later with the code.';

  @override
  String get teamLeaveAction => 'Leave';

  @override
  String teamLeaveFailed(Object error) {
    return 'Leaving failed: $error';
  }

  @override
  String get teamCopyCode => 'Copy code';

  @override
  String get teamCodeCopied => 'Code copied – send it to your friends.';

  @override
  String teamMembers(int count) {
    return 'Members ($count)';
  }

  @override
  String teamMembersLoadFailed(Object error) {
    return 'Members could not be loaded: $error';
  }

  @override
  String teamMemberYou(Object name) {
    return '$name (you)';
  }

  @override
  String get teamFounder => 'Founder';

  @override
  String get teamShareLocation => 'Share location with the team';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get teamLeave => 'Leave team';

  @override
  String bannerToday(Object label) {
    return 'Today: $label';
  }

  @override
  String bannerTomorrow(Object label) {
    return 'Tomorrow: $label';
  }

  @override
  String bannerMilestoneOn(Object label, DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$label on $dateString';
  }

  @override
  String countdownToday(Object label) {
    return 'Today is $label';
  }

  @override
  String countdownTomorrow(Object label) {
    return 'Tomorrow is $label';
  }

  @override
  String countdownDays(Object label) {
    return 'days until $label';
  }

  @override
  String get statusOver => 'Over';

  @override
  String get statusOpensToday => 'Opens today';

  @override
  String get statusOpensTomorrow => 'Opens tomorrow';

  @override
  String statusOpensInDays(int days) {
    return 'Opens in $days days';
  }

  @override
  String statusFrom(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'From $dateString';
  }

  @override
  String get statusLastDay => 'Last day';

  @override
  String get statusUntilTomorrow => 'Open · until tomorrow';

  @override
  String statusDaysLeft(int days) {
    return 'Open · $days days left';
  }

  @override
  String newsOpensToday(Object name) {
    return '$name opens today';
  }

  @override
  String newsOpensSoon(Object name) {
    return '$name opens soon';
  }

  @override
  String newsLastDays(Object name) {
    return 'Last chance: $name';
  }

  @override
  String newsIsNew(Object name) {
    return 'New in Market Mate: $name';
  }

  @override
  String get relToday => 'today';

  @override
  String get relYesterday => 'yesterday';

  @override
  String relDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get pillFavorite => 'Favourite';

  @override
  String standsCount(int count) {
    return '$count stands';
  }

  @override
  String get toMarket => 'View market';

  @override
  String get readMore => 'Learn more';

  @override
  String get marketsLoadFailed => 'The markets could not be loaded.';

  @override
  String get homeFavorites => 'Your favourites';

  @override
  String get homeNews => 'News';

  @override
  String get noMarkets => 'No markets yet.';

  @override
  String get homeRunning => 'Open now';

  @override
  String get homeUpcoming => 'Coming up';

  @override
  String get homePast => 'Past markets';

  @override
  String get appleSignInFailed =>
      'Sign in with Apple failed. Please try again.';
}
