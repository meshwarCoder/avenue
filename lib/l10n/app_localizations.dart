import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

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
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Avenue'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @startOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Start of the Week'**
  String get startOfWeek;

  /// No description provided for @timeSystem.
  ///
  /// In en, this message translates to:
  /// **'Time System'**
  String get timeSystem;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile Details'**
  String get profileDetails;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

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

  /// No description provided for @betaVersion.
  ///
  /// In en, this message translates to:
  /// **'Beta Version'**
  String get betaVersion;

  /// No description provided for @betaNotice.
  ///
  /// In en, this message translates to:
  /// **'Avenue is currently in beta. Some features are still being polished.'**
  String get betaNotice;

  /// No description provided for @helpImprove.
  ///
  /// In en, this message translates to:
  /// **'Help us improve Avenue'**
  String get helpImprove;

  /// No description provided for @feedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit a bug report or feature request'**
  String get feedbackSubtitle;

  /// No description provided for @versionInfo.
  ///
  /// In en, this message translates to:
  /// **'Avenue v0.1.0-beta'**
  String get versionInfo;

  /// No description provided for @devOptions.
  ///
  /// In en, this message translates to:
  /// **'Dev Options'**
  String get devOptions;

  /// No description provided for @aiModel.
  ///
  /// In en, this message translates to:
  /// **'AI Model'**
  String get aiModel;

  /// No description provided for @cloudApiKey.
  ///
  /// In en, this message translates to:
  /// **'Cloud API Key'**
  String get cloudApiKey;

  /// No description provided for @setUpdateServerKey.
  ///
  /// In en, this message translates to:
  /// **'Set or update server key'**
  String get setUpdateServerKey;

  /// No description provided for @changeAiModel.
  ///
  /// In en, this message translates to:
  /// **'Change AI Model'**
  String get changeAiModel;

  /// No description provided for @modelName.
  ///
  /// In en, this message translates to:
  /// **'Model name'**
  String get modelName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @updateCloudApiKey.
  ///
  /// In en, this message translates to:
  /// **'Update Cloud API Key'**
  String get updateCloudApiKey;

  /// No description provided for @newApiKey.
  ///
  /// In en, this message translates to:
  /// **'New API Key'**
  String get newApiKey;

  /// No description provided for @saveToCloud.
  ///
  /// In en, this message translates to:
  /// **'Save to Cloud'**
  String get saveToCloud;

  /// No description provided for @searchTasksDev.
  ///
  /// In en, this message translates to:
  /// **'Search tasks (Dev Test)'**
  String get searchTasksDev;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found for this query.'**
  String get noResultsFound;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @hour24.
  ///
  /// In en, this message translates to:
  /// **'24-Hour'**
  String get hour24;

  /// No description provided for @hour12.
  ///
  /// In en, this message translates to:
  /// **'12-Hour'**
  String get hour12;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your productivity companion'**
  String get authSubtitle;

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

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @newToAvenue.
  ///
  /// In en, this message translates to:
  /// **'New to Avenue?'**
  String get newToAvenue;

  /// No description provided for @joinAvenue.
  ///
  /// In en, this message translates to:
  /// **'Join Avenue'**
  String get joinAvenue;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @backOnline.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get backOnline;

  /// No description provided for @errTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a task title'**
  String get errTaskTitle;

  /// No description provided for @errStartTime.
  ///
  /// In en, this message translates to:
  /// **'Please select a start time'**
  String get errStartTime;

  /// No description provided for @errEndTime.
  ///
  /// In en, this message translates to:
  /// **'Please select an end time'**
  String get errEndTime;

  /// No description provided for @errTimeRange.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get errTimeRange;

  /// No description provided for @errEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get errEmailRequired;

  /// No description provided for @errEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get errEmailInvalid;

  /// No description provided for @errPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get errPasswordRequired;

  /// No description provided for @errPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get errPasswordShort;

  /// No description provided for @errConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get errConfirmPasswordRequired;

  /// No description provided for @errPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get errPasswordsMismatch;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @whatOnYourMind.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get whatOnYourMind;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Title'**
  String get taskTitle;

  /// No description provided for @anyDetails.
  ///
  /// In en, this message translates to:
  /// **'Any details?'**
  String get anyDetails;

  /// No description provided for @descOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descOptional;

  /// No description provided for @occurrence.
  ///
  /// In en, this message translates to:
  /// **'Occurrence'**
  String get occurrence;

  /// No description provided for @oneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get oneTime;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @scheduling.
  ///
  /// In en, this message translates to:
  /// **'Scheduling'**
  String get scheduling;

  /// No description provided for @repeatOn.
  ///
  /// In en, this message translates to:
  /// **'Repeat on'**
  String get repeatOn;

  /// No description provided for @timeFrame.
  ///
  /// In en, this message translates to:
  /// **'Time Frame'**
  String get timeFrame;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @importance.
  ///
  /// In en, this message translates to:
  /// **'Importance'**
  String get importance;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTask;

  /// No description provided for @updateChanges.
  ///
  /// In en, this message translates to:
  /// **'Update Changes'**
  String get updateChanges;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @errSelectDay.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one day'**
  String get errSelectDay;

  /// No description provided for @errLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Cannot have 3 tasks at the same time!'**
  String get errLimitExceeded;

  /// No description provided for @errPastTask.
  ///
  /// In en, this message translates to:
  /// **'Cannot schedule tasks in the past!'**
  String get errPastTask;

  /// No description provided for @taskOverlap.
  ///
  /// In en, this message translates to:
  /// **'Task Overlap'**
  String get taskOverlap;

  /// No description provided for @overlapMessage.
  ///
  /// In en, this message translates to:
  /// **'This task overlaps with another one in your schedule. Do you want to proceed?'**
  String get overlapMessage;

  /// No description provided for @proceedAnyway.
  ///
  /// In en, this message translates to:
  /// **'Proceed Anyway'**
  String get proceedAnyway;

  /// No description provided for @taskNotifications.
  ///
  /// In en, this message translates to:
  /// **'Task Notifications'**
  String get taskNotifications;

  /// No description provided for @atStartTime.
  ///
  /// In en, this message translates to:
  /// **'At start time'**
  String get atStartTime;

  /// No description provided for @notificationAt.
  ///
  /// In en, this message translates to:
  /// **'Notification at {time}'**
  String notificationAt(Object time);

  /// No description provided for @reminderBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Reminder before start'**
  String get reminderBeforeStart;

  /// No description provided for @minutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before'**
  String minutesBefore(Object minutes);

  /// No description provided for @noEarlyReminder.
  ///
  /// In en, this message translates to:
  /// **'No early reminder'**
  String get noEarlyReminder;

  /// No description provided for @completionAlert.
  ///
  /// In en, this message translates to:
  /// **'Completion Alert'**
  String get completionAlert;

  /// No description provided for @completionAlertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Encouraging notification on Done'**
  String get completionAlertSubtitle;

  /// No description provided for @masterRoutine.
  ///
  /// In en, this message translates to:
  /// **'Master Routine'**
  String get masterRoutine;

  /// No description provided for @noRecurringTasks.
  ///
  /// In en, this message translates to:
  /// **'No recurring tasks yet.'**
  String get noRecurringTasks;

  /// No description provided for @deleteRoutine.
  ///
  /// In en, this message translates to:
  /// **'Delete Routine'**
  String get deleteRoutine;

  /// No description provided for @deleteRoutineConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{taskName}\"? This will stop generating future tasks for this routine.'**
  String deleteRoutineConfirm(Object taskName);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @futureTasks.
  ///
  /// In en, this message translates to:
  /// **'Future Tasks'**
  String get futureTasks;

  /// No description provided for @noFutureTasks.
  ///
  /// In en, this message translates to:
  /// **'No future tasks found'**
  String get noFutureTasks;

  /// No description provided for @pastTasks.
  ///
  /// In en, this message translates to:
  /// **'Past Tasks'**
  String get pastTasks;

  /// No description provided for @previousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous Week'**
  String get previousWeek;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next Week'**
  String get nextWeek;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @noTasksToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks for today. Relax!'**
  String get noTasksToday;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @viewTimeline.
  ///
  /// In en, this message translates to:
  /// **'View Timeline'**
  String get viewTimeline;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history here. 🌫️'**
  String get noHistory;

  /// No description provided for @noTasksRelax.
  ///
  /// In en, this message translates to:
  /// **'No tasks today! ☕'**
  String get noTasksRelax;

  /// No description provided for @motivationalPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect score! You nailed it! 🏆'**
  String get motivationalPerfect;

  /// No description provided for @motivationalExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent performance! 🌟'**
  String get motivationalExcellent;

  /// No description provided for @motivationalGood.
  ///
  /// In en, this message translates to:
  /// **'Good effort on this day! 👍'**
  String get motivationalGood;

  /// No description provided for @motivationalSome.
  ///
  /// In en, this message translates to:
  /// **'Managed to get some done. 📈'**
  String get motivationalSome;

  /// No description provided for @motivationalPassed.
  ///
  /// In en, this message translates to:
  /// **'This day passed by. ⌛'**
  String get motivationalPassed;

  /// No description provided for @motivationalStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started! 💪'**
  String get motivationalStart;

  /// No description provided for @motivationalGreatStart.
  ///
  /// In en, this message translates to:
  /// **'Great start, keep it up! ✨'**
  String get motivationalGreatStart;

  /// No description provided for @motivationalDoingGreat.
  ///
  /// In en, this message translates to:
  /// **'You\'re doing great! 🌟'**
  String get motivationalDoingGreat;

  /// No description provided for @motivationalAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there! 🎯'**
  String get motivationalAlmostThere;

  /// No description provided for @motivationalAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done! Enjoy your day 🎉'**
  String get motivationalAllDone;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @oneTimeUpper.
  ///
  /// In en, this message translates to:
  /// **'ONE-TIME'**
  String get oneTimeUpper;

  /// No description provided for @recurringUpper.
  ///
  /// In en, this message translates to:
  /// **'RECURRING'**
  String get recurringUpper;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get notes;

  /// No description provided for @taskNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Task hasn\'t started yet!'**
  String get taskNotStarted;

  /// No description provided for @markPending.
  ///
  /// In en, this message translates to:
  /// **'Mark as Pending'**
  String get markPending;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as Done'**
  String get markDone;

  /// No description provided for @deleteRecurringTask.
  ///
  /// In en, this message translates to:
  /// **'Delete Recurring Task'**
  String get deleteRecurringTask;

  /// No description provided for @deleteRecurringConfirm.
  ///
  /// In en, this message translates to:
  /// **'Would you like to delete this task for today only, or stop it from recurring entirely?'**
  String get deleteRecurringConfirm;

  /// No description provided for @onlyToday.
  ///
  /// In en, this message translates to:
  /// **'Only Today'**
  String get onlyToday;

  /// No description provided for @entirely.
  ///
  /// In en, this message translates to:
  /// **'Entirely'**
  String get entirely;

  /// No description provided for @fromTime.
  ///
  /// In en, this message translates to:
  /// **'From {time}'**
  String fromTime(Object time);

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All Day'**
  String get allDay;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @mayLong.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get mayLong;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @crushedIt.
  ///
  /// In en, this message translates to:
  /// **'You crushed it!'**
  String get crushedIt;

  /// No description provided for @readyMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Ready to mark this task as done and keep the momentum going?'**
  String get readyMarkDone;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get letsGo;

  /// No description provided for @undoTask.
  ///
  /// In en, this message translates to:
  /// **'Undo this task?'**
  String get undoTask;

  /// No description provided for @undoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Marking this as not done will move it back to your active schedule. Continue?'**
  String get undoConfirm;

  /// No description provided for @yesUndo.
  ///
  /// In en, this message translates to:
  /// **'Yes, undo'**
  String get yesUndo;

  /// No description provided for @actionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Action Blocked'**
  String get actionBlocked;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @backToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to Today'**
  String get backToToday;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @executed.
  ///
  /// In en, this message translates to:
  /// **'Executed'**
  String get executed;

  /// No description provided for @successfully.
  ///
  /// In en, this message translates to:
  /// **'successfully'**
  String get successfully;

  /// No description provided for @forDate.
  ///
  /// In en, this message translates to:
  /// **'for {date}'**
  String forDate(Object date);

  /// No description provided for @aiIsThinking.
  ///
  /// In en, this message translates to:
  /// **'Avenue is thinking...'**
  String get aiIsThinking;

  /// No description provided for @howCanIHelp.
  ///
  /// In en, this message translates to:
  /// **'How can I help you today?'**
  String get howCanIHelp;

  /// No description provided for @aiEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try \"Plan my week\" or \"Add a gym session every Monday at 6pm\"'**
  String get aiEmptySubtitle;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Action'**
  String get confirmAction;

  /// No description provided for @confirmAll.
  ///
  /// In en, this message translates to:
  /// **'Confirm All ({count})'**
  String confirmAll(Object count);

  /// No description provided for @executedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Executed successfully'**
  String get executedSuccessfully;

  /// No description provided for @personalTaskManager.
  ///
  /// In en, this message translates to:
  /// **'Your personal task manager'**
  String get personalTaskManager;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renameChat.
  ///
  /// In en, this message translates to:
  /// **'Rename Chat'**
  String get renameChat;

  /// No description provided for @enterNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter new title'**
  String get enterNewTitle;

  /// No description provided for @deleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat'**
  String get deleteChat;

  /// No description provided for @deleteChatConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this chat? This action cannot be undone.'**
  String get deleteChatConfirm;

  /// No description provided for @aiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'AI is unavailable'**
  String get aiUnavailable;

  /// No description provided for @messageAssistant.
  ///
  /// In en, this message translates to:
  /// **'Message Assistant...'**
  String get messageAssistant;

  /// No description provided for @connectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Internet connection required'**
  String get connectionRequired;

  /// No description provided for @pleaseLogIn.
  ///
  /// In en, this message translates to:
  /// **'Please log in to use the AI Assistant'**
  String get pleaseLogIn;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(Object count);

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank You!'**
  String get thankYou;

  /// No description provided for @feedbackThankYouMessage.
  ///
  /// In en, this message translates to:
  /// **'We truly appreciate your feedback! It helps us make Avenue better for everyone.'**
  String get feedbackThankYouMessage;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get submitFeedback;

  /// No description provided for @feedbackHeader.
  ///
  /// In en, this message translates to:
  /// **'Your feedback is important'**
  String get feedbackHeader;

  /// No description provided for @feedbackHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us improve Avenue by reporting bugs or suggesting new features.'**
  String get feedbackHeaderSubtitle;

  /// No description provided for @feedbackType.
  ///
  /// In en, this message translates to:
  /// **'Feedback Type'**
  String get feedbackType;

  /// No description provided for @bugReport.
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get bugReport;

  /// No description provided for @featureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get featureRequest;

  /// No description provided for @howCanWeImprove.
  ///
  /// In en, this message translates to:
  /// **'How can we improve?'**
  String get howCanWeImprove;

  /// No description provided for @enterMessageHere.
  ///
  /// In en, this message translates to:
  /// **'Enter your message here...'**
  String get enterMessageHere;

  /// No description provided for @errEnterMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message'**
  String get errEnterMessage;

  /// No description provided for @apiKeyEditorNotice.
  ///
  /// In en, this message translates to:
  /// **'Enter a new OpenRouter API Key. This will be stored securely in the cloud and used by the server.'**
  String get apiKeyEditorNotice;

  /// No description provided for @openRouterApiKey.
  ///
  /// In en, this message translates to:
  /// **'OpenRouter API Key'**
  String get openRouterApiKey;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @avenueNotifications.
  ///
  /// In en, this message translates to:
  /// **'Avenue Notifications'**
  String get avenueNotifications;

  /// No description provided for @avenueNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Default notification channel for Avenue app'**
  String get avenueNotificationsDesc;

  /// No description provided for @errNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection try again'**
  String get errNoInternet;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout try again'**
  String get errTimeout;

  /// No description provided for @errUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error occurred try again'**
  String get errUnexpected;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get errInvalidCredentials;

  /// No description provided for @errEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email first.'**
  String get errEmailNotConfirmed;

  /// No description provided for @errUserAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This account already exists. Try logging in.'**
  String get errUserAlreadyExists;

  /// No description provided for @errRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get errRateLimit;

  /// No description provided for @errAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Try again.'**
  String get errAuthFailed;

  /// No description provided for @errTaskNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task not found'**
  String get errTaskNotFound;

  /// No description provided for @errAiUnavailableBeta.
  ///
  /// In en, this message translates to:
  /// **'The app is still in beta, and we can\'t afford the API right now. Please try again later.'**
  String get errAiUnavailableBeta;

  /// No description provided for @errAiDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your daily (5) AI usage limit. Since the app is in beta, these limits help us manage costs. Please try again tomorrow.'**
  String get errAiDailyLimit;

  /// No description provided for @errAiMonthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your monthly (50) AI usage limit. Since the app is in beta, these limits help us manage costs. Please try again next month.'**
  String get errAiMonthlyLimit;

  /// No description provided for @actionsConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Actions confirmed'**
  String get actionsConfirmed;

  /// No description provided for @actionCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get actionCreated;

  /// No description provided for @actionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get actionDeleted;

  /// No description provided for @actionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get actionUpdated;

  /// No description provided for @actionSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get actionSkipped;

  /// No description provided for @actionTask.
  ///
  /// In en, this message translates to:
  /// **'task'**
  String get actionTask;

  /// No description provided for @actionHabit.
  ///
  /// In en, this message translates to:
  /// **'habit'**
  String get actionHabit;

  /// No description provided for @actionHabitInstance.
  ///
  /// In en, this message translates to:
  /// **'habit instance'**
  String get actionHabitInstance;
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
      <String>['ar', 'de', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
