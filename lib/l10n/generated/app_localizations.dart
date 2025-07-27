import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

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
    Locale('en'),
    Locale('si'),
    Locale('ta')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'My Health App'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @affirmation.
  ///
  /// In en, this message translates to:
  /// **'Affirmation'**
  String get affirmation;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @ministryName.
  ///
  /// In en, this message translates to:
  /// **'Ministry of Health'**
  String get ministryName;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @news.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get news;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @emergencyCalled.
  ///
  /// In en, this message translates to:
  /// **'Emergency call made'**
  String get emergencyCalled;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected item'**
  String get selected;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @switchToLightMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Light Mode'**
  String get switchToLightMode;

  /// No description provided for @switchToDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Dark Mode'**
  String get switchToDarkMode;

  /// No description provided for @ourVision.
  ///
  /// In en, this message translates to:
  /// **'Our Vision'**
  String get ourVision;

  /// No description provided for @visionText.
  ///
  /// In en, this message translates to:
  /// **'\"A healthier nation that contributes to its economic, social, mental and spiritual development.\"'**
  String get visionText;

  /// No description provided for @ourMission.
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get ourMission;

  /// No description provided for @missionText.
  ///
  /// In en, this message translates to:
  /// **'\"To contribute to the social and economic development of Sri Lanka by achieving the highest attainable health levels through preventive, curative and rehabilitative services of high quality, available and accessible to people of Sri Lanka.\"'**
  String get missionText;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'READ MORE'**
  String get readMore;

  /// No description provided for @ministryLeadership.
  ///
  /// In en, this message translates to:
  /// **'Ministry Leadership'**
  String get ministryLeadership;

  /// No description provided for @minister.
  ///
  /// In en, this message translates to:
  /// **'Minister of Health and Mass Media'**
  String get minister;

  /// No description provided for @deputyMinister.
  ///
  /// In en, this message translates to:
  /// **'Deputy Minister of Health and Mass Media'**
  String get deputyMinister;

  /// No description provided for @secretary.
  ///
  /// In en, this message translates to:
  /// **'Secretary / Ministry of Health and Mass Media'**
  String get secretary;

  /// No description provided for @directorGeneral.
  ///
  /// In en, this message translates to:
  /// **'Director General of Health Services'**
  String get directorGeneral;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @sinhala.
  ///
  /// In en, this message translates to:
  /// **'Sinhala'**
  String get sinhala;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get tamil;
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
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
