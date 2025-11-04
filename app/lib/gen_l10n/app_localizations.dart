import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('sv'),
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @verifyPassword.
  ///
  /// In en, this message translates to:
  /// **'Verify password'**
  String get verifyPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @quarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get quarter;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @last.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get last;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? You cannot undo and your data will disappear after you delete your account.'**
  String get deleteAccountConfirmation;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

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

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @side.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get side;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get genericError;

  /// No description provided for @connectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout, could not connect to the server.'**
  String get connectionTimeout;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error, are you connected to the internet?'**
  String get connectionError;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this?'**
  String get removeConfirmation;

  /// No description provided for @goodWork.
  ///
  /// In en, this message translates to:
  /// **'Good work!'**
  String get goodWork;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @pickANumber.
  ///
  /// In en, this message translates to:
  /// **'Pick a number'**
  String get pickANumber;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @pushPermissionsErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'You need to turn on notifications in your phone\'s app settings.'**
  String get pushPermissionsErrorMessage;

  /// No description provided for @watchSettings.
  ///
  /// In en, this message translates to:
  /// **'Watch settings'**
  String get watchSettings;

  /// No description provided for @paraplegic.
  ///
  /// In en, this message translates to:
  /// **'Paraplegic'**
  String get paraplegic;

  /// No description provided for @tetraplegic.
  ///
  /// In en, this message translates to:
  /// **'Tetraplegic'**
  String get tetraplegic;

  /// No description provided for @sedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get sedentary;

  /// No description provided for @movement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get movement;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @weights.
  ///
  /// In en, this message translates to:
  /// **'Weights'**
  String get weights;

  /// No description provided for @skiErgo.
  ///
  /// In en, this message translates to:
  /// **'Ski ergometer'**
  String get skiErgo;

  /// No description provided for @armErgo.
  ///
  /// In en, this message translates to:
  /// **'Arm cycle'**
  String get armErgo;

  /// No description provided for @rollOutside.
  ///
  /// In en, this message translates to:
  /// **'Roll outside exercise ( or other )'**
  String get rollOutside;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @injury.
  ///
  /// In en, this message translates to:
  /// **'Injury'**
  String get injury;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @bodyPart.
  ///
  /// In en, this message translates to:
  /// **'Body part'**
  String get bodyPart;

  /// No description provided for @bodyPartNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get bodyPartNeck;

  /// No description provided for @bodyPartBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get bodyPartBack;

  /// No description provided for @bodyPartScapula.
  ///
  /// In en, this message translates to:
  /// **'Scapula'**
  String get bodyPartScapula;

  /// No description provided for @bodyPartShoulderJoint.
  ///
  /// In en, this message translates to:
  /// **'Shoulder joint'**
  String get bodyPartShoulderJoint;

  /// No description provided for @bodyPartElbow.
  ///
  /// In en, this message translates to:
  /// **'Elbow'**
  String get bodyPartElbow;

  /// No description provided for @bodyPartHand.
  ///
  /// In en, this message translates to:
  /// **'Hand'**
  String get bodyPartHand;

  /// No description provided for @arm.
  ///
  /// In en, this message translates to:
  /// **'Arm'**
  String get arm;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @injuryLevel.
  ///
  /// In en, this message translates to:
  /// **'Injury level'**
  String get injuryLevel;

  /// No description provided for @gear.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get gear;

  /// No description provided for @medicin.
  ///
  /// In en, this message translates to:
  /// **'Medicin'**
  String get medicin;

  /// No description provided for @introductionScreenHeader.
  ///
  /// In en, this message translates to:
  /// **'Track your movement'**
  String get introductionScreenHeader;

  /// No description provided for @introductionWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Wheelability app!'**
  String get introductionWelcome;

  /// No description provided for @registerDataTitle.
  ///
  /// In en, this message translates to:
  /// **'How the app uses your data'**
  String get registerDataTitle;

  /// No description provided for @registerDataDescription.
  ///
  /// In en, this message translates to:
  /// **'There is no automatic collection of data in the app. Everything that is logged is what you do yourself through the \"Logbook\" and the shortcuts on the home screen. All data is visible in your Logbook.'**
  String get registerDataDescription;

  /// No description provided for @registerDataDeletion.
  ///
  /// In en, this message translates to:
  /// **'If you choose to delete your account, all data linked to the account will also disappear.'**
  String get registerDataDeletion;

  /// No description provided for @registerProceed.
  ///
  /// In en, this message translates to:
  /// **'Do you want to continue?'**
  String get registerProceed;

  /// No description provided for @intro.
  ///
  /// In en, this message translates to:
  /// **'Intro'**
  String get intro;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Wheelability'**
  String get onboardingTitle;

  /// No description provided for @onboardingIntro.
  ///
  /// In en, this message translates to:
  /// **'Hello and welcome to Wheelability, this guide will show you what features are available.\n\nYou can choose whether you are interested in using them or not, if you deselect a feature it will not appear on the home screen. You can always undo this by redoing this from the settings in the app.\n\n Press \"Next\" to continue.'**
  String get onboardingIntro;

  /// No description provided for @watchFunctions.
  ///
  /// In en, this message translates to:
  /// **'Watch functions'**
  String get watchFunctions;

  /// No description provided for @onboardingWantFunctions.
  ///
  /// In en, this message translates to:
  /// **'I want these features'**
  String get onboardingWantFunctions;

  /// No description provided for @onboardingWatchRequirement.
  ///
  /// In en, this message translates to:
  /// **'* You need a Fitbit ( Versa 2/3 or Sense 1/2 )'**
  String get onboardingWatchRequirement;

  /// No description provided for @onboardingNotInterested.
  ///
  /// In en, this message translates to:
  /// **'Not interested'**
  String get onboardingNotInterested;

  /// No description provided for @onboardingDontHaveWatch.
  ///
  /// In en, this message translates to:
  /// **'I don\'t have the watch'**
  String get onboardingDontHaveWatch;

  /// No description provided for @onboardingCaloriesDescription.
  ///
  /// In en, this message translates to:
  /// **'An estimate of your daily energy consumption (calories) is shown here. You can also compare with an average day during the last week.'**
  String get onboardingCaloriesDescription;

  /// No description provided for @onboardingSedentaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you get information on how long you sit still in total during a day, how often you break up your sedentary life and how long you sit still before you are active.'**
  String get onboardingSedentaryDescription;

  /// No description provided for @onboardingMovementDescription.
  ///
  /// In en, this message translates to:
  /// **'This shows how long and when you are physically active, described as low, medium and high intensity'**
  String get onboardingMovementDescription;

  /// No description provided for @onboardingPressureReleaseAndUlcerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pressure ulcers & relief'**
  String get onboardingPressureReleaseAndUlcerTitle;

  /// No description provided for @onboardingPressureReleaseDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you get information about how often you have pressure relief and how long you sat still between your pressure reliefs. You can also set how many times during the day you should be reminded.'**
  String get onboardingPressureReleaseDescription;

  /// No description provided for @onboaridngPressureUlcerDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can record the location, degree and photograph the spread of the pressure ulcer to be able to follow the development of your pressure ulcer.'**
  String get onboaridngPressureUlcerDescription;

  /// No description provided for @onboardingPainFeature.
  ///
  /// In en, this message translates to:
  /// **'Log your pain'**
  String get onboardingPainFeature;

  /// No description provided for @onboardingPainDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can register where you have pain and what level of pain you have today.'**
  String get onboardingPainDescription;

  /// No description provided for @onboardingNeuropathicPainDescription.
  ///
  /// In en, this message translates to:
  /// **'Set your level for pain at/under injury, intermittent pain or allodynia.'**
  String get onboardingNeuropathicPainDescription;

  /// No description provided for @onboardingSpasticityDescription.
  ///
  /// In en, this message translates to:
  /// **'Set your spasticity level.'**
  String get onboardingSpasticityDescription;

  /// No description provided for @onboardingPushDescription.
  ///
  /// In en, this message translates to:
  /// **'In order to receive reminders or recommendations through push notifications, you need to give your approval for the app to send you push notifications.'**
  String get onboardingPushDescription;

  /// No description provided for @onboardingActivatePush.
  ///
  /// In en, this message translates to:
  /// **'Enable push notifications'**
  String get onboardingActivatePush;

  /// No description provided for @onboardingSettingsInfo.
  ///
  /// In en, this message translates to:
  /// **'You can change your settings in the app at any time.'**
  String get onboardingSettingsInfo;

  /// No description provided for @onboardingBladderAndBowelFunctions.
  ///
  /// In en, this message translates to:
  /// **'Bladder & Bowel'**
  String get onboardingBladderAndBowelFunctions;

  /// No description provided for @onboardingUtiDescription.
  ///
  /// In en, this message translates to:
  /// **'Record whether or not you have a urinary tract infection.'**
  String get onboardingUtiDescription;

  /// No description provided for @onboardingBladderEmptyingDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can record how often you empty your bladder and get reminders when it\'s time to empty your bladder.'**
  String get onboardingBladderEmptyingDescription;

  /// No description provided for @onboardingLeakageDescription.
  ///
  /// In en, this message translates to:
  /// **'Register when you have a leak.'**
  String get onboardingLeakageDescription;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get appSettings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @enableDisableFeatures.
  ///
  /// In en, this message translates to:
  /// **'Enable/disable features'**
  String get enableDisableFeatures;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @redoIntro.
  ///
  /// In en, this message translates to:
  /// **'Redo introduction'**
  String get redoIntro;

  /// No description provided for @showLicenses.
  ///
  /// In en, this message translates to:
  /// **'Show licenses'**
  String get showLicenses;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'UserID'**
  String get userId;

  /// No description provided for @userIdCopyMessage.
  ///
  /// In en, this message translates to:
  /// **'UserID copied to clipboard'**
  String get userIdCopyMessage;

  /// No description provided for @movementReminders.
  ///
  /// In en, this message translates to:
  /// **'Movement reminders'**
  String get movementReminders;

  /// No description provided for @logbookReminders.
  ///
  /// In en, this message translates to:
  /// **'Logbook reminders'**
  String get logbookReminders;

  /// No description provided for @noDataWarning.
  ///
  /// In en, this message translates to:
  /// **'No data warning'**
  String get noDataWarning;

  /// No description provided for @aboutCalories.
  ///
  /// In en, this message translates to:
  /// **'An estimate of your daily energy consumption (calories) is shown here, which is done by the activity bracelet (watch) recording the movement from the accelerometer and the heart rate continuously. The information from the activity bracelet as well as information on injury level, gender and body weight is used to calculate energy consumption and activity level (intensity).'**
  String get aboutCalories;

  /// No description provided for @aboutSedentary.
  ///
  /// In en, this message translates to:
  /// **'Here is an estimate of the total time - distributed over the day - you sit still and work, watch TV, read or eat.'**
  String get aboutSedentary;

  /// No description provided for @aboutMovement.
  ///
  /// In en, this message translates to:
  /// **'An estimate of your daily activity is shown here. Movement (low-intensity activity, blue). Consists of activities that are perceived as light effort and can be described as 20 - 45% of an individual\'s maximum capacity.\nActivity (Medium to high intensity activity, green). Consists of activities perceived as somewhat strenuous to strenuous and very strenuous. These can be described as medium 46 - 63% and high 54 - 90% of maximum intensity.\n\nThe activity level is based on percentage (%) of maximum capacity (relative intensity), this means that the same activity can be perceived as exerting differently by different individuals.'**
  String get aboutMovement;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateAndTime;

  /// No description provided for @journalNoData.
  ///
  /// In en, this message translates to:
  /// **'You have no data for this period'**
  String get journalNoData;

  /// No description provided for @journalWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Logbook'**
  String get journalWelcome;

  /// No description provided for @journalWelcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can get an overview of what you have logged and create new entries, press the button below to get started.'**
  String get journalWelcomeDescription;

  /// No description provided for @logbook.
  ///
  /// In en, this message translates to:
  /// **'Logbook'**
  String get logbook;

  /// No description provided for @listEntries.
  ///
  /// In en, this message translates to:
  /// **'List entries'**
  String get listEntries;

  /// No description provided for @listEntriesDescription.
  ///
  /// In en, this message translates to:
  /// **'View/edit your entries.'**
  String get listEntriesDescription;

  /// No description provided for @addBodyPart.
  ///
  /// In en, this message translates to:
  /// **'Add body part'**
  String get addBodyPart;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get newEntry;

  /// No description provided for @journalCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to log?'**
  String get journalCategoriesTitle;

  /// No description provided for @journalCategoriesDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose one of the categories you see below'**
  String get journalCategoriesDescription;

  /// No description provided for @journalShortcutDescription.
  ///
  /// In en, this message translates to:
  /// **'Press a button below to create a new post within the same category.'**
  String get journalShortcutDescription;

  /// No description provided for @pain.
  ///
  /// In en, this message translates to:
  /// **'Pain'**
  String get pain;

  /// No description provided for @painAndDiscomfort.
  ///
  /// In en, this message translates to:
  /// **'Pain & discomfort'**
  String get painAndDiscomfort;

  /// No description provided for @painAndDiscormfortEmpty.
  ///
  /// In en, this message translates to:
  /// **'Log neuropathic pain or spasticity to see it here.'**
  String get painAndDiscormfortEmpty;

  /// No description provided for @painAndDiscormfortEmptyButton.
  ///
  /// In en, this message translates to:
  /// **'Go to logbook'**
  String get painAndDiscormfortEmptyButton;

  /// No description provided for @neuropathic.
  ///
  /// In en, this message translates to:
  /// **'Neuropathic'**
  String get neuropathic;

  /// No description provided for @neuropathicPain.
  ///
  /// In en, this message translates to:
  /// **'Neuropathic pain'**
  String get neuropathicPain;

  /// No description provided for @typeOfPain.
  ///
  /// In en, this message translates to:
  /// **'Type of pain'**
  String get typeOfPain;

  /// No description provided for @belowOrAt.
  ///
  /// In en, this message translates to:
  /// **'Pain ( below / at )'**
  String get belowOrAt;

  /// No description provided for @intermittent.
  ///
  /// In en, this message translates to:
  /// **'Intermittent'**
  String get intermittent;

  /// No description provided for @allodynia.
  ///
  /// In en, this message translates to:
  /// **'Allodynia'**
  String get allodynia;

  /// No description provided for @musclePainTitle.
  ///
  /// In en, this message translates to:
  /// **'Pain in muscles and joints'**
  String get musclePainTitle;

  /// No description provided for @musclePainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From muscle and joints'**
  String get musclePainSubtitle;

  /// No description provided for @trackPain.
  ///
  /// In en, this message translates to:
  /// **'Track pain'**
  String get trackPain;

  /// No description provided for @trackPainDescription.
  ///
  /// In en, this message translates to:
  /// **'Press a bodyPart to add a new pain entry.'**
  String get trackPainDescription;

  /// No description provided for @trackPainEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a body part to start tracking your pain.'**
  String get trackPainEmpty;

  /// No description provided for @painLevel.
  ///
  /// In en, this message translates to:
  /// **'Pain level'**
  String get painLevel;

  /// No description provided for @painLevelHelper.
  ///
  /// In en, this message translates to:
  /// **'Choose a number between 1-10'**
  String get painLevelHelper;

  /// No description provided for @painCommentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get painCommentPlaceholder;

  /// No description provided for @painCommentHelper.
  ///
  /// In en, this message translates to:
  /// **'Describe how you feel, what you have done, how you have slept, etc.'**
  String get painCommentHelper;

  /// No description provided for @exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exercise;

  /// No description provided for @newExercise.
  ///
  /// In en, this message translates to:
  /// **'New exercise'**
  String get newExercise;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @exerciseActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'What kind of activity did you do?'**
  String get exerciseActivityDescription;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @exerciseLengthDescription.
  ///
  /// In en, this message translates to:
  /// **'For how long did you exercise?'**
  String get exerciseLengthDescription;

  /// No description provided for @selfAssessedPhysicalActivity.
  ///
  /// In en, this message translates to:
  /// **'Self-assessed physical activity'**
  String get selfAssessedPhysicalActivity;

  /// No description provided for @selfAssessedPhysicalActivityTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Physical training'**
  String get selfAssessedPhysicalActivityTrainingTitle;

  /// No description provided for @selfAssessedPhysicalActivityTrainingDescription.
  ///
  /// In en, this message translates to:
  /// **'How much time do you spend in a typical week on physical training that makes you out of breath, for example rolling outdoors, ball sports, exercise classes, cycling or similar.\n\nRemember to count every day of the week and that this is about physical training where you should get out of breath. The next page contains questions about everyday physical activity.'**
  String get selfAssessedPhysicalActivityTrainingDescription;

  /// No description provided for @selfAssessedPhysicalActivityEverydayTitle.
  ///
  /// In en, this message translates to:
  /// **'Everyday physical activity'**
  String get selfAssessedPhysicalActivityEverydayTitle;

  /// No description provided for @selfAssessedPhysicalActivityEverydayDescription.
  ///
  /// In en, this message translates to:
  /// **'How much time do you spend in a typical week on everyday physical activity, for example rolling outdoors (walks), household chores, gardening, shopping or similar.'**
  String get selfAssessedPhysicalActivityEverydayDescription;

  /// No description provided for @selfAssessedPhysicalActivitySedentaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Sedentary time'**
  String get selfAssessedPhysicalActivitySedentaryTitle;

  /// No description provided for @selfAssessedPhysicalActivitySedentaryDescription.
  ///
  /// In en, this message translates to:
  /// **'How much time do you spend sitting still during a day, for example watching TV, sitting at a computer, reading or similar, excluding sleep.\n\nBecause this question is based on time per day, the number will be multiplied by seven to get the time per week'**
  String get selfAssessedPhysicalActivitySedentaryDescription;

  /// No description provided for @selfAssessedPhysicalActivityTrainingDurationNone.
  ///
  /// In en, this message translates to:
  /// **'0 minutes/none'**
  String get selfAssessedPhysicalActivityTrainingDurationNone;

  /// No description provided for @selfAssessedPhysicalActivityTrainingDurationLessThan30Minutes.
  ///
  /// In en, this message translates to:
  /// **'Less than 30 minutes'**
  String get selfAssessedPhysicalActivityTrainingDurationLessThan30Minutes;

  /// No description provided for @selfAssessedPhysicalActivityTrainingDuration30To60Minutes.
  ///
  /// In en, this message translates to:
  /// **'30-60 minutes (0.5-1 hour)'**
  String get selfAssessedPhysicalActivityTrainingDuration30To60Minutes;

  /// No description provided for @selfAssessedPhysicalActivityTrainingDuration60To90Minutes.
  ///
  /// In en, this message translates to:
  /// **'60-90 minutes (1-1.5 hours)'**
  String get selfAssessedPhysicalActivityTrainingDuration60To90Minutes;

  /// No description provided for @selfAssessedPhysicalActivityTrainingDuration90To120Minutes.
  ///
  /// In en, this message translates to:
  /// **'90-120 minutes (1.5-2 hours)'**
  String get selfAssessedPhysicalActivityTrainingDuration90To120Minutes;

  /// No description provided for @selfAssessedPhysicalActivityTrainingDurationMoreThan120Minutes.
  ///
  /// In en, this message translates to:
  /// **'More than 120 minutes (more than 2 hours)'**
  String get selfAssessedPhysicalActivityTrainingDurationMoreThan120Minutes;

  /// No description provided for @selfAssessedPhysicalActivityEverydayDurationNone.
  ///
  /// In en, this message translates to:
  /// **'0 minutes/none'**
  String get selfAssessedPhysicalActivityEverydayDurationNone;

  /// No description provided for @selfAssessedPhysicalActivityEverydayDurationLessThan30Minutes.
  ///
  /// In en, this message translates to:
  /// **'Less than 30 minutes'**
  String get selfAssessedPhysicalActivityEverydayDurationLessThan30Minutes;

  /// No description provided for @selfAssessedPhysicalActivityEverydayDuration30To60Minutes.
  ///
  /// In en, this message translates to:
  /// **'30-60 minutes (0.5-1 hour)'**
  String get selfAssessedPhysicalActivityEverydayDuration30To60Minutes;

  /// No description provided for @selfAssessedPhysicalActivityEverydayDuration60To90Minutes.
  ///
  /// In en, this message translates to:
  /// **'60-90 minutes (1-1.5 hours)'**
  String get selfAssessedPhysicalActivityEverydayDuration60To90Minutes;

  /// No description provided for @selfAssessedPhysicalActivityEverydayDuration90To150Minutes.
  ///
  /// In en, this message translates to:
  /// **'90-150 minutes (1.5-2.5 hours)'**
  String get selfAssessedPhysicalActivityEverydayDuration90To150Minutes;

  /// No description provided for @selfAssessedPhysicalActivityEverydayDuration150To300Minutes.
  ///
  /// In en, this message translates to:
  /// **'150-300 minutes (2.5-5 hours)'**
  String get selfAssessedPhysicalActivityEverydayDuration150To300Minutes;

  /// No description provided for @selfAssessedPhysicalActivityEverydayDurationMoreThan300Minutes.
  ///
  /// In en, this message translates to:
  /// **'More than 300 minutes'**
  String get selfAssessedPhysicalActivityEverydayDurationMoreThan300Minutes;

  /// No description provided for @selfAssessedPhysicalActivityWeekInfoInstruction.
  ///
  /// In en, this message translates to:
  /// **'To submit an earlier week, change the date below to any day within that week.'**
  String get selfAssessedPhysicalActivityWeekInfoInstruction;

  /// No description provided for @selfAssessedPhysicalActivityWeekInfoRange.
  ///
  /// In en, this message translates to:
  /// **'With the current date, your answers will be saved for {start} to {end}.'**
  String selfAssessedPhysicalActivityWeekInfoRange(Object start, Object end);

  /// No description provided for @selfAssessedSedentaryDurationAlmostAllDay.
  ///
  /// In en, this message translates to:
  /// **'Almost the entire day'**
  String get selfAssessedSedentaryDurationAlmostAllDay;

  /// No description provided for @selfAssessedSedentaryDuration13To15Hours.
  ///
  /// In en, this message translates to:
  /// **'13-15 hours'**
  String get selfAssessedSedentaryDuration13To15Hours;

  /// No description provided for @selfAssessedSedentaryDuration10To12Hours.
  ///
  /// In en, this message translates to:
  /// **'10-12 hours'**
  String get selfAssessedSedentaryDuration10To12Hours;

  /// No description provided for @selfAssessedSedentaryDuration7To9Hours.
  ///
  /// In en, this message translates to:
  /// **'7-9 hours'**
  String get selfAssessedSedentaryDuration7To9Hours;

  /// No description provided for @selfAssessedSedentaryDuration4To6Hours.
  ///
  /// In en, this message translates to:
  /// **'4-6 hours'**
  String get selfAssessedSedentaryDuration4To6Hours;

  /// No description provided for @selfAssessedSedentaryDuration1To3Hours.
  ///
  /// In en, this message translates to:
  /// **'1-3 hours'**
  String get selfAssessedSedentaryDuration1To3Hours;

  /// No description provided for @selfAssessedSedentaryDurationNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get selfAssessedSedentaryDurationNever;

  /// No description provided for @selfAssessedPhysicalActivityTrainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get selfAssessedPhysicalActivityTrainingLabel;

  /// No description provided for @selfAssessedPhysicalActivityEverydayLabel.
  ///
  /// In en, this message translates to:
  /// **'Everyday activity'**
  String get selfAssessedPhysicalActivityEverydayLabel;

  /// No description provided for @selfAssessedPhysicalActivitySedentaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get selfAssessedPhysicalActivitySedentaryLabel;

  /// No description provided for @pressureRelease.
  ///
  /// In en, this message translates to:
  /// **'Pressure release'**
  String get pressureRelease;

  /// No description provided for @pressureReleases.
  ///
  /// In en, this message translates to:
  /// **'Pressure releases'**
  String get pressureReleases;

  /// No description provided for @pressureReleaseNow.
  ///
  /// In en, this message translates to:
  /// **'Pressure release now'**
  String get pressureReleaseNow;

  /// No description provided for @pressureReleaseSelectExercises.
  ///
  /// In en, this message translates to:
  /// **'Choose exercises'**
  String get pressureReleaseSelectExercises;

  /// No description provided for @pressureReleaseSelectExercisesDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep in mind that complete pressure relief gives the best results.'**
  String get pressureReleaseSelectExercisesDescription;

  /// No description provided for @pressureReleaseCreateGoal.
  ///
  /// In en, this message translates to:
  /// **'Create a goal for pressure relief'**
  String get pressureReleaseCreateGoal;

  /// No description provided for @pressureReleaseAlreadyDone.
  ///
  /// In en, this message translates to:
  /// **'I have already performed pressure relief'**
  String get pressureReleaseAlreadyDone;

  /// No description provided for @pressureReleaseTimeToDoIt.
  ///
  /// In en, this message translates to:
  /// **'Time to relieve'**
  String get pressureReleaseTimeToDoIt;

  /// No description provided for @holdPositionFor.
  ///
  /// In en, this message translates to:
  /// **'Hold position for'**
  String get holdPositionFor;

  /// No description provided for @pressureReleaseSittingExercises.
  ///
  /// In en, this message translates to:
  /// **'Sitting exercises'**
  String get pressureReleaseSittingExercises;

  /// No description provided for @pressureReleaseExerciseLying.
  ///
  /// In en, this message translates to:
  /// **'Lying'**
  String get pressureReleaseExerciseLying;

  /// No description provided for @pressureReleaseExerciseLyingDescription.
  ///
  /// In en, this message translates to:
  /// **'Lying on your stomach or side'**
  String get pressureReleaseExerciseLyingDescription;

  /// No description provided for @pressureReleaseExerciseLeanForward.
  ///
  /// In en, this message translates to:
  /// **'Leaning forward'**
  String get pressureReleaseExerciseLeanForward;

  /// No description provided for @pressureReleaseExerciseLeanForwardDescription.
  ///
  /// In en, this message translates to:
  /// **'Lean your upper body forward so that your stomach rests against your thighs or against a table'**
  String get pressureReleaseExerciseLeanForwardDescription;

  /// No description provided for @pressureReleaseExerciseLeanLeft.
  ///
  /// In en, this message translates to:
  /// **'Leaning left'**
  String get pressureReleaseExerciseLeanLeft;

  /// No description provided for @pressureReleaseExerciseLeanLeftDescription.
  ///
  /// In en, this message translates to:
  /// **'Lean your upper body against the left armrest or against a table'**
  String get pressureReleaseExerciseLeanLeftDescription;

  /// No description provided for @pressureReleaseExerciseLeanRight.
  ///
  /// In en, this message translates to:
  /// **'Leaning right'**
  String get pressureReleaseExerciseLeanRight;

  /// No description provided for @pressureReleaseExerciseLeanRightDescription.
  ///
  /// In en, this message translates to:
  /// **'Lean your upper body against the right armrest or against a table'**
  String get pressureReleaseExerciseLeanRightDescription;

  /// No description provided for @urinaryTractInfection.
  ///
  /// In en, this message translates to:
  /// **'Urinary tract infection'**
  String get urinaryTractInfection;

  /// No description provided for @utiTypeNone.
  ///
  /// In en, this message translates to:
  /// **'No infection'**
  String get utiTypeNone;

  /// No description provided for @utiTypeFeeling.
  ///
  /// In en, this message translates to:
  /// **'Feeling'**
  String get utiTypeFeeling;

  /// No description provided for @utiTypeDiagnosed.
  ///
  /// In en, this message translates to:
  /// **'Diagnosed'**
  String get utiTypeDiagnosed;

  /// No description provided for @utiTypeNoneDescription.
  ///
  /// In en, this message translates to:
  /// **'You have no symptoms of a urinary tract infection.'**
  String get utiTypeNoneDescription;

  /// No description provided for @utiTypeFeelingDescription.
  ///
  /// In en, this message translates to:
  /// **'You suspect you have a urinary tract infection.'**
  String get utiTypeFeelingDescription;

  /// No description provided for @utiTypeDiagnosedDescription.
  ///
  /// In en, this message translates to:
  /// **'You have been diagnosed with a urinary tract infection.'**
  String get utiTypeDiagnosedDescription;

  /// No description provided for @utiTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose an option'**
  String get utiTypeHint;

  /// No description provided for @utiChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change urinary tract infection status'**
  String get utiChangeStatus;

  /// No description provided for @noUti.
  ///
  /// In en, this message translates to:
  /// **'No UTI'**
  String get noUti;

  /// No description provided for @noLoggedUti.
  ///
  /// In en, this message translates to:
  /// **'No logged UTI'**
  String get noLoggedUti;

  /// No description provided for @urine.
  ///
  /// In en, this message translates to:
  /// **'Urine'**
  String get urine;

  /// No description provided for @urineTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the option that describes the urine.'**
  String get urineTypeHint;

  /// No description provided for @bladderEmptying.
  ///
  /// In en, this message translates to:
  /// **'Bladder emptying'**
  String get bladderEmptying;

  /// No description provided for @bladderEmptyings.
  ///
  /// In en, this message translates to:
  /// **'Bladder emptyings'**
  String get bladderEmptyings;

  /// No description provided for @bladderEmptyingCreateGoal.
  ///
  /// In en, this message translates to:
  /// **'Create a goal for bladder emptying'**
  String get bladderEmptyingCreateGoal;

  /// No description provided for @bladderEmptyingTimeToDoIt.
  ///
  /// In en, this message translates to:
  /// **'Time to empty'**
  String get bladderEmptyingTimeToDoIt;

  /// No description provided for @urineTypeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get urineTypeNormal;

  /// No description provided for @urineTypeCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get urineTypeCloudy;

  /// No description provided for @urineTypeBlood.
  ///
  /// In en, this message translates to:
  /// **'Blood in the urine'**
  String get urineTypeBlood;

  /// No description provided for @urineSmellTitle.
  ///
  /// In en, this message translates to:
  /// **'Does it smell?'**
  String get urineSmellTitle;

  /// No description provided for @urineSmellDescription.
  ///
  /// In en, this message translates to:
  /// **'Smell can be a sign of infection'**
  String get urineSmellDescription;

  /// No description provided for @urineSmellNo.
  ///
  /// In en, this message translates to:
  /// **'No it does not smell'**
  String get urineSmellNo;

  /// No description provided for @urineSmellYes.
  ///
  /// In en, this message translates to:
  /// **'Yes it smells'**
  String get urineSmellYes;

  /// No description provided for @leakage.
  ///
  /// In en, this message translates to:
  /// **'Leakage'**
  String get leakage;

  /// No description provided for @bowel.
  ///
  /// In en, this message translates to:
  /// **'Bowel'**
  String get bowel;

  /// No description provided for @bowelEmptying.
  ///
  /// In en, this message translates to:
  /// **'Bowel emptying'**
  String get bowelEmptying;

  /// No description provided for @stoolType.
  ///
  /// In en, this message translates to:
  /// **'Stool type'**
  String get stoolType;

  /// No description provided for @stoolTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the option that describes the stool.'**
  String get stoolTypeHint;

  /// No description provided for @stoolType1.
  ///
  /// In en, this message translates to:
  /// **'Severe constipation'**
  String get stoolType1;

  /// No description provided for @stoolType2.
  ///
  /// In en, this message translates to:
  /// **'Constipation'**
  String get stoolType2;

  /// No description provided for @stoolType3.
  ///
  /// In en, this message translates to:
  /// **'Firm'**
  String get stoolType3;

  /// No description provided for @stoolType4.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get stoolType4;

  /// No description provided for @stoolType5.
  ///
  /// In en, this message translates to:
  /// **'Lacking form'**
  String get stoolType5;

  /// No description provided for @stoolType6.
  ///
  /// In en, this message translates to:
  /// **'Mild diarrhea'**
  String get stoolType6;

  /// No description provided for @stoolType7.
  ///
  /// In en, this message translates to:
  /// **'Severe diarrhea'**
  String get stoolType7;

  /// No description provided for @stoolType1Description.
  ///
  /// In en, this message translates to:
  /// **'Separate hard lumps'**
  String get stoolType1Description;

  /// No description provided for @stoolType2Description.
  ///
  /// In en, this message translates to:
  /// **'Lumpy and sausage like'**
  String get stoolType2Description;

  /// No description provided for @stoolType3Description.
  ///
  /// In en, this message translates to:
  /// **'A sausage shape with cracks in the surface'**
  String get stoolType3Description;

  /// No description provided for @stoolType4Description.
  ///
  /// In en, this message translates to:
  /// **'Like a smooth, soft sausage or snake'**
  String get stoolType4Description;

  /// No description provided for @stoolType5Description.
  ///
  /// In en, this message translates to:
  /// **'Soft blobs with clear cut edges'**
  String get stoolType5Description;

  /// No description provided for @stoolType6Description.
  ///
  /// In en, this message translates to:
  /// **'Mushy consistency with ragged edges'**
  String get stoolType6Description;

  /// No description provided for @stoolType7Description.
  ///
  /// In en, this message translates to:
  /// **'Liquid consistency with no solid pieces'**
  String get stoolType7Description;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @goalPressureRelease.
  ///
  /// In en, this message translates to:
  /// **'Set your daily goal for pressure relief'**
  String get goalPressureRelease;

  /// No description provided for @goalBladderEmptying.
  ///
  /// In en, this message translates to:
  /// **'Set your daily goal for bladder emptying'**
  String get goalBladderEmptying;

  /// No description provided for @goalTimePerDay.
  ///
  /// In en, this message translates to:
  /// **'How many times per day?'**
  String get goalTimePerDay;

  /// No description provided for @bladderGoalTimePerDayDescription.
  ///
  /// In en, this message translates to:
  /// **'It is recommended to empty your bladder 4-8 times per day.'**
  String get bladderGoalTimePerDayDescription;

  /// No description provided for @goalTimePerDayDescription.
  ///
  /// In en, this message translates to:
  /// **'We recommend 8 times per day.'**
  String get goalTimePerDayDescription;

  /// No description provided for @goalStart.
  ///
  /// In en, this message translates to:
  /// **'What time of day do you want to start?'**
  String get goalStart;

  /// No description provided for @goalStartDescription.
  ///
  /// In en, this message translates to:
  /// **'For example. an hour after you usually wake up.'**
  String get goalStartDescription;

  /// No description provided for @ofDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'of daily goal'**
  String get ofDailyGoal;

  /// No description provided for @createYourGoal.
  ///
  /// In en, this message translates to:
  /// **'Create your goal'**
  String get createYourGoal;

  /// No description provided for @leftToReachGoalMessage.
  ///
  /// In en, this message translates to:
  /// **'left to reach your daily goal.'**
  String get leftToReachGoalMessage;

  /// No description provided for @reachedGoalMessage.
  ///
  /// In en, this message translates to:
  /// **'You have reached your daily goal!'**
  String get reachedGoalMessage;

  /// No description provided for @editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get editGoal;

  /// No description provided for @pressureUlcer.
  ///
  /// In en, this message translates to:
  /// **'Pressure ulcer'**
  String get pressureUlcer;

  /// No description provided for @pressureUlcers.
  ///
  /// In en, this message translates to:
  /// **'Pressure ulcers'**
  String get pressureUlcers;

  /// No description provided for @noLoggedPressureUlcer.
  ///
  /// In en, this message translates to:
  /// **'No logged pressure ulcer'**
  String get noLoggedPressureUlcer;

  /// No description provided for @pressureUlcerChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change pressure ulcer status'**
  String get pressureUlcerChangeStatus;

  /// No description provided for @pressureUlcerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add pressure ulcer'**
  String get pressureUlcerAdd;

  /// No description provided for @pressureUlcerViewHistory.
  ///
  /// In en, this message translates to:
  /// **'See pressure ulcer history'**
  String get pressureUlcerViewHistory;

  /// No description provided for @pressureUlcerClassification.
  ///
  /// In en, this message translates to:
  /// **'Pressure ulcer classification'**
  String get pressureUlcerClassification;

  /// No description provided for @pressureUlcerClassificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the category of injury your pressure ulcer currently has.'**
  String get pressureUlcerClassificationDescription;

  /// No description provided for @pressureUlcerClassificationHint.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get pressureUlcerClassificationHint;

  /// No description provided for @pressureUlcerLocation.
  ///
  /// In en, this message translates to:
  /// **'Where is your pressure ulcer located?'**
  String get pressureUlcerLocation;

  /// No description provided for @pressureUlcerLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the location of your pressure ulcer.'**
  String get pressureUlcerLocationDescription;

  /// No description provided for @pressureUlcerLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Select a location'**
  String get pressureUlcerLocationHint;

  /// No description provided for @selectInjuryLevel.
  ///
  /// In en, this message translates to:
  /// **'Select injury level'**
  String get selectInjuryLevel;

  /// No description provided for @noPressureUlcer.
  ///
  /// In en, this message translates to:
  /// **'No pressure ulcer'**
  String get noPressureUlcer;

  /// No description provided for @pressureUlcerCategory1.
  ///
  /// In en, this message translates to:
  /// **'Redness'**
  String get pressureUlcerCategory1;

  /// No description provided for @pressureUlcerCategory2.
  ///
  /// In en, this message translates to:
  /// **'Shallow wound'**
  String get pressureUlcerCategory2;

  /// No description provided for @pressureUlcerCategory3.
  ///
  /// In en, this message translates to:
  /// **'Open wound'**
  String get pressureUlcerCategory3;

  /// No description provided for @pressureUlcerCategory4.
  ///
  /// In en, this message translates to:
  /// **'Deep open wound'**
  String get pressureUlcerCategory4;

  /// No description provided for @noPressureUlcerDescription.
  ///
  /// In en, this message translates to:
  /// **'The pressure ulcer has healed'**
  String get noPressureUlcerDescription;

  /// No description provided for @pressureUlcerCategory1Description.
  ///
  /// In en, this message translates to:
  /// **'Redness that does not fade with pressure'**
  String get pressureUlcerCategory1Description;

  /// No description provided for @pressureUlcerCategory2Description.
  ///
  /// In en, this message translates to:
  /// **'Partial skin damage, blister, crack, abraded skin'**
  String get pressureUlcerCategory2Description;

  /// No description provided for @pressureUlcerCategory3Description.
  ///
  /// In en, this message translates to:
  /// **'Open skin with small pit'**
  String get pressureUlcerCategory3Description;

  /// No description provided for @pressureUlcerCategory4Description.
  ///
  /// In en, this message translates to:
  /// **'An open deep wound where bones, tendons and muscles may be visible'**
  String get pressureUlcerCategory4Description;

  /// No description provided for @ancle.
  ///
  /// In en, this message translates to:
  /// **'Ancle'**
  String get ancle;

  /// No description provided for @heel.
  ///
  /// In en, this message translates to:
  /// **'Heel'**
  String get heel;

  /// No description provided for @insideKnee.
  ///
  /// In en, this message translates to:
  /// **'Inside knee'**
  String get insideKnee;

  /// No description provided for @hip.
  ///
  /// In en, this message translates to:
  /// **'Hip'**
  String get hip;

  /// No description provided for @sitBones.
  ///
  /// In en, this message translates to:
  /// **'Sit bones'**
  String get sitBones;

  /// No description provided for @sacrum.
  ///
  /// In en, this message translates to:
  /// **'Sacrum'**
  String get sacrum;

  /// No description provided for @scapula.
  ///
  /// In en, this message translates to:
  /// **'Scapula'**
  String get scapula;

  /// No description provided for @shoulder.
  ///
  /// In en, this message translates to:
  /// **'Shoulder'**
  String get shoulder;

  /// No description provided for @spasticity.
  ///
  /// In en, this message translates to:
  /// **'Spasticity'**
  String get spasticity;

  /// No description provided for @spasticityLevel.
  ///
  /// In en, this message translates to:
  /// **'Spasticity level'**
  String get spasticityLevel;

  /// No description provided for @spasticityLevelDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a number between 1-10'**
  String get spasticityLevelDescription;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Wheelability'**
  String get appName;

  /// No description provided for @redirecting.
  ///
  /// In en, this message translates to:
  /// **'Redirecting...'**
  String get redirecting;

  /// No description provided for @authenticating.
  ///
  /// In en, this message translates to:
  /// **'Authenticating...'**
  String get authenticating;

  /// No description provided for @abort.
  ///
  /// In en, this message translates to:
  /// **'Abort'**
  String get abort;

  /// No description provided for @watchSyncLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'You need to be logged in to sync with your watch.'**
  String get watchSyncLoginRequired;

  /// No description provided for @watchSyncInvalidFitbitInfo.
  ///
  /// In en, this message translates to:
  /// **'Got invalid information from the Fitbit app.'**
  String get watchSyncInvalidFitbitInfo;

  /// No description provided for @forcedLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to login with provided credentials.'**
  String get forcedLoginFailed;

  /// No description provided for @missingUserIdOrApiKey.
  ///
  /// In en, this message translates to:
  /// **'Missing userId or apiKey parameters.'**
  String get missingUserIdOrApiKey;

  /// No description provided for @noWatchConnected.
  ///
  /// In en, this message translates to:
  /// **'No watch connected'**
  String get noWatchConnected;

  /// No description provided for @confirmDisconnectWatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get confirmDisconnectWatchTitle;

  /// No description provided for @disconnectWatchConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting your watch will stop all recordings and remove the connection. Do you want to proceed?'**
  String get disconnectWatchConfirmation;

  /// No description provided for @watchDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Watch disconnected successfully'**
  String get watchDisconnected;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {time}'**
  String lastSynced(Object time);

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @bluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off'**
  String get bluetoothOff;

  /// No description provided for @recordingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recordingInProgress;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @syncInstructions.
  ///
  /// In en, this message translates to:
  /// **'Press the sync button to upload your data'**
  String get syncInstructions;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recordings synced successfully!'**
  String get syncSuccess;

  /// No description provided for @syncNoData.
  ///
  /// In en, this message translates to:
  /// **'No recordings found to sync.'**
  String get syncNoData;

  /// No description provided for @searchingForWatches.
  ///
  /// In en, this message translates to:
  /// **'Searching for watches...'**
  String get searchingForWatches;

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found.'**
  String get noDevicesFound;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @searchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get searchAgain;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @unknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownDevice;

  /// No description provided for @connectWatchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Connect your watch to get started!'**
  String get connectWatchPrompt;

  /// No description provided for @connectWatch.
  ///
  /// In en, this message translates to:
  /// **'Connect Watch'**
  String get connectWatch;

  /// No description provided for @generatedImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Generated Image'**
  String get generatedImageTitle;

  /// No description provided for @noImageFromServer.
  ///
  /// In en, this message translates to:
  /// **'No image returned from server.'**
  String get noImageFromServer;

  /// No description provided for @generatingImage.
  ///
  /// In en, this message translates to:
  /// **'Generating image…'**
  String get generatingImage;

  /// No description provided for @failedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcal;
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
      <String>['en', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
