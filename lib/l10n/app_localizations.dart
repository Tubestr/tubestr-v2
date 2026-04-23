import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Tubestr'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabCapture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get tabCapture;

  /// No description provided for @tabStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get tabStudio;

  /// No description provided for @tabParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get tabParent;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get actionHide;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionReveal.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get actionReveal;

  /// No description provided for @actionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get actionSend;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// No description provided for @actionWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get actionWatch;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get actionSkipForNow;

  /// No description provided for @actionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get actionRestore;

  /// No description provided for @actionRetryNow.
  ///
  /// In en, this message translates to:
  /// **'Retry now'**
  String get actionRetryNow;

  /// No description provided for @actionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get actionApprove;

  /// No description provided for @actionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get actionReject;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @publicKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Public key copied'**
  String get publicKeyCopied;

  /// No description provided for @recoveryKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Recovery key copied'**
  String get recoveryKeyCopied;

  /// No description provided for @externalOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open {title} in a browser.'**
  String externalOpenFailed(String title);

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystemDescription.
  ///
  /// In en, this message translates to:
  /// **'Follow device'**
  String get themeSystemDescription;

  /// No description provided for @themeLightDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep it bright'**
  String get themeLightDescription;

  /// No description provided for @themeDarkDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep it cozy'**
  String get themeDarkDescription;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languageSystemDescription.
  ///
  /// In en, this message translates to:
  /// **'Follow device language'**
  String get languageSystemDescription;

  /// No description provided for @languageEnglishDescription.
  ///
  /// In en, this message translates to:
  /// **'Use English'**
  String get languageEnglishDescription;

  /// No description provided for @languageSpanishDescription.
  ///
  /// In en, this message translates to:
  /// **'Use Spanish'**
  String get languageSpanishDescription;

  /// No description provided for @kidThemeCampfire.
  ///
  /// In en, this message translates to:
  /// **'Campfire'**
  String get kidThemeCampfire;

  /// No description provided for @kidThemeTreehouse.
  ///
  /// In en, this message translates to:
  /// **'Treehouse'**
  String get kidThemeTreehouse;

  /// No description provided for @kidThemeBlanketFort.
  ///
  /// In en, this message translates to:
  /// **'Blanket Fort'**
  String get kidThemeBlanketFort;

  /// No description provided for @kidThemeStarlight.
  ///
  /// In en, this message translates to:
  /// **'Starlight'**
  String get kidThemeStarlight;

  /// No description provided for @switchProfile.
  ///
  /// In en, this message translates to:
  /// **'Switch Profile'**
  String get switchProfile;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @privateKeyBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Private key backup'**
  String get privateKeyBackupTitle;

  /// No description provided for @privateKeyBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This private key gives full control of your parent account.'**
  String get privateKeyBackupSubtitle;

  /// No description provided for @privateKeyBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'Keep this private. Anyone with this key can control your family account.'**
  String get privateKeyBackupWarning;

  /// No description provided for @profileSwitcherNoProfile.
  ///
  /// In en, this message translates to:
  /// **'No profile yet'**
  String get profileSwitcherNoProfile;

  /// No description provided for @profileSwitcherProfileFallback.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSwitcherProfileFallback;

  /// No description provided for @scanQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQrTitle;

  /// No description provided for @scanQrInstructions.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a QR code.'**
  String get scanQrInstructions;

  /// No description provided for @qrNoCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera available.'**
  String get qrNoCamera;

  /// No description provided for @qrOpenCameraFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open camera: {error}'**
  String qrOpenCameraFailed(String error);

  /// No description provided for @reportFeelingPrompt.
  ///
  /// In en, this message translates to:
  /// **'How does this video make you feel?'**
  String get reportFeelingPrompt;

  /// No description provided for @reportActionPrompt.
  ///
  /// In en, this message translates to:
  /// **'What should we do?'**
  String get reportActionPrompt;

  /// No description provided for @reportConfirmPrompt.
  ///
  /// In en, this message translates to:
  /// **'Ready to send?'**
  String get reportConfirmPrompt;

  /// No description provided for @reportFeelingUncomfortable.
  ///
  /// In en, this message translates to:
  /// **'Feels Weird'**
  String get reportFeelingUncomfortable;

  /// No description provided for @reportFeelingSad.
  ///
  /// In en, this message translates to:
  /// **'Makes Me Sad'**
  String get reportFeelingSad;

  /// No description provided for @reportFeelingConfused.
  ///
  /// In en, this message translates to:
  /// **'Confusing'**
  String get reportFeelingConfused;

  /// No description provided for @reportFeelingScared.
  ///
  /// In en, this message translates to:
  /// **'Scary'**
  String get reportFeelingScared;

  /// No description provided for @reportFeelingAngry.
  ///
  /// In en, this message translates to:
  /// **'Really Bad'**
  String get reportFeelingAngry;

  /// No description provided for @reportActionTell.
  ///
  /// In en, this message translates to:
  /// **'Just Tell Them'**
  String get reportActionTell;

  /// No description provided for @reportActionTellSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Note it for yourself.'**
  String get reportActionTellSubtitle;

  /// No description provided for @reportActionHide.
  ///
  /// In en, this message translates to:
  /// **'Hide Their Videos'**
  String get reportActionHide;

  /// No description provided for @reportActionHideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let your parent know privately.'**
  String get reportActionHideSubtitle;

  /// No description provided for @reportActionBlock.
  ///
  /// In en, this message translates to:
  /// **'Block Them'**
  String get reportActionBlock;

  /// No description provided for @reportActionBlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alert both families.'**
  String get reportActionBlockSubtitle;

  /// No description provided for @reportDestinationLocal.
  ///
  /// In en, this message translates to:
  /// **'Stays on this device'**
  String get reportDestinationLocal;

  /// No description provided for @reportDestinationParent.
  ///
  /// In en, this message translates to:
  /// **'Your parent'**
  String get reportDestinationParent;

  /// No description provided for @reportDestinationFamily.
  ///
  /// In en, this message translates to:
  /// **'Both families'**
  String get reportDestinationFamily;

  /// No description provided for @reportLevelNoted.
  ///
  /// In en, this message translates to:
  /// **'Level 1 · Noted'**
  String get reportLevelNoted;

  /// No description provided for @reportLevelParentHelp.
  ///
  /// In en, this message translates to:
  /// **'Level 2 · Parent help'**
  String get reportLevelParentHelp;

  /// No description provided for @reportLevelFamilyAlert.
  ///
  /// In en, this message translates to:
  /// **'Level 3 · Family alert'**
  String get reportLevelFamilyAlert;

  /// No description provided for @reportLevelOneExplanation.
  ///
  /// In en, this message translates to:
  /// **'This stays on your device so you can talk about it with a grown-up later.'**
  String get reportLevelOneExplanation;

  /// No description provided for @reportLevelTwoExplanation.
  ///
  /// In en, this message translates to:
  /// **'This lets your parent know so they can check in with you.'**
  String get reportLevelTwoExplanation;

  /// No description provided for @reportLevelThreeExplanation.
  ///
  /// In en, this message translates to:
  /// **'This sends an alert to both families so the grown-ups can sort it out.'**
  String get reportLevelThreeExplanation;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonUnsafe.
  ///
  /// In en, this message translates to:
  /// **'Unsafe'**
  String get reportReasonUnsafe;

  /// No description provided for @reportReasonIllegal.
  ///
  /// In en, this message translates to:
  /// **'Illegal'**
  String get reportReasonIllegal;

  /// No description provided for @reportLevelValue.
  ///
  /// In en, this message translates to:
  /// **'level {level}'**
  String reportLevelValue(int level);

  /// No description provided for @onboardingIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Family\'s Private Space'**
  String get onboardingIntroTitle;

  /// No description provided for @onboardingIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tubestr is a video app built just for families. No ads, no algorithms, no strangers.'**
  String get onboardingIntroSubtitle;

  /// No description provided for @onboardingParentKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Your Parent Key'**
  String get onboardingParentKeyTitle;

  /// No description provided for @onboardingParentKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'First, you\'ll set up a secure parent identity. This key is yours alone and controls your family\'s account.'**
  String get onboardingParentKeySubtitle;

  /// No description provided for @onboardingKidsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Your Kids'**
  String get onboardingKidsTitle;

  /// No description provided for @onboardingKidsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a profile for each child with their own colorful theme. Each kid gets a personalized experience.'**
  String get onboardingKidsSubtitle;

  /// No description provided for @onboardingCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Record & Edit Together'**
  String get onboardingCreateTitle;

  /// No description provided for @onboardingCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Kids can capture videos, add stickers, music, and effects in the Edit Studio. Creativity without the risk.'**
  String get onboardingCreateSubtitle;

  /// No description provided for @onboardingApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'You Approve Everything'**
  String get onboardingApproveTitle;

  /// No description provided for @onboardingApproveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every video goes through you first. Review, approve, and share only with family members you trust.'**
  String get onboardingApproveSubtitle;

  /// No description provided for @onboardingStepOne.
  ///
  /// In en, this message translates to:
  /// **'Step 1'**
  String get onboardingStepOne;

  /// No description provided for @onboardingStepTwo.
  ///
  /// In en, this message translates to:
  /// **'Step 2'**
  String get onboardingStepTwo;

  /// No description provided for @onboardingStepThree.
  ///
  /// In en, this message translates to:
  /// **'Step 3'**
  String get onboardingStepThree;

  /// No description provided for @onboardingStepFour.
  ///
  /// In en, this message translates to:
  /// **'Step 4'**
  String get onboardingStepFour;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Tubestr'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get onboardingWelcomeBackTitle;

  /// No description provided for @onboardingGettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get onboardingGettingStarted;

  /// No description provided for @onboardingParentAccount.
  ///
  /// In en, this message translates to:
  /// **'Parent account'**
  String get onboardingParentAccount;

  /// No description provided for @onboardingChildProfiles.
  ///
  /// In en, this message translates to:
  /// **'Child profiles'**
  String get onboardingChildProfiles;

  /// No description provided for @onboardingAlmostDone.
  ///
  /// In en, this message translates to:
  /// **'Almost done'**
  String get onboardingAlmostDone;

  /// No description provided for @onboardingCreateNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get onboardingCreateNewAccount;

  /// No description provided for @onboardingHaveBackupKey.
  ///
  /// In en, this message translates to:
  /// **'I have a backup key'**
  String get onboardingHaveBackupKey;

  /// No description provided for @onboardingParentDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Parent display name'**
  String get onboardingParentDisplayName;

  /// No description provided for @onboardingParentBirthYear.
  ///
  /// In en, this message translates to:
  /// **'Parent birth year'**
  String get onboardingParentBirthYear;

  /// No description provided for @onboardingParentBackupKey.
  ///
  /// In en, this message translates to:
  /// **'Parent backup key'**
  String get onboardingParentBackupKey;

  /// No description provided for @onboardingGenerateParentKey.
  ///
  /// In en, this message translates to:
  /// **'Generate Parent Key'**
  String get onboardingGenerateParentKey;

  /// No description provided for @onboardingContinueChildProfiles.
  ///
  /// In en, this message translates to:
  /// **'Continue to Child Profiles'**
  String get onboardingContinueChildProfiles;

  /// No description provided for @onboardingComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete Onboarding'**
  String get onboardingComplete;

  /// No description provided for @onboardingAddChildProfile.
  ///
  /// In en, this message translates to:
  /// **'Add Child Profile'**
  String get onboardingAddChildProfile;

  /// No description provided for @onboardingScanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get onboardingScanQrCode;

  /// No description provided for @onboardingReadPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read privacy policy'**
  String get onboardingReadPrivacyPolicy;

  /// No description provided for @onboardingAllowAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow Access'**
  String get onboardingAllowAccess;

  /// No description provided for @onboardingRequestingAccess.
  ///
  /// In en, this message translates to:
  /// **'Requesting Access...'**
  String get onboardingRequestingAccess;

  /// No description provided for @onboardingParentEligibilityMissingYear.
  ///
  /// In en, this message translates to:
  /// **'Enter the parent account holder\'s birth year before continuing.'**
  String get onboardingParentEligibilityMissingYear;

  /// No description provided for @onboardingParentEligibilityInvalidYear.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid four-digit birth year.'**
  String get onboardingParentEligibilityInvalidYear;

  /// No description provided for @onboardingParentEligibilityYearRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a birth year between 1900 and {currentYear}.'**
  String onboardingParentEligibilityYearRange(int currentYear);

  /// No description provided for @onboardingParentEligibilityAdult.
  ///
  /// In en, this message translates to:
  /// **'Tubestr parent accounts must be created by an adult who is 18 or older.'**
  String get onboardingParentEligibilityAdult;

  /// No description provided for @onboardingParentEligibilityConsent.
  ///
  /// In en, this message translates to:
  /// **'Confirm the parent consent statement before generating the parent key.'**
  String get onboardingParentEligibilityConsent;

  /// No description provided for @onboardingParentKeyCreated.
  ///
  /// In en, this message translates to:
  /// **'Parent key created. Save your backup before you continue.'**
  String get onboardingParentKeyCreated;

  /// No description provided for @onboardingBackupKeyAdded.
  ///
  /// In en, this message translates to:
  /// **'Backup key added. Restore when you are ready.'**
  String get onboardingBackupKeyAdded;

  /// No description provided for @onboardingRestoreKeyIncomplete.
  ///
  /// In en, this message translates to:
  /// **'That backup key doesn\'t look complete yet. Paste the full `nsec1...` key or 64-character backup key and try again.'**
  String get onboardingRestoreKeyIncomplete;

  /// No description provided for @onboardingRestoreKeyFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not restore that backup key yet. Please double-check it and try again.'**
  String get onboardingRestoreKeyFailed;

  /// No description provided for @onboardingChildNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a child name before continuing.'**
  String get onboardingChildNameRequired;

  /// No description provided for @onboardingAddChildFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not add that child profile yet.'**
  String get onboardingAddChildFailed;

  /// No description provided for @onboardingNeedChildProfile.
  ///
  /// In en, this message translates to:
  /// **'Add at least one child profile to finish setup.'**
  String get onboardingNeedChildProfile;

  /// No description provided for @onboardingPermissionsFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not get camera and microphone access yet. You can try again now or allow them later in Settings.'**
  String get onboardingPermissionsFailed;

  /// No description provided for @onboardingCheckingParentKey.
  ///
  /// In en, this message translates to:
  /// **'Checking your saved parent key...'**
  String get onboardingCheckingParentKey;

  /// No description provided for @onboardingBootstrapNeedsMoment.
  ///
  /// In en, this message translates to:
  /// **'Tubestr needs another moment'**
  String get onboardingBootstrapNeedsMoment;

  /// No description provided for @onboardingBootstrapChecking.
  ///
  /// In en, this message translates to:
  /// **'We are checking your parent backup and preparing this device.'**
  String get onboardingBootstrapChecking;

  /// No description provided for @onboardingBootstrapReachFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not reach this device\'s saved family setup just yet. Please try again in a moment.'**
  String get onboardingBootstrapReachFailed;

  /// No description provided for @onboardingBootstrapLibraryMoment.
  ///
  /// In en, this message translates to:
  /// **'Your family library needs another moment to open on this device. Please try again.'**
  String get onboardingBootstrapLibraryMoment;

  /// No description provided for @onboardingBootstrapGeneric.
  ///
  /// In en, this message translates to:
  /// **'We hit a setup snag while opening your family space. Nothing is lost. Please try again.'**
  String get onboardingBootstrapGeneric;

  /// No description provided for @onboardingWhoFamily.
  ///
  /// In en, this message translates to:
  /// **'Who\'s in Your Family?'**
  String get onboardingWhoFamily;

  /// No description provided for @onboardingWhoFamilySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a profile for each child. They\'ll each get their own themed space to watch and create videos.'**
  String get onboardingWhoFamilySubtitle;

  /// No description provided for @onboardingTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get onboardingTheme;

  /// No description provided for @onboardingName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get onboardingName;

  /// No description provided for @onboardingPreparingKey.
  ///
  /// In en, this message translates to:
  /// **'Preparing your secure parent key...'**
  String get onboardingPreparingKey;

  /// No description provided for @onboardingSaveParentKey.
  ///
  /// In en, this message translates to:
  /// **'Save your parent key'**
  String get onboardingSaveParentKey;

  /// No description provided for @onboardingPrivateKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Your private key is the master backup for this parent account. Save it somewhere safe before continuing.'**
  String get onboardingPrivateKeyHelp;

  /// No description provided for @onboardingCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re All Set!'**
  String get onboardingCompleteTitle;

  /// No description provided for @onboardingCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your family\'s Tubestr is ready.'**
  String get onboardingCompleteSubtitle;

  /// No description provided for @onboardingBackupShareText.
  ///
  /// In en, this message translates to:
  /// **'Tubestr Parent Backup Key\n\nKeep this private. Anyone with this key can control your family account.\n\n{key}'**
  String onboardingBackupShareText(String key);

  /// No description provided for @homeGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get homeGoodMorning;

  /// No description provided for @homeGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get homeGoodAfternoon;

  /// No description provided for @homeGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get homeGoodEvening;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String homeGreeting(String greeting, String name);

  /// No description provided for @homeStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start in Capture, then head to Edit Studio to add stickers, music, or text.'**
  String get homeStartSubtitle;

  /// No description provided for @homeVideosNeedMoment.
  ///
  /// In en, this message translates to:
  /// **'Your videos need another moment'**
  String get homeVideosNeedMoment;

  /// No description provided for @homeLibraryError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this child\'s library just yet. Pull down to try again.'**
  String get homeLibraryError;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your family video shelf starts here'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture a first clip or connect with a trusted family before this space fills up.'**
  String get homeEmptySubtitle;

  /// No description provided for @homeOpenCapture.
  ///
  /// In en, this message translates to:
  /// **'Open Capture'**
  String get homeOpenCapture;

  /// No description provided for @homeConnectFamilies.
  ///
  /// In en, this message translates to:
  /// **'Connect Families'**
  String get homeConnectFamilies;

  /// No description provided for @homeCapturePrompt.
  ///
  /// In en, this message translates to:
  /// **'Capture a clip, then decorate it in Edit Studio when you\'re ready.'**
  String get homeCapturePrompt;

  /// No description provided for @homeShareLater.
  ///
  /// In en, this message translates to:
  /// **'Share later'**
  String get homeShareLater;

  /// No description provided for @homeConnectWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Connect with Friends'**
  String get homeConnectWithFriends;

  /// No description provided for @homeShareTrustedFamilies.
  ///
  /// In en, this message translates to:
  /// **'Share videos with trusted families'**
  String get homeShareTrustedFamilies;

  /// No description provided for @homeReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get homeReady;

  /// No description provided for @homeTapDownloadLater.
  ///
  /// In en, this message translates to:
  /// **'Tap to download later'**
  String get homeTapDownloadLater;

  /// No description provided for @homeDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get homeDownloading;

  /// No description provided for @homeNeedsRetry.
  ///
  /// In en, this message translates to:
  /// **'Needs retry'**
  String get homeNeedsRetry;

  /// No description provided for @approvalPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get approvalPending;

  /// No description provided for @captureCameraNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Camera needs attention'**
  String get captureCameraNeedsAttention;

  /// No description provided for @captureNoCamera.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a camera on this device right now.'**
  String get captureNoCamera;

  /// No description provided for @captureCheckingClip.
  ///
  /// In en, this message translates to:
  /// **'Checking your clip'**
  String get captureCheckingClip;

  /// No description provided for @captureTryRecordingAgain.
  ///
  /// In en, this message translates to:
  /// **'Try recording again'**
  String get captureTryRecordingAgain;

  /// No description provided for @captureVideoSaved.
  ///
  /// In en, this message translates to:
  /// **'Video Saved!'**
  String get captureVideoSaved;

  /// No description provided for @captureSavedNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Saved, but needs a parent look'**
  String get captureSavedNeedsReview;

  /// No description provided for @captureClipReady.
  ///
  /// In en, this message translates to:
  /// **'Clip ready'**
  String get captureClipReady;

  /// No description provided for @captureReadyDetail.
  ///
  /// In en, this message translates to:
  /// **'Your clip is saved, scanned, and ready to edit, watch, or share.'**
  String get captureReadyDetail;

  /// No description provided for @captureShareNow.
  ///
  /// In en, this message translates to:
  /// **'Share now'**
  String get captureShareNow;

  /// No description provided for @captureChooseChild.
  ///
  /// In en, this message translates to:
  /// **'Choose a child profile before recording a clip.'**
  String get captureChooseChild;

  /// No description provided for @captureCameraTimeout.
  ///
  /// In en, this message translates to:
  /// **'The camera took too long to open. Try again, or close any other app using the camera.'**
  String get captureCameraTimeout;

  /// No description provided for @captureCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is turned off. Allow camera access in Settings, then try again.'**
  String get captureCameraDenied;

  /// No description provided for @captureMicrophoneDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off. Try again, or turn microphone access on in Settings to record with sound.'**
  String get captureMicrophoneDenied;

  /// No description provided for @captureCameraStillDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is still turned off. Allow access in Settings, then try again.'**
  String get captureCameraStillDenied;

  /// No description provided for @captureCameraBusy.
  ///
  /// In en, this message translates to:
  /// **'The camera is busy right now. Close any other app using it and try again.'**
  String get captureCameraBusy;

  /// No description provided for @captureCameraStartFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t start the camera just yet. Give it another try.'**
  String get captureCameraStartFailed;

  /// No description provided for @captureFinishSetupShare.
  ///
  /// In en, this message translates to:
  /// **'Finish parent setup before sharing clips with family.'**
  String get captureFinishSetupShare;

  /// No description provided for @captureNeedsParentReview.
  ///
  /// In en, this message translates to:
  /// **'This clip needs a parent review before it can be shared.'**
  String get captureNeedsParentReview;

  /// No description provided for @captureConnectFamilyShare.
  ///
  /// In en, this message translates to:
  /// **'Connect with a family space first, then you can share this clip.'**
  String get captureConnectFamilyShare;

  /// No description provided for @captureShareFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t share that clip yet. It\'s still saved safely here.'**
  String get captureShareFailed;

  /// No description provided for @captureSharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing \"{title}\" to {count, plural, =1{# family space} other{# family spaces}}...'**
  String captureSharing(String title, int count);

  /// No description provided for @editorHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Studio'**
  String get editorHubTitle;

  /// No description provided for @editorHubNeedsMoment.
  ///
  /// In en, this message translates to:
  /// **'Edit Studio needs another moment'**
  String get editorHubNeedsMoment;

  /// No description provided for @editorHubLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your clips for editing just yet. Try switching profiles or come back in a moment.'**
  String get editorHubLoadFailed;

  /// No description provided for @editorHubEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Need a clip'**
  String get editorHubEmptyTitle;

  /// No description provided for @editorHubEmptyDetail.
  ///
  /// In en, this message translates to:
  /// **'Capture something first, then bring it here for stickers, music, text, and remixes.'**
  String get editorHubEmptyDetail;

  /// No description provided for @editorHubCaptureFirst.
  ///
  /// In en, this message translates to:
  /// **'Capture First'**
  String get editorHubCaptureFirst;

  /// No description provided for @editorToolTrim.
  ///
  /// In en, this message translates to:
  /// **'Trim'**
  String get editorToolTrim;

  /// No description provided for @editorToolEffects.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get editorToolEffects;

  /// No description provided for @editorToolStickers.
  ///
  /// In en, this message translates to:
  /// **'Stickers'**
  String get editorToolStickers;

  /// No description provided for @editorToolAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get editorToolAudio;

  /// No description provided for @editorToolText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get editorToolText;

  /// No description provided for @editorActionKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing later'**
  String get editorActionKeepEditing;

  /// No description provided for @editorActionUseSticker.
  ///
  /// In en, this message translates to:
  /// **'Use Sticker'**
  String get editorActionUseSticker;

  /// No description provided for @editorActionRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get editorActionRetake;

  /// No description provided for @editorSearchStickers.
  ///
  /// In en, this message translates to:
  /// **'Search stickers'**
  String get editorSearchStickers;

  /// No description provided for @editorSearchMusic.
  ///
  /// In en, this message translates to:
  /// **'Search music'**
  String get editorSearchMusic;

  /// No description provided for @editorTypeSomething.
  ///
  /// In en, this message translates to:
  /// **'Type something...'**
  String get editorTypeSomething;

  /// No description provided for @editorAddText.
  ///
  /// In en, this message translates to:
  /// **'Add text'**
  String get editorAddText;

  /// No description provided for @editorTapText.
  ///
  /// In en, this message translates to:
  /// **'Tap existing text or add a new one.'**
  String get editorTapText;

  /// No description provided for @editorStickerPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo to create a sticker'**
  String get editorStickerPhotoTitle;

  /// No description provided for @editorSelfieCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is turned off. Allow it in Settings, then try again.'**
  String get editorSelfieCameraDenied;

  /// No description provided for @editorSelfieCameraFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open the selfie camera just yet. Please try again.'**
  String get editorSelfieCameraFailed;

  /// No description provided for @editorStickerLiftFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t lift the sticker from that photo. Try another selfie with a clearer background.'**
  String get editorStickerLiftFailed;

  /// No description provided for @editorStickerCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t make that sticker just yet. Try another photo.'**
  String get editorStickerCreateFailed;

  /// No description provided for @editorStickerSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save that sticker yet. Please try again.'**
  String get editorStickerSaveFailed;

  /// No description provided for @editorExportSaved.
  ///
  /// In en, this message translates to:
  /// **'Your remix is in the library and ready for the next step.'**
  String get editorExportSaved;

  /// No description provided for @editorExportWarning.
  ///
  /// In en, this message translates to:
  /// **'{warning} The remix is still saved and ready to keep going.'**
  String editorExportWarning(String warning);

  /// No description provided for @editorExportGenericFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save that remix yet. Your edit choices are still here.'**
  String get editorExportGenericFailed;

  /// No description provided for @editorExportSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t finish saving that remix yet. Try again in a moment.'**
  String get editorExportSaveFailed;

  /// No description provided for @editorExportTimeoutFailed.
  ///
  /// In en, this message translates to:
  /// **'That export took too long, so we stopped it. Your edit choices are still here.'**
  String get editorExportTimeoutFailed;

  /// No description provided for @editorExportInProgress.
  ///
  /// In en, this message translates to:
  /// **'Finish exporting before leaving this screen.'**
  String get editorExportInProgress;

  /// No description provided for @editorExportProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Saving remix'**
  String get editorExportProgressTitle;

  /// No description provided for @editorExportProgressArTitle.
  ///
  /// In en, this message translates to:
  /// **'Applying face filter'**
  String get editorExportProgressArTitle;

  /// No description provided for @editorExportProgressDetail.
  ///
  /// In en, this message translates to:
  /// **'Keep this screen open while Tubestr saves your remix.'**
  String get editorExportProgressDetail;

  /// No description provided for @editorExportProgressArDetail.
  ///
  /// In en, this message translates to:
  /// **'Face filters can take a little longer to bake into the video.'**
  String get editorExportProgressArDetail;

  /// No description provided for @editorExportProgressLongDetail.
  ///
  /// In en, this message translates to:
  /// **'Still working. Larger clips and face filters can take another moment.'**
  String get editorExportProgressLongDetail;

  /// No description provided for @editorShareNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'This remix still needs a parent review before it can be shared.'**
  String get editorShareNeedsReview;

  /// No description provided for @editorShareUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t upload that remix to the family media server yet. Check your connection and try again.'**
  String get editorShareUploadFailed;

  /// No description provided for @editorShareConnectFamily.
  ///
  /// In en, this message translates to:
  /// **'Connect with a family space first, then try sharing this remix again.'**
  String get editorShareConnectFamily;

  /// No description provided for @editorShareFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t share that remix yet. It\'s still saved safely in your library.'**
  String get editorShareFailed;

  /// No description provided for @editorSharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing to {count, plural, =1{# family space} other{# family spaces}}...'**
  String editorSharing(int count);

  /// No description provided for @playerDownloadNow.
  ///
  /// In en, this message translates to:
  /// **'Download Now'**
  String get playerDownloadNow;

  /// No description provided for @playerRepairDownload.
  ///
  /// In en, this message translates to:
  /// **'Repair Download'**
  String get playerRepairDownload;

  /// No description provided for @playerDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get playerDownloading;

  /// No description provided for @playerSharedDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Shared video downloaded'**
  String get playerSharedDownloaded;

  /// No description provided for @playerReportDelivered.
  ///
  /// In en, this message translates to:
  /// **'Report delivered'**
  String get playerReportDelivered;

  /// No description provided for @playerReportSaved.
  ///
  /// In en, this message translates to:
  /// **'Report saved ({status})'**
  String playerReportSaved(String status);

  /// No description provided for @playerHideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get playerHideDetails;

  /// No description provided for @playerShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get playerShowDetails;

  /// No description provided for @playerReact.
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get playerReact;

  /// No description provided for @playerMyClip.
  ///
  /// In en, this message translates to:
  /// **'My clip'**
  String get playerMyClip;

  /// No description provided for @playerFamilyShare.
  ///
  /// In en, this message translates to:
  /// **'Family share'**
  String get playerFamilyShare;

  /// No description provided for @playerRemoteMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'This video isn\'t here yet'**
  String get playerRemoteMissingTitle;

  /// No description provided for @playerRemotePreparingTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting your video ready'**
  String get playerRemotePreparingTitle;

  /// No description provided for @playerRemoteFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s try that download again'**
  String get playerRemoteFailedTitle;

  /// No description provided for @playerRemoteReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family video ready to watch'**
  String get playerRemoteReadyTitle;

  /// No description provided for @playerRemotePreparingDetail.
  ///
  /// In en, this message translates to:
  /// **'This clip is still getting ready on this device.'**
  String get playerRemotePreparingDetail;

  /// No description provided for @playerRemoteCheckingDetail.
  ///
  /// In en, this message translates to:
  /// **'Checking the saved copy so playback stays smooth and safe.'**
  String get playerRemoteCheckingDetail;

  /// No description provided for @playerRemoteReadyDetail.
  ///
  /// In en, this message translates to:
  /// **'Download this family clip and press play when it is ready.'**
  String get playerRemoteReadyDetail;

  /// No description provided for @playerDownloadConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t download that clip right now. Check your connection and try again.'**
  String get playerDownloadConnectionFailed;

  /// No description provided for @playerDownloadVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'The saved copy needs another pass. Try the download again in a moment.'**
  String get playerDownloadVerificationFailed;

  /// No description provided for @playerDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t download that clip yet. Please try again.'**
  String get playerDownloadFailed;

  /// No description provided for @playerShareNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'This clip still needs a parent review before it can be shared.'**
  String get playerShareNeedsReview;

  /// No description provided for @playerShareUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t upload that clip to the family media server yet. Check your connection and try again.'**
  String get playerShareUploadFailed;

  /// No description provided for @playerShareConnectFamily.
  ///
  /// In en, this message translates to:
  /// **'Connect with a family space first, then try sharing again.'**
  String get playerShareConnectFamily;

  /// No description provided for @playerShareFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t share that clip yet. It\'s still saved safely here.'**
  String get playerShareFailed;

  /// No description provided for @playerReportFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send that report just yet. Your note is still on this device, so please try again.'**
  String get playerReportFailed;

  /// No description provided for @playerLikeFailed.
  ///
  /// In en, this message translates to:
  /// **'That like didn\'t go through yet. Please try again in a moment.'**
  String get playerLikeFailed;

  /// No description provided for @playerReactionFailed.
  ///
  /// In en, this message translates to:
  /// **'That reaction didn\'t go through yet. Please try again in a moment.'**
  String get playerReactionFailed;

  /// No description provided for @playerSharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing \"{title}\" to {count, plural, =1{# family space} other{# family spaces}}...'**
  String playerSharing(String title, int count);

  /// No description provided for @playerWatchingSoFar.
  ///
  /// In en, this message translates to:
  /// **'Watching so far'**
  String get playerWatchingSoFar;

  /// No description provided for @playerWatchingSoFarDevice.
  ///
  /// In en, this message translates to:
  /// **'Watching so far on this device'**
  String get playerWatchingSoFarDevice;

  /// No description provided for @playerPlayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# Play} other{# Plays}}'**
  String playerPlayCount(int count);

  /// No description provided for @playerCompletion.
  ///
  /// In en, this message translates to:
  /// **'{value}% Completion'**
  String playerCompletion(int value);

  /// No description provided for @playerReplays.
  ///
  /// In en, this message translates to:
  /// **'{value}% Replays'**
  String playerReplays(int value);

  /// No description provided for @playerNoLikes.
  ///
  /// In en, this message translates to:
  /// **'No likes yet'**
  String get playerNoLikes;

  /// No description provided for @playerLikeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# Like} other{# Likes}}'**
  String playerLikeCount(int count);

  /// No description provided for @playerAFamily.
  ///
  /// In en, this message translates to:
  /// **'A family'**
  String get playerAFamily;

  /// No description provided for @playerMoreLikes.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String playerMoreLikes(int count);

  /// No description provided for @playerReactions.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get playerReactions;

  /// No description provided for @parentZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent Zone'**
  String get parentZoneTitle;

  /// No description provided for @parentSectionDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get parentSectionDashboard;

  /// No description provided for @parentSectionChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get parentSectionChildren;

  /// No description provided for @parentSectionFamily.
  ///
  /// In en, this message translates to:
  /// **'Family Spaces'**
  String get parentSectionFamily;

  /// No description provided for @parentSectionActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get parentSectionActivity;

  /// No description provided for @parentSectionNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get parentSectionNetwork;

  /// No description provided for @parentSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get parentSectionAccount;

  /// No description provided for @parentSectionDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get parentSectionDiagnostics;

  /// No description provided for @parentStartHere.
  ///
  /// In en, this message translates to:
  /// **'Start Here'**
  String get parentStartHere;

  /// No description provided for @parentControlRoom.
  ///
  /// In en, this message translates to:
  /// **'Control Room'**
  String get parentControlRoom;

  /// No description provided for @parentOpenSections.
  ///
  /// In en, this message translates to:
  /// **'Open sections'**
  String get parentOpenSections;

  /// No description provided for @parentPinIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get parentPinIncorrect;

  /// No description provided for @parentPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs must match (4 digits)'**
  String get parentPinMismatch;

  /// No description provided for @parentCreatePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Parent PIN'**
  String get parentCreatePinTitle;

  /// No description provided for @parentUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Parent Zone'**
  String get parentUnlockTitle;

  /// No description provided for @parentPinCreateDetail.
  ///
  /// In en, this message translates to:
  /// **'Set a four-digit code so family controls stay separate from the kid-facing app.'**
  String get parentPinCreateDetail;

  /// No description provided for @parentPinUpdateLater.
  ///
  /// In en, this message translates to:
  /// **'You can update this later in Settings.'**
  String get parentPinUpdateLater;

  /// No description provided for @parentPinNew.
  ///
  /// In en, this message translates to:
  /// **'New PIN (4 digits)'**
  String get parentPinNew;

  /// No description provided for @parentPinConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get parentPinConfirm;

  /// No description provided for @parentPinSave.
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get parentPinSave;

  /// No description provided for @parentPinUpdated.
  ///
  /// In en, this message translates to:
  /// **'PIN updated'**
  String get parentPinUpdated;

  /// No description provided for @parentDisplayNameSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved display name'**
  String get parentDisplayNameSaved;

  /// No description provided for @parentProfilePublished.
  ///
  /// In en, this message translates to:
  /// **'Published parent profile'**
  String get parentProfilePublished;

  /// No description provided for @parentProfilePublishFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t publish your parent profile just yet. Please try again.'**
  String get parentProfilePublishFailed;

  /// No description provided for @parentJoinedFamily.
  ///
  /// In en, this message translates to:
  /// **'Joined {name}'**
  String parentJoinedFamily(String name);

  /// No description provided for @parentAlreadyConnected.
  ///
  /// In en, this message translates to:
  /// **'You\'re already connected.'**
  String get parentAlreadyConnected;

  /// No description provided for @parentAlreadyConnectedGroup.
  ///
  /// In en, this message translates to:
  /// **'You\'re already connected in {groupName}.'**
  String parentAlreadyConnectedGroup(String groupName);

  /// No description provided for @parentConnectionAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'Connection already sent. They can approve it in Parent Zone.'**
  String get parentConnectionAlreadySent;

  /// No description provided for @parentConnectionAlreadySentGroup.
  ///
  /// In en, this message translates to:
  /// **'Connection already sent for {groupName}. They can approve it in Parent Zone.'**
  String parentConnectionAlreadySentGroup(String groupName);

  /// No description provided for @parentConnectionSent.
  ///
  /// In en, this message translates to:
  /// **'Connection sent. They can approve it in Parent Zone.'**
  String get parentConnectionSent;

  /// No description provided for @parentGroupCreated.
  ///
  /// In en, this message translates to:
  /// **'Group created.'**
  String get parentGroupCreated;

  /// No description provided for @parentJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t finish joining that family space yet. Please try again.'**
  String get parentJoinFailed;

  /// No description provided for @parentCreateInviteFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t create an invite just yet. Please try again.'**
  String get parentCreateInviteFailed;

  /// No description provided for @parentInviteUseFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t use that invite yet. Double-check it and try again.'**
  String get parentInviteUseFailed;

  /// No description provided for @parentInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Invite Code'**
  String get parentInviteTitle;

  /// No description provided for @parentInviteScanInstructions.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a family invite QR code.'**
  String get parentInviteScanInstructions;

  /// No description provided for @parentInviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Tubestr Family Invite\n\nOpen this link on the other parent\'s device:\n{payload}'**
  String parentInviteShareText(String payload);

  /// No description provided for @parentShareLink.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get parentShareLink;

  /// No description provided for @parentCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get parentCopyCode;

  /// No description provided for @parentOpenFamilySpace.
  ///
  /// In en, this message translates to:
  /// **'Open A Family Space'**
  String get parentOpenFamilySpace;

  /// No description provided for @parentOpenFamilySpaceDetail.
  ///
  /// In en, this message translates to:
  /// **'Share one invite code, then come back here when the other parent sends their welcome.'**
  String get parentOpenFamilySpaceDetail;

  /// No description provided for @parentCreateInvite.
  ///
  /// In en, this message translates to:
  /// **'Create invite'**
  String get parentCreateInvite;

  /// No description provided for @parentCreateInviteDetail.
  ///
  /// In en, this message translates to:
  /// **'Show a QR code or send a shareable invite link'**
  String get parentCreateInviteDetail;

  /// No description provided for @parentScanInvite.
  ///
  /// In en, this message translates to:
  /// **'Scan invite'**
  String get parentScanInvite;

  /// No description provided for @parentScanInviteDetail.
  ///
  /// In en, this message translates to:
  /// **'Join the shared family space in one step'**
  String get parentScanInviteDetail;

  /// No description provided for @parentPasteInvite.
  ///
  /// In en, this message translates to:
  /// **'Paste invite'**
  String get parentPasteInvite;

  /// No description provided for @parentPasteInviteDetail.
  ///
  /// In en, this message translates to:
  /// **'Enter an invite link or code manually'**
  String get parentPasteInviteDetail;

  /// No description provided for @parentPasteInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste Invite'**
  String get parentPasteInviteTitle;

  /// No description provided for @parentPasteInvitePrompt.
  ///
  /// In en, this message translates to:
  /// **'Paste an invite link or code from another parent.'**
  String get parentPasteInvitePrompt;

  /// No description provided for @parentInviteInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite link or code'**
  String get parentInviteInputLabel;

  /// No description provided for @parentUseInvite.
  ///
  /// In en, this message translates to:
  /// **'Use invite'**
  String get parentUseInvite;

  /// No description provided for @parentJoiningFamily.
  ///
  /// In en, this message translates to:
  /// **'Joining family…'**
  String get parentJoiningFamily;

  /// No description provided for @parentFamilyConnectionsFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not load family connections right now.'**
  String get parentFamilyConnectionsFailed;

  /// No description provided for @parentNoFamiliesTitle.
  ///
  /// In en, this message translates to:
  /// **'No trusted families yet'**
  String get parentNoFamiliesTitle;

  /// No description provided for @parentNoFamiliesDetail.
  ///
  /// In en, this message translates to:
  /// **'Create an invite or scan one from another parent to open your first family space.'**
  String get parentNoFamiliesDetail;

  /// No description provided for @parentPendingWelcomes.
  ///
  /// In en, this message translates to:
  /// **'Pending Welcomes'**
  String get parentPendingWelcomes;

  /// No description provided for @parentActiveFamilySpaces.
  ///
  /// In en, this message translates to:
  /// **'Active Family Spaces'**
  String get parentActiveFamilySpaces;

  /// No description provided for @parentManageConnection.
  ///
  /// In en, this message translates to:
  /// **'Manage connection'**
  String get parentManageConnection;

  /// No description provided for @parentFamilySpaceFallback.
  ///
  /// In en, this message translates to:
  /// **'Family Space'**
  String get parentFamilySpaceFallback;

  /// No description provided for @parentFamilyFallback.
  ///
  /// In en, this message translates to:
  /// **'{name} Family'**
  String parentFamilyFallback(String name);

  /// No description provided for @parentMembers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# member} other{# members}}'**
  String parentMembers(int count);

  /// No description provided for @parentConnectionHealth.
  ///
  /// In en, this message translates to:
  /// **'Connection Health'**
  String get parentConnectionHealth;

  /// No description provided for @parentConnectionHealthy.
  ///
  /// In en, this message translates to:
  /// **'Sharing and reporting are connected right now.'**
  String get parentConnectionHealthy;

  /// No description provided for @parentConnectionWaiting.
  ///
  /// In en, this message translates to:
  /// **'Some actions are waiting for a relay connection before they can finish.'**
  String get parentConnectionWaiting;

  /// No description provided for @parentEverythingSynced.
  ///
  /// In en, this message translates to:
  /// **'Everything has synced'**
  String get parentEverythingSynced;

  /// No description provided for @parentQueuedActions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# queued action} other{# queued actions}}'**
  String parentQueuedActions(int count);

  /// No description provided for @parentNoRetriesNeeded.
  ///
  /// In en, this message translates to:
  /// **'No retries needed.'**
  String get parentNoRetriesNeeded;

  /// No description provided for @parentRelayAccess.
  ///
  /// In en, this message translates to:
  /// **'Relay Access'**
  String get parentRelayAccess;

  /// No description provided for @parentRelayAccessDetail.
  ///
  /// In en, this message translates to:
  /// **'These relay addresses carry invites, reports, and family updates. Changes here also publish to other Nostr clients that use your key.'**
  String get parentRelayAccessDetail;

  /// No description provided for @parentNoCustomRelays.
  ///
  /// In en, this message translates to:
  /// **'No custom relays saved yet.'**
  String get parentNoCustomRelays;

  /// No description provided for @parentRelayInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Add relay URL'**
  String get parentRelayInputLabel;

  /// No description provided for @parentRelaySave.
  ///
  /// In en, this message translates to:
  /// **'Save relays'**
  String get parentRelaySave;

  /// No description provided for @parentReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get parentReconnect;

  /// No description provided for @parentUseDefaults.
  ///
  /// In en, this message translates to:
  /// **'Use defaults'**
  String get parentUseDefaults;

  /// No description provided for @parentRelaysReconnected.
  ///
  /// In en, this message translates to:
  /// **'Relays reconnected'**
  String get parentRelaysReconnected;

  /// No description provided for @parentLastPublished.
  ///
  /// In en, this message translates to:
  /// **'Last published {time}'**
  String parentLastPublished(String time);

  /// No description provided for @parentMediaServers.
  ///
  /// In en, this message translates to:
  /// **'Media Servers'**
  String get parentMediaServers;

  /// No description provided for @parentMediaServersDetail.
  ///
  /// In en, this message translates to:
  /// **'Choose where encrypted media uploads can live for family delivery. Saves publish automatically so other devices and clients stay in sync.'**
  String get parentMediaServersDetail;

  /// No description provided for @parentBlossomInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Blossom server'**
  String get parentBlossomInputLabel;

  /// No description provided for @parentServersSave.
  ///
  /// In en, this message translates to:
  /// **'Save servers'**
  String get parentServersSave;

  /// No description provided for @parentSafetyHq.
  ///
  /// In en, this message translates to:
  /// **'Safety HQ'**
  String get parentSafetyHq;

  /// No description provided for @parentSafetyHqDetail.
  ///
  /// In en, this message translates to:
  /// **'Keep higher-risk reports separate from the main family thread and deliver them to Tubestr moderation once Safety HQ is connected.'**
  String get parentSafetyHqDetail;

  /// No description provided for @parentSafetyHqRefreshPending.
  ///
  /// In en, this message translates to:
  /// **'Safety HQ needs another moment to refresh.'**
  String get parentSafetyHqRefreshPending;

  /// No description provided for @parentSafetyHqRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh Safety HQ'**
  String get parentSafetyHqRefresh;

  /// No description provided for @parentSafetyHqCheck.
  ///
  /// In en, this message translates to:
  /// **'Check Safety HQ'**
  String get parentSafetyHqCheck;

  /// No description provided for @parentSafetyHqSetup.
  ///
  /// In en, this message translates to:
  /// **'Set Up Safety HQ'**
  String get parentSafetyHqSetup;

  /// No description provided for @parentSafetyHqReady.
  ///
  /// In en, this message translates to:
  /// **'Safety HQ is connected and ready.'**
  String get parentSafetyHqReady;

  /// No description provided for @parentSafetyHqConnectingStarted.
  ///
  /// In en, this message translates to:
  /// **'Safety HQ is connecting. We sent the setup welcome to the moderation service.'**
  String get parentSafetyHqConnectingStarted;

  /// No description provided for @parentSafetyHqStillConnecting.
  ///
  /// In en, this message translates to:
  /// **'Safety HQ is still connecting. Leave the app online for a moment and check again.'**
  String get parentSafetyHqStillConnecting;

  /// No description provided for @parentSafetySetupFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t set up Safety HQ yet. Please try again.'**
  String get parentSafetySetupFailed;

  /// No description provided for @parentHowSafetyWorks.
  ///
  /// In en, this message translates to:
  /// **'How Safety Reporting Works'**
  String get parentHowSafetyWorks;

  /// No description provided for @parentSafetyWorksDetail.
  ///
  /// In en, this message translates to:
  /// **'Parents can verify what stays private, what reaches the other family, and where media abuse reports are sent.'**
  String get parentSafetyWorksDetail;

  /// No description provided for @parentSafetyLevelOneTitle.
  ///
  /// In en, this message translates to:
  /// **'Level 1 stays here'**
  String get parentSafetyLevelOneTitle;

  /// No description provided for @parentSafetyLevelOneDetail.
  ///
  /// In en, this message translates to:
  /// **'Gentle feedback stays on this device so a child can talk with a grown-up later.'**
  String get parentSafetyLevelOneDetail;

  /// No description provided for @parentSafetyLevelTwoTitle.
  ///
  /// In en, this message translates to:
  /// **'Level 2 alerts the parent on this device'**
  String get parentSafetyLevelTwoTitle;

  /// No description provided for @parentSafetyLevelTwoDetail.
  ///
  /// In en, this message translates to:
  /// **'Stronger concerns stay private to this family and show up in Parent Zone only.'**
  String get parentSafetyLevelTwoDetail;

  /// No description provided for @parentSafetyLevelThreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Level 3 alerts both families'**
  String get parentSafetyLevelThreeTitle;

  /// No description provided for @parentSafetyLevelThreeDetail.
  ///
  /// In en, this message translates to:
  /// **'The family group gets the report first. Safety HQ keeps a separate copy when it has been set up.'**
  String get parentSafetyLevelThreeDetail;

  /// No description provided for @parentSafetyBud09Title.
  ///
  /// In en, this message translates to:
  /// **'BUD-09 abuse signals are best effort'**
  String get parentSafetyBud09Title;

  /// No description provided for @parentSafetyBud09Detail.
  ///
  /// In en, this message translates to:
  /// **'If a parent deletes a shared video, Tubestr also asks the media servers to flag that blob, but the in-app moderation state remains the source of truth.'**
  String get parentSafetyBud09Detail;

  /// No description provided for @parentStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String parentStatus(String status);

  /// No description provided for @parentStatusLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'{detail} Last updated {time}'**
  String parentStatusLastUpdated(String detail, String time);

  /// No description provided for @parentLocalGroupId.
  ///
  /// In en, this message translates to:
  /// **'Local group ID'**
  String get parentLocalGroupId;

  /// No description provided for @parentJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get parentJustNow;

  /// No description provided for @parentMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# minute ago} other{# minutes ago}}'**
  String parentMinutesAgo(int count);

  /// No description provided for @parentHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# hour ago} other{# hours ago}}'**
  String parentHoursAgo(int count);

  /// No description provided for @parentDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# day ago} other{# days ago}}'**
  String parentDaysAgo(int count);

  /// No description provided for @parentChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get parentChildrenTitle;

  /// No description provided for @parentChildrenDetail.
  ///
  /// In en, this message translates to:
  /// **'Each child keeps a theme and local profile for capture, editing, and playback.'**
  String get parentChildrenDetail;

  /// No description provided for @parentAddChildPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add a child profile below so the app has someone to capture and edit for.'**
  String get parentAddChildPrompt;

  /// No description provided for @parentAddChildProfile.
  ///
  /// In en, this message translates to:
  /// **'Add Child Profile'**
  String get parentAddChildProfile;

  /// No description provided for @parentChildName.
  ///
  /// In en, this message translates to:
  /// **'Child name'**
  String get parentChildName;

  /// No description provided for @parentChooseChildTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose a name and theme so capture and editing stay personalized.'**
  String get parentChooseChildTheme;

  /// No description provided for @parentSaveChild.
  ///
  /// In en, this message translates to:
  /// **'Save child'**
  String get parentSaveChild;

  /// No description provided for @parentApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Approvals & Scanning'**
  String get parentApprovalTitle;

  /// No description provided for @parentApprovalDetail.
  ///
  /// In en, this message translates to:
  /// **'Decide how much parent review happens before a clip can leave the device.'**
  String get parentApprovalDetail;

  /// No description provided for @parentRequireApproval.
  ///
  /// In en, this message translates to:
  /// **'Require parent approval before sharing'**
  String get parentRequireApproval;

  /// No description provided for @parentRequireApprovalDetail.
  ///
  /// In en, this message translates to:
  /// **'Clips are always scanned on-device. Turn this on if you also want every new clip to wait for a parent.'**
  String get parentRequireApprovalDetail;

  /// No description provided for @parentApprovalQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Approval Queue'**
  String get parentApprovalQueueTitle;

  /// No description provided for @parentApprovalWaitingScan.
  ///
  /// In en, this message translates to:
  /// **'Waiting on scan results'**
  String get parentApprovalWaitingScan;

  /// No description provided for @parentUnsafeTopic.
  ///
  /// In en, this message translates to:
  /// **'Unsafe topic'**
  String get parentUnsafeTopic;

  /// No description provided for @parentNeedsLook.
  ///
  /// In en, this message translates to:
  /// **'Needs a look'**
  String get parentNeedsLook;

  /// No description provided for @parentVeryLoud.
  ///
  /// In en, this message translates to:
  /// **'Very loud'**
  String get parentVeryLoud;

  /// No description provided for @parentLotsOfFaces.
  ///
  /// In en, this message translates to:
  /// **'Lots of faces'**
  String get parentLotsOfFaces;

  /// No description provided for @parentLongClip.
  ///
  /// In en, this message translates to:
  /// **'Long clip'**
  String get parentLongClip;

  /// No description provided for @parentIntenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Intense title'**
  String get parentIntenseTitle;

  /// No description provided for @parentAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent account'**
  String get parentAccountTitle;

  /// No description provided for @parentAccountNoIdentity.
  ///
  /// In en, this message translates to:
  /// **'Create or restore the parent account before using family tools.'**
  String get parentAccountNoIdentity;

  /// No description provided for @parentDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get parentDisplayNameLabel;

  /// No description provided for @parentDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Lee and Emma'**
  String get parentDisplayNameHint;

  /// No description provided for @parentDisplayNameDetail.
  ///
  /// In en, this message translates to:
  /// **'Choose the name other families will see when you connect or share.'**
  String get parentDisplayNameDetail;

  /// No description provided for @parentUpdatePin.
  ///
  /// In en, this message translates to:
  /// **'Update PIN'**
  String get parentUpdatePin;

  /// No description provided for @parentUpdatePinDetail.
  ///
  /// In en, this message translates to:
  /// **'Update the four-digit code that protects the parent workspace.'**
  String get parentUpdatePinDetail;

  /// No description provided for @parentNewPinLabel.
  ///
  /// In en, this message translates to:
  /// **'New 4-digit PIN'**
  String get parentNewPinLabel;

  /// No description provided for @parentPublicAddressReady.
  ///
  /// In en, this message translates to:
  /// **'Your public parent address is ready for invites and sharing.'**
  String get parentPublicAddressReady;

  /// No description provided for @parentBackupKeyDescription.
  ///
  /// In en, this message translates to:
  /// **'This is the backup key for your parent account. Keep it somewhere private and easy for you to find later.'**
  String get parentBackupKeyDescription;

  /// No description provided for @parentSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get parentSupport;

  /// No description provided for @parentPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get parentPrivacyPolicy;

  /// No description provided for @parentTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get parentTerms;

  /// No description provided for @parentSignOutReset.
  ///
  /// In en, this message translates to:
  /// **'Sign out & reset app'**
  String get parentSignOutReset;

  /// No description provided for @parentSignOutResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out & reset app?'**
  String get parentSignOutResetTitle;

  /// No description provided for @parentSignOutResetDetail.
  ///
  /// In en, this message translates to:
  /// **'This will remove the saved parent account from this device, clear the Parent Zone PIN, wipe local videos and cached shares, and clear the synced Apple-keychain copy Tubestr uses for automatic restore here. Make sure your recovery key is saved first.'**
  String get parentSignOutResetDetail;

  /// No description provided for @parentResetFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t finish resetting this device yet. Please try again.'**
  String get parentResetFailed;

  /// No description provided for @parentDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete parent account?'**
  String get parentDeleteAccountTitle;

  /// No description provided for @parentDeleteAccountDetail.
  ///
  /// In en, this message translates to:
  /// **'This removes backend account records for this parent address. Media already copied onto other approved family devices may still remain there until those recipients delete it too.'**
  String get parentDeleteAccountDetail;

  /// No description provided for @parentDeleteAccountDetailWithAddress.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes Tubestr backend account records for {address}. This also signs the device out after deletion succeeds. Any App Store or Play subscription must still be cancelled separately in Apple or Google billing settings.'**
  String parentDeleteAccountDetailWithAddress(String address);

  /// No description provided for @parentDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get parentDeleteAccount;

  /// No description provided for @parentKeepAccount.
  ///
  /// In en, this message translates to:
  /// **'Keep account'**
  String get parentKeepAccount;

  /// No description provided for @parentDeleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t delete the parent account yet. Please try again.'**
  String get parentDeleteAccountFailed;

  /// No description provided for @parentAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Parent account deleted from Tubestr backend records.'**
  String get parentAccountDeleted;

  /// No description provided for @parentDeleteChildTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {childName}?'**
  String parentDeleteChildTitle(String childName);

  /// No description provided for @parentDeleteChildFallback.
  ///
  /// In en, this message translates to:
  /// **'this child profile'**
  String get parentDeleteChildFallback;

  /// No description provided for @parentDeleteChildDetail.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove the child profile and delete any videos and media stored on behalf of this profile from Tubestr-managed servers. Clips already delivered to other family members remain on their devices.\n\nThis cannot be undone.'**
  String get parentDeleteChildDetail;

  /// No description provided for @parentDeleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get parentDeleteProfile;

  /// No description provided for @parentChildDeleted.
  ///
  /// In en, this message translates to:
  /// **'{childName} removed from Tubestr servers.'**
  String parentChildDeleted(String childName);

  /// No description provided for @parentChildDeletePartial.
  ///
  /// In en, this message translates to:
  /// **'We could not finish deleting {childName} yet because {count, plural, =1{# file could not be removed} other{# files could not be removed}} from Tubestr servers. Try again when the connection is stable.'**
  String parentChildDeletePartial(String childName, int count);

  /// No description provided for @parentNoQueuedActions.
  ///
  /// In en, this message translates to:
  /// **'No queued actions to retry'**
  String get parentNoQueuedActions;

  /// No description provided for @parentQueuedActionsStillWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# action still waiting — check your connection} other{# actions still waiting — check your connection}}'**
  String parentQueuedActionsStillWaiting(int count);

  /// No description provided for @parentQueuedActionsSent.
  ///
  /// In en, this message translates to:
  /// **'Sent {flushed} of {total, plural, =1{# queued action} other{# queued actions}}'**
  String parentQueuedActionsSent(int flushed, int total);

  /// No description provided for @parentSharedVideoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {title} for this family'**
  String parentSharedVideoDeleted(String title);

  /// No description provided for @parentDeleteSharedVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t delete that shared video just yet. Please try again.'**
  String get parentDeleteSharedVideoFailed;

  /// No description provided for @parentMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed member from family group'**
  String get parentMemberRemoved;

  /// No description provided for @parentRemoveMemberFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t remove that member just yet. Please try again.'**
  String get parentRemoveMemberFailed;

  /// No description provided for @parentMemberPromoted.
  ///
  /// In en, this message translates to:
  /// **'Promoted member to admin'**
  String get parentMemberPromoted;

  /// No description provided for @parentPromoteMemberFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t promote that member just yet. Please try again.'**
  String get parentPromoteMemberFailed;

  /// No description provided for @parentLeaveFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this family space?'**
  String get parentLeaveFamilyTitle;

  /// No description provided for @parentLeaveFamilySolo.
  ///
  /// In en, this message translates to:
  /// **'You are the only member. Leaving abandons the group — nobody else can receive new shares here.'**
  String get parentLeaveFamilySolo;

  /// No description provided for @parentLeaveFamilyAdmin.
  ///
  /// In en, this message translates to:
  /// **'You\'ll step down as admin and leave \"{groupName}\". You will stop receiving new shares from this family and will no longer be able to send to it. Past clips already stay on your device.'**
  String parentLeaveFamilyAdmin(String groupName);

  /// No description provided for @parentLeaveFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'You will leave \"{groupName}\". You will stop receiving new shares from this family and will no longer be able to send to it. Past clips already stay on your device.'**
  String parentLeaveFamilyMember(String groupName);

  /// No description provided for @parentLeaveFamilyLastAdmin.
  ///
  /// In en, this message translates to:
  /// **'You\'re the only admin. Use Make admin on another member above, then try again.'**
  String get parentLeaveFamilyLastAdmin;

  /// No description provided for @parentLeaveFamilyFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t leave that family space just yet. Please try again.'**
  String get parentLeaveFamilyFailed;

  /// No description provided for @parentLeftFamily.
  ///
  /// In en, this message translates to:
  /// **'Left {groupName}'**
  String parentLeftFamily(String groupName);

  /// No description provided for @parentLeaveFamilyAdminGuidance.
  ///
  /// In en, this message translates to:
  /// **'You\'ll self-demote, then publish a leave request. Another member commits the removal when they come online.'**
  String get parentLeaveFamilyAdminGuidance;

  /// No description provided for @parentLeaveFamilyMemberGuidance.
  ///
  /// In en, this message translates to:
  /// **'You\'ll publish a leave request. Another member commits the removal when they come online; new shares stop arriving in this space.'**
  String get parentLeaveFamilyMemberGuidance;

  /// No description provided for @parentMakeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get parentMakeAdmin;

  /// No description provided for @parentWorking.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get parentWorking;

  /// No description provided for @parentSharedVideos.
  ///
  /// In en, this message translates to:
  /// **'Shared Videos'**
  String get parentSharedVideos;

  /// No description provided for @parentCurrentParentIdentity.
  ///
  /// In en, this message translates to:
  /// **'Current parent identity'**
  String get parentCurrentParentIdentity;

  /// No description provided for @parentYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get parentYou;

  /// No description provided for @parentAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get parentAdmin;

  /// No description provided for @parentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get parentDeleted;

  /// No description provided for @parentDiagnosticsCurrentState.
  ///
  /// In en, this message translates to:
  /// **'Current State'**
  String get parentDiagnosticsCurrentState;

  /// No description provided for @parentDiagnosticsActiveSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Active Subscriptions'**
  String get parentDiagnosticsActiveSubscriptions;

  /// No description provided for @parentDiagnosticsAppBuild.
  ///
  /// In en, this message translates to:
  /// **'App Build'**
  String get parentDiagnosticsAppBuild;

  /// No description provided for @parentDiagnosticsRefreshSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Refresh subscriptions'**
  String get parentDiagnosticsRefreshSubscriptions;

  /// No description provided for @parentDiagnosticsCopyDebugDump.
  ///
  /// In en, this message translates to:
  /// **'Copy debug dump'**
  String get parentDiagnosticsCopyDebugDump;

  /// No description provided for @parentDiagnosticsRefreshPage.
  ///
  /// In en, this message translates to:
  /// **'Refresh page'**
  String get parentDiagnosticsRefreshPage;

  /// No description provided for @parentDiagnosticsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied relay sync diagnostics'**
  String get parentDiagnosticsCopied;

  /// No description provided for @parentDiagnosticsVersionLoading.
  ///
  /// In en, this message translates to:
  /// **'Version and build number are loading.'**
  String get parentDiagnosticsVersionLoading;

  /// No description provided for @parentDiagnosticsBuildUnavailable.
  ///
  /// In en, this message translates to:
  /// **'App build unavailable'**
  String get parentDiagnosticsBuildUnavailable;

  /// No description provided for @parentDiagnosticsBuildUnavailableDetail.
  ///
  /// In en, this message translates to:
  /// **'This platform did not return version and build metadata.'**
  String get parentDiagnosticsBuildUnavailableDetail;

  /// No description provided for @parentDiagnosticsVersionBuild.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · Build {buildNumber}'**
  String parentDiagnosticsVersionBuild(String version, String buildNumber);

  /// No description provided for @parentDiagnosticsUnknownVersion.
  ///
  /// In en, this message translates to:
  /// **'unknown version'**
  String get parentDiagnosticsUnknownVersion;

  /// No description provided for @parentDiagnosticsUnknownBuild.
  ///
  /// In en, this message translates to:
  /// **'unknown build'**
  String get parentDiagnosticsUnknownBuild;

  /// No description provided for @parentDiagnosticsNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'has not completed yet'**
  String get parentDiagnosticsNotCompleted;

  /// No description provided for @parentDiagnosticsCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed {value}'**
  String parentDiagnosticsCompleted(String value);

  /// No description provided for @parentDiagnosticsShares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get parentDiagnosticsShares;

  /// No description provided for @parentDiagnosticsDeliveryIssues.
  ///
  /// In en, this message translates to:
  /// **'Delivery Issues'**
  String get parentDiagnosticsDeliveryIssues;

  /// No description provided for @parentDiagnosticsRecentHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent History'**
  String get parentDiagnosticsRecentHistory;

  /// No description provided for @parentDiagnosticsNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No control-plane activity captured yet.'**
  String get parentDiagnosticsNoHistory;

  /// No description provided for @parentDiagnosticsClear.
  ///
  /// In en, this message translates to:
  /// **'Shares, reports, and remote downloads look clear from this device.'**
  String get parentDiagnosticsClear;

  /// No description provided for @parentActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'When you share with another family, the latest deliveries will appear here.'**
  String get parentActivityEmpty;

  /// No description provided for @parentReportGentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle feedback from another family.'**
  String get parentReportGentle;

  /// No description provided for @parentReportConcern.
  ///
  /// In en, this message translates to:
  /// **'A concern from another family needs a look.'**
  String get parentReportConcern;

  /// No description provided for @parentReportSafetyHq.
  ///
  /// In en, this message translates to:
  /// **'A serious concern was escalated to Safety HQ.'**
  String get parentReportSafetyHq;

  /// No description provided for @parentReportFamily.
  ///
  /// In en, this message translates to:
  /// **'A concern was shared with both families.'**
  String get parentReportFamily;

  /// No description provided for @parentDestinationDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'Device only'**
  String get parentDestinationDeviceOnly;

  /// No description provided for @parentDestinationParentOnly.
  ///
  /// In en, this message translates to:
  /// **'Parent only'**
  String get parentDestinationParentOnly;

  /// No description provided for @parentDestinationBothFamilies.
  ///
  /// In en, this message translates to:
  /// **'Both families'**
  String get parentDestinationBothFamilies;

  /// No description provided for @parentDestinationFamilyGroup.
  ///
  /// In en, this message translates to:
  /// **'Family group'**
  String get parentDestinationFamilyGroup;

  /// No description provided for @parentDestinationParentHelpers.
  ///
  /// In en, this message translates to:
  /// **'Parent helpers'**
  String get parentDestinationParentHelpers;

  /// No description provided for @parentAuditRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Removed a family member'**
  String get parentAuditRemoveMember;

  /// No description provided for @parentAuditDeleteVideo.
  ///
  /// In en, this message translates to:
  /// **'Deleted shared video'**
  String get parentAuditDeleteVideo;

  /// No description provided for @launchQueuedShares.
  ///
  /// In en, this message translates to:
  /// **'Queued shares'**
  String get launchQueuedShares;

  /// No description provided for @launchQueuedLikes.
  ///
  /// In en, this message translates to:
  /// **'Queued likes'**
  String get launchQueuedLikes;

  /// No description provided for @launchQueuedReactions.
  ///
  /// In en, this message translates to:
  /// **'Queued reactions'**
  String get launchQueuedReactions;

  /// No description provided for @launchQueuedReports.
  ///
  /// In en, this message translates to:
  /// **'Queued reports'**
  String get launchQueuedReports;

  /// No description provided for @launchQueuedProfileUpdates.
  ///
  /// In en, this message translates to:
  /// **'Queued profile updates'**
  String get launchQueuedProfileUpdates;

  /// No description provided for @launchQueuedRelayUpdates.
  ///
  /// In en, this message translates to:
  /// **'Queued relay list updates'**
  String get launchQueuedRelayUpdates;

  /// No description provided for @launchQueuedMediaServerUpdates.
  ///
  /// In en, this message translates to:
  /// **'Queued media server updates'**
  String get launchQueuedMediaServerUpdates;

  /// No description provided for @launchQueuedMuteUpdates.
  ///
  /// In en, this message translates to:
  /// **'Queued mute list updates'**
  String get launchQueuedMuteUpdates;

  /// No description provided for @launchDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get launchDelivered;

  /// No description provided for @launchWaitingRetry.
  ///
  /// In en, this message translates to:
  /// **'Waiting for retry'**
  String get launchWaitingRetry;

  /// No description provided for @launchWaitingSafety.
  ///
  /// In en, this message translates to:
  /// **'Waiting on Safety HQ copy'**
  String get launchWaitingSafety;

  /// No description provided for @launchWaitingConnection.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection'**
  String get launchWaitingConnection;

  /// No description provided for @launchWaitingMediaReference.
  ///
  /// In en, this message translates to:
  /// **'Waiting for encrypted media reference'**
  String get launchWaitingMediaReference;

  /// No description provided for @launchDeliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Delivery failed'**
  String get launchDeliveryFailed;

  /// No description provided for @launchDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Retry when the connection is stable.'**
  String get launchDownloadFailed;

  /// No description provided for @launchDownloadRelayFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed because the relay or media server was unreachable.'**
  String get launchDownloadRelayFailed;

  /// No description provided for @launchDownloadUnlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed while unlocking the encrypted video package.'**
  String get launchDownloadUnlockFailed;

  /// No description provided for @launchDownloadVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed because the saved copy did not pass verification.'**
  String get launchDownloadVerifyFailed;

  /// No description provided for @launchDownloadMetadataFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed because the shared clip metadata was incomplete.'**
  String get launchDownloadMetadataFailed;

  /// No description provided for @launchDownloadGenericFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Retry to fetch a fresh encrypted copy.'**
  String get launchDownloadGenericFailed;

  /// No description provided for @safetyHqProvisioned.
  ///
  /// In en, this message translates to:
  /// **'Provisioned'**
  String get safetyHqProvisioned;

  /// No description provided for @safetyHqConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get safetyHqConnecting;

  /// No description provided for @safetyHqQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get safetyHqQueued;

  /// No description provided for @safetyHqNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get safetyHqNotConfigured;

  /// No description provided for @safetyHqProvisionedDetail.
  ///
  /// In en, this message translates to:
  /// **'Safety HQ is provisioned and ready to receive higher-risk family alerts.'**
  String get safetyHqProvisionedDetail;

  /// No description provided for @safetyHqConnectingDetail.
  ///
  /// In en, this message translates to:
  /// **'Tubestr has already sent the setup welcome. This turns ready once the moderation service joins the group over the relay network.'**
  String get safetyHqConnectingDetail;

  /// No description provided for @safetyHqQueuedDetail.
  ///
  /// In en, this message translates to:
  /// **'Safety HQ setup is queued and will start as soon as this device can reach the moderation relays.'**
  String get safetyHqQueuedDetail;

  /// No description provided for @safetyHqNotConfiguredDetail.
  ///
  /// In en, this message translates to:
  /// **'Set up Safety HQ to keep a separate copy of higher-risk family alerts in Tubestr moderation.'**
  String get safetyHqNotConfiguredDetail;

  /// No description provided for @safetyHqMissingApiUrl.
  ///
  /// In en, this message translates to:
  /// **'This build is missing the Tubestr Safety HQ API URL.'**
  String get safetyHqMissingApiUrl;

  /// No description provided for @safetyHqIncompleteBootstrap.
  ///
  /// In en, this message translates to:
  /// **'Tubestr Safety HQ bootstrap data is incomplete.'**
  String get safetyHqIncompleteBootstrap;

  /// No description provided for @editorActionExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get editorActionExport;

  /// No description provided for @editorActionExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting'**
  String get editorActionExporting;

  /// No description provided for @editorLoadTrackFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load {track}. Please try again.'**
  String editorLoadTrackFailed(String track);

  /// No description provided for @editorRemixTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} Remix'**
  String editorRemixTitle(String title);

  /// No description provided for @editorBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get editorBrightness;

  /// No description provided for @editorContrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get editorContrast;

  /// No description provided for @editorSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get editorSaturation;

  /// No description provided for @editorSharpness.
  ///
  /// In en, this message translates to:
  /// **'Sharpness'**
  String get editorSharpness;

  /// No description provided for @editorVignette.
  ///
  /// In en, this message translates to:
  /// **'Vignette'**
  String get editorVignette;

  /// No description provided for @editorTrimKeepDuration.
  ///
  /// In en, this message translates to:
  /// **'Keep: {duration}'**
  String editorTrimKeepDuration(String duration);

  /// No description provided for @editorCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get editorCategoryAll;

  /// No description provided for @editorCategoryYours.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get editorCategoryYours;

  /// No description provided for @editorCategoryOriginals.
  ///
  /// In en, this message translates to:
  /// **'Originals'**
  String get editorCategoryOriginals;

  /// No description provided for @editorCategoryFaces.
  ///
  /// In en, this message translates to:
  /// **'Faces'**
  String get editorCategoryFaces;

  /// No description provided for @editorCategoryHearts.
  ///
  /// In en, this message translates to:
  /// **'Hearts'**
  String get editorCategoryHearts;

  /// No description provided for @editorCategoryParty.
  ///
  /// In en, this message translates to:
  /// **'Party'**
  String get editorCategoryParty;

  /// No description provided for @editorCategoryAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get editorCategoryAnimals;

  /// No description provided for @editorCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get editorCategoryFood;

  /// No description provided for @editorCategorySports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get editorCategorySports;

  /// No description provided for @editorCategoryObjects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get editorCategoryObjects;

  /// No description provided for @editorCategoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get editorCategoryTravel;

  /// No description provided for @editorFilterNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get editorFilterNone;

  /// No description provided for @editorFilterVivid.
  ///
  /// In en, this message translates to:
  /// **'Vivid'**
  String get editorFilterVivid;

  /// No description provided for @editorFilterMatte.
  ///
  /// In en, this message translates to:
  /// **'Matte'**
  String get editorFilterMatte;

  /// No description provided for @editorFilterFade.
  ///
  /// In en, this message translates to:
  /// **'Fade'**
  String get editorFilterFade;

  /// No description provided for @editorFilterWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get editorFilterWarm;

  /// No description provided for @editorFilterCool.
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get editorFilterCool;

  /// No description provided for @editorFilterNoir.
  ///
  /// In en, this message translates to:
  /// **'Noir'**
  String get editorFilterNoir;

  /// No description provided for @editorNoStickersHereYet.
  ///
  /// In en, this message translates to:
  /// **'No stickers here yet'**
  String get editorNoStickersHereYet;

  /// No description provided for @editorNoMatchingStickers.
  ///
  /// In en, this message translates to:
  /// **'No matching stickers'**
  String get editorNoMatchingStickers;

  /// No description provided for @editorMusicReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get editorMusicReady;

  /// No description provided for @editorMusicDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get editorMusicDownload;

  /// No description provided for @editorMusicLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get editorMusicLoading;

  /// No description provided for @editorMusicHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get editorMusicHappy;

  /// No description provided for @editorMusicEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get editorMusicEnergy;

  /// No description provided for @editorMusicChill.
  ///
  /// In en, this message translates to:
  /// **'Chill'**
  String get editorMusicChill;

  /// No description provided for @editorMusicChiptune.
  ///
  /// In en, this message translates to:
  /// **'Chiptune'**
  String get editorMusicChiptune;

  /// No description provided for @editorMusicDramatic.
  ///
  /// In en, this message translates to:
  /// **'Dramatic'**
  String get editorMusicDramatic;

  /// No description provided for @editorMusicLoops.
  ///
  /// In en, this message translates to:
  /// **'Loops'**
  String get editorMusicLoops;

  /// No description provided for @editorNoMusicHereYet.
  ///
  /// In en, this message translates to:
  /// **'No music here yet'**
  String get editorNoMusicHereYet;

  /// No description provided for @editorNoMatchingMusic.
  ///
  /// In en, this message translates to:
  /// **'No matching music'**
  String get editorNoMatchingMusic;

  /// No description provided for @homeMakeFirstVideo.
  ///
  /// In en, this message translates to:
  /// **'Make your first video'**
  String get homeMakeFirstVideo;

  /// No description provided for @homeMyVideos.
  ///
  /// In en, this message translates to:
  /// **'My Videos'**
  String get homeMyVideos;

  /// No description provided for @homeFromFriendsFamily.
  ///
  /// In en, this message translates to:
  /// **'From Friends & Family'**
  String get homeFromFriendsFamily;

  /// No description provided for @homeLikeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# like} other{# likes}}'**
  String homeLikeCount(int count);

  /// No description provided for @captureFinishSetupShareThisClip.
  ///
  /// In en, this message translates to:
  /// **'Finish parent setup before sharing this clip.'**
  String get captureFinishSetupShareThisClip;

  /// No description provided for @editorHubMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get editorHubMusic;

  /// No description provided for @onboardingOpeningApp.
  ///
  /// In en, this message translates to:
  /// **'Opening Tubestr'**
  String get onboardingOpeningApp;

  /// No description provided for @onboardingScanBackupKey.
  ///
  /// In en, this message translates to:
  /// **'Scan Backup Key'**
  String get onboardingScanBackupKey;

  /// No description provided for @onboardingRestoreFirst.
  ///
  /// In en, this message translates to:
  /// **'Restore first'**
  String get onboardingRestoreFirst;

  /// No description provided for @onboardingCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get onboardingCamera;

  /// No description provided for @onboardingMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get onboardingMicrophone;

  /// No description provided for @onboardingCameraPermissionDetail.
  ///
  /// In en, this message translates to:
  /// **'Use the camera for recording videos and scanning family invites.'**
  String get onboardingCameraPermissionDetail;

  /// No description provided for @onboardingMicrophonePermissionDetail.
  ///
  /// In en, this message translates to:
  /// **'Capture audio while recording videos.'**
  String get onboardingMicrophonePermissionDetail;

  /// No description provided for @onboardingAppPermissionsDetail.
  ///
  /// In en, this message translates to:
  /// **'Tubestr uses the camera for recording videos and scanning family invites, and the microphone for video sound.'**
  String get onboardingAppPermissionsDetail;

  /// No description provided for @parentResetApp.
  ///
  /// In en, this message translates to:
  /// **'Reset app'**
  String get parentResetApp;

  /// No description provided for @parentLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get parentLeave;

  /// No description provided for @parentSaveLocally.
  ///
  /// In en, this message translates to:
  /// **'Save locally'**
  String get parentSaveLocally;

  /// No description provided for @parentPublishProfile.
  ///
  /// In en, this message translates to:
  /// **'Publish profile'**
  String get parentPublishProfile;

  /// No description provided for @parentPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent PIN'**
  String get parentPinTitle;

  /// No description provided for @parentPermanentServerDeletion.
  ///
  /// In en, this message translates to:
  /// **'Permanent server-side deletion'**
  String get parentPermanentServerDeletion;

  /// No description provided for @parentRecoveryKey.
  ///
  /// In en, this message translates to:
  /// **'Recovery key'**
  String get parentRecoveryKey;

  /// No description provided for @parentCannotUndoDevice.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone on this device'**
  String get parentCannotUndoDevice;

  /// No description provided for @parentProfileDeleted.
  ///
  /// In en, this message translates to:
  /// **'Profile deleted. {count, plural, =1{# file removed} other{# files removed}} from Tubestr servers.'**
  String parentProfileDeleted(int count);

  /// No description provided for @parentDiagnosticsReadingBuild.
  ///
  /// In en, this message translates to:
  /// **'Reading app build'**
  String get parentDiagnosticsReadingBuild;

  /// No description provided for @parentFamilyConnection.
  ///
  /// In en, this message translates to:
  /// **'Family connection'**
  String get parentFamilyConnection;

  /// No description provided for @parentQueueClear.
  ///
  /// In en, this message translates to:
  /// **'Queue is clear'**
  String get parentQueueClear;

  /// No description provided for @parentNoChildProfiles.
  ///
  /// In en, this message translates to:
  /// **'No child profiles yet'**
  String get parentNoChildProfiles;

  /// No description provided for @parentDashboardReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get parentDashboardReady;

  /// No description provided for @parentDashboardNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get parentDashboardNotSet;

  /// No description provided for @parentDashboardFamilySpaces.
  ///
  /// In en, this message translates to:
  /// **'Family spaces'**
  String get parentDashboardFamilySpaces;

  /// No description provided for @parentDashboardJoinCreate.
  ///
  /// In en, this message translates to:
  /// **'Join or create a family space'**
  String get parentDashboardJoinCreate;

  /// No description provided for @parentDashboardClear.
  ///
  /// In en, this message translates to:
  /// **'Everything is clear'**
  String get parentDashboardClear;

  /// No description provided for @parentDashboardOpenChildren.
  ///
  /// In en, this message translates to:
  /// **'Open Children'**
  String get parentDashboardOpenChildren;

  /// No description provided for @parentDashboardOpenNetwork.
  ///
  /// In en, this message translates to:
  /// **'Open Network'**
  String get parentDashboardOpenNetwork;

  /// No description provided for @parentDashboardNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get parentDashboardNeedsReview;

  /// No description provided for @onboardingScanBackupInstructions.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at your saved parent backup QR code.'**
  String get onboardingScanBackupInstructions;

  /// No description provided for @editorRemixSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Remix saved'**
  String get editorRemixSavedTitle;

  /// No description provided for @editorReviewFirst.
  ///
  /// In en, this message translates to:
  /// **'Review first'**
  String get editorReviewFirst;

  /// No description provided for @captureMicrophoneNoticeOff.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off, so clips will save without sound. Turn microphone access on in Settings to add audio.'**
  String get captureMicrophoneNoticeOff;

  /// No description provided for @captureFinishingClipTitle.
  ///
  /// In en, this message translates to:
  /// **'Finishing your clip'**
  String get captureFinishingClipTitle;

  /// No description provided for @captureFinishingClipDetail.
  ///
  /// In en, this message translates to:
  /// **'Preparing the video and thumbnail for your library.'**
  String get captureFinishingClipDetail;

  /// No description provided for @captureSafetyScanDetail.
  ///
  /// In en, this message translates to:
  /// **'Running an on-device safety scan before sharing.'**
  String get captureSafetyScanDetail;

  /// No description provided for @captureOpeningCamera.
  ///
  /// In en, this message translates to:
  /// **'Opening camera'**
  String get captureOpeningCamera;

  /// No description provided for @captureGettingReadyDetail.
  ///
  /// In en, this message translates to:
  /// **'Getting everything ready so you can record a new clip.'**
  String get captureGettingReadyDetail;

  /// No description provided for @captureMicSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get captureMicSilent;

  /// No description provided for @capturePreparingCamera.
  ///
  /// In en, this message translates to:
  /// **'Preparing camera'**
  String get capturePreparingCamera;

  /// No description provided for @captureGettingReadyShort.
  ///
  /// In en, this message translates to:
  /// **'Getting everything ready.'**
  String get captureGettingReadyShort;

  /// No description provided for @editorHubNothingToRemix.
  ///
  /// In en, this message translates to:
  /// **'Nothing to remix yet'**
  String get editorHubNothingToRemix;

  /// No description provided for @editorHubRecordFirstDetail.
  ///
  /// In en, this message translates to:
  /// **'Record something in Capture first, then come back here to add music, stickers, text, and trims.'**
  String get editorHubRecordFirstDetail;

  /// No description provided for @editorHubFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From {label}'**
  String editorHubFromLabel(String label);

  /// No description provided for @editorStickerPreviewPrompt.
  ///
  /// In en, this message translates to:
  /// **'Looking good! Use it as a sticker?'**
  String get editorStickerPreviewPrompt;

  /// No description provided for @homeFallbackName.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get homeFallbackName;

  /// No description provided for @homeFirstSteps.
  ///
  /// In en, this message translates to:
  /// **'First steps'**
  String get homeFirstSteps;

  /// No description provided for @homeFirstStepsDetail.
  ///
  /// In en, this message translates to:
  /// **'This shelf stays simple until your family actually starts recording.'**
  String get homeFirstStepsDetail;

  /// No description provided for @homeReadyToWatch.
  ///
  /// In en, this message translates to:
  /// **'Ready to watch'**
  String get homeReadyToWatch;

  /// No description provided for @homeSavedFrom.
  ///
  /// In en, this message translates to:
  /// **'Saved from {source}'**
  String homeSavedFrom(String source);

  /// No description provided for @onboardingParentRestoredLocal.
  ///
  /// In en, this message translates to:
  /// **'Parent account restored on this device. In v2, child profiles are local, so you can add the children you want on this device next.'**
  String get onboardingParentRestoredLocal;

  /// No description provided for @onboardingOpeningAppDetail.
  ///
  /// In en, this message translates to:
  /// **'Getting your family space ready on this device.'**
  String get onboardingOpeningAppDetail;

  /// No description provided for @onboardingRoleSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'First, we need to create your parent account. This only takes a minute.'**
  String get onboardingRoleSelectSubtitle;

  /// No description provided for @onboardingParentKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Your parent key is like your family\'s master password. It proves you\'re the parent and lets you manage everything.'**
  String get onboardingParentKeyHelp;

  /// No description provided for @onboardingDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Lee & Emma'**
  String get onboardingDisplayNameHint;

  /// No description provided for @onboardingBirthYearHint.
  ///
  /// In en, this message translates to:
  /// **'1988'**
  String get onboardingBirthYearHint;

  /// No description provided for @onboardingConsentLabel.
  ///
  /// In en, this message translates to:
  /// **'I am 18 or older and I agree to the Tubestr privacy policy on behalf of any children whose profiles I create.'**
  String get onboardingConsentLabel;

  /// No description provided for @onboardingBackupKeyCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent backup key'**
  String get onboardingBackupKeyCardTitle;

  /// No description provided for @onboardingBackupKeyCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Save this before you continue. It is the recovery path for your parent account.'**
  String get onboardingBackupKeyCardDescription;

  /// No description provided for @onboardingRestoreKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste your saved `nsec1...` key or 64-character backup key. You can also scan the QR code if you saved one. If this device still has your parent account saved in secure storage or synced Apple Keychain, Tubestr will pick it up automatically on launch.'**
  String get onboardingRestoreKeySubtitle;

  /// No description provided for @onboardingRestoringParentAccount.
  ///
  /// In en, this message translates to:
  /// **'Restoring your parent account'**
  String get onboardingRestoringParentAccount;

  /// No description provided for @onboardingRecoveryComplete.
  ///
  /// In en, this message translates to:
  /// **'Recovery complete'**
  String get onboardingRecoveryComplete;

  /// No description provided for @onboardingRecoveryNeedsRetry.
  ///
  /// In en, this message translates to:
  /// **'Recovery needs another try'**
  String get onboardingRecoveryNeedsRetry;

  /// No description provided for @onboardingParentKeyRecovered.
  ///
  /// In en, this message translates to:
  /// **'Parent key recovered'**
  String get onboardingParentKeyRecovered;

  /// No description provided for @onboardingChildNameHint.
  ///
  /// In en, this message translates to:
  /// **'Emma'**
  String get onboardingChildNameHint;

  /// No description provided for @onboardingOneLastThing.
  ///
  /// In en, this message translates to:
  /// **'One Last Thing'**
  String get onboardingOneLastThing;

  /// No description provided for @onboardingParentPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Parent public key'**
  String get onboardingParentPublicKey;

  /// No description provided for @parentInviteQrInstructions.
  ///
  /// In en, this message translates to:
  /// **'Have the other parent scan this from their Parent Zone. This will close automatically once they connect.'**
  String get parentInviteQrInstructions;

  /// No description provided for @parentSafetyHqKeysRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Safety HQ is temporarily unavailable while Tubestr refreshes the moderation service keys. Please try again later.'**
  String get parentSafetyHqKeysRefreshing;

  /// No description provided for @parentModerationLoadingDetail.
  ///
  /// In en, this message translates to:
  /// **'Moderation details need another moment to load.'**
  String get parentModerationLoadingDetail;

  /// No description provided for @parentModerationControls.
  ///
  /// In en, this message translates to:
  /// **'Moderation Controls'**
  String get parentModerationControls;

  /// No description provided for @parentModerationControlsDetail.
  ///
  /// In en, this message translates to:
  /// **'Delete shared videos or remove family members. These are separate actions.'**
  String get parentModerationControlsDetail;

  /// No description provided for @parentMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get parentMembersTitle;

  /// No description provided for @parentNoMemberDetails.
  ///
  /// In en, this message translates to:
  /// **'No member details available yet.'**
  String get parentNoMemberDetails;

  /// No description provided for @parentNoSharedVideosFromFamily.
  ///
  /// In en, this message translates to:
  /// **'No shared videos from this family yet.'**
  String get parentNoSharedVideosFromFamily;

  /// No description provided for @parentRemoveMemberCaveat.
  ///
  /// In en, this message translates to:
  /// **'Removing a member does not delete their past content automatically.'**
  String get parentRemoveMemberCaveat;

  /// No description provided for @parentLeaveFamilySpaceAction.
  ///
  /// In en, this message translates to:
  /// **'Leave this family space'**
  String get parentLeaveFamilySpaceAction;

  /// No description provided for @parentProfilePinCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent Profile & PIN'**
  String get parentProfilePinCardTitle;

  /// No description provided for @parentDeleteAccountCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Parent Account'**
  String get parentDeleteAccountCardTitle;

  /// No description provided for @parentDeleteAccountCardDetail.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete Tubestr account records tied to this parent address from Tubestr-operated backend systems, then sign this device out. Any App Store or Play subscription must still be cancelled separately with Apple or Google.'**
  String get parentDeleteAccountCardDetail;

  /// No description provided for @parentDeletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting parent account...'**
  String get parentDeletingAccount;

  /// No description provided for @parentIdentityBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity & Backup'**
  String get parentIdentityBackupTitle;

  /// No description provided for @parentIdentityBackupDetail.
  ///
  /// In en, this message translates to:
  /// **'Keep your recovery details somewhere private so you can restore parent access if you switch devices.'**
  String get parentIdentityBackupDetail;

  /// No description provided for @parentIdentityMissing.
  ///
  /// In en, this message translates to:
  /// **'Parent identity missing'**
  String get parentIdentityMissing;

  /// No description provided for @parentIdentityReady.
  ///
  /// In en, this message translates to:
  /// **'Parent account is ready'**
  String get parentIdentityReady;

  /// No description provided for @parentAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent address'**
  String get parentAddressLabel;

  /// No description provided for @parentPoliciesSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Policies & Support'**
  String get parentPoliciesSupportTitle;

  /// No description provided for @parentPoliciesSupportDetail.
  ///
  /// In en, this message translates to:
  /// **'Open the public support, privacy, and terms pages that families and App Review should be able to find from inside the app.'**
  String get parentPoliciesSupportDetail;

  /// No description provided for @parentResetDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset This Device'**
  String get parentResetDeviceTitle;

  /// No description provided for @parentResetDeviceDetail.
  ///
  /// In en, this message translates to:
  /// **'Reset Tubestr on this device and remove the saved parent account, cached media, queued actions, and Parent Zone PIN. This also clears the synced Apple-keychain copy Tubestr uses for automatic restore on this device.'**
  String get parentResetDeviceDetail;

  /// No description provided for @parentResetDeviceWarning.
  ///
  /// In en, this message translates to:
  /// **'Make sure your parent recovery key is saved somewhere safe. After reset, this device will not auto-restore the parent account until you import that key again.'**
  String get parentResetDeviceWarning;

  /// No description provided for @parentApprovalEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No clips are waiting for a parent review right now.'**
  String get parentApprovalEmptySubtitle;

  /// No description provided for @parentApprovalHasItemsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review new clips before they can be shared outside the device.'**
  String get parentApprovalHasItemsSubtitle;

  /// No description provided for @parentApprovalEmptyDetail.
  ///
  /// In en, this message translates to:
  /// **'New videos are scanned automatically. Anything that needs your approval will appear here.'**
  String get parentApprovalEmptyDetail;

  /// No description provided for @parentDashboardFamilyHealth.
  ///
  /// In en, this message translates to:
  /// **'Family Health'**
  String get parentDashboardFamilyHealth;

  /// No description provided for @parentDashboardLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get parentDashboardLoading;

  /// No description provided for @parentDashboardNoFamilySpaceDetail.
  ///
  /// In en, this message translates to:
  /// **'You need at least one family space to share clips with. Scan a parent\'s invite QR or create a new space to invite someone.'**
  String get parentDashboardNoFamilySpaceDetail;

  /// No description provided for @parentDashboardOpenFamilySpaces.
  ///
  /// In en, this message translates to:
  /// **'Open Family Spaces'**
  String get parentDashboardOpenFamilySpaces;

  /// No description provided for @parentDashboardAllClearDetail.
  ///
  /// In en, this message translates to:
  /// **'No waiting approvals, pending reports, or offline retries right now.'**
  String get parentDashboardAllClearDetail;

  /// No description provided for @parentDashboardApprovalsClear.
  ///
  /// In en, this message translates to:
  /// **'Approval queue is clear'**
  String get parentDashboardApprovalsClear;

  /// No description provided for @parentDashboardClipsNeedReview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# clip needs review} other{# clips need review}}'**
  String parentDashboardClipsNeedReview(int count);

  /// No description provided for @parentDashboardApprovalsClearDetail.
  ///
  /// In en, this message translates to:
  /// **'New kid clips can move ahead without a parent check right now.'**
  String get parentDashboardApprovalsClearDetail;

  /// No description provided for @parentDashboardApprovalsPendingDetail.
  ///
  /// In en, this message translates to:
  /// **'Open Children to approve or reject new clips before they can be shared.'**
  String get parentDashboardApprovalsPendingDetail;

  /// No description provided for @parentDashboardReportsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Reports are up to date'**
  String get parentDashboardReportsUpToDate;

  /// No description provided for @parentDashboardReportsNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# report needs attention} other{# reports need attention}}'**
  String parentDashboardReportsNeedAttention(int count);

  /// No description provided for @parentDashboardReportsUpToDateDetail.
  ///
  /// In en, this message translates to:
  /// **'Family feedback and safety reports are up to date.'**
  String get parentDashboardReportsUpToDateDetail;

  /// No description provided for @parentDashboardReportsPendingDetail.
  ///
  /// In en, this message translates to:
  /// **'Some reports are still being delivered or need follow-up.'**
  String get parentDashboardReportsPendingDetail;

  /// No description provided for @parentDashboardConnectionHealthy.
  ///
  /// In en, this message translates to:
  /// **'Connection health looks good'**
  String get parentDashboardConnectionHealthy;

  /// No description provided for @parentDashboardActionsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# action is waiting offline} other{# actions are waiting offline}}'**
  String parentDashboardActionsWaiting(int count);

  /// No description provided for @parentDashboardConnectionHealthyDetail.
  ///
  /// In en, this message translates to:
  /// **'Shares, reports, and relay activity are connected.'**
  String get parentDashboardConnectionHealthyDetail;

  /// No description provided for @parentDashboardConnectionPendingDetail.
  ///
  /// In en, this message translates to:
  /// **'Open Network to retry queued work and reconnect relays if needed.'**
  String get parentDashboardConnectionPendingDetail;

  /// No description provided for @parentDashboardControlRoomFirstStep.
  ///
  /// In en, this message translates to:
  /// **'Your first step: join or create a family space so you can share clips with someone.'**
  String get parentDashboardControlRoomFirstStep;

  /// No description provided for @parentDashboardControlRoomSteady.
  ///
  /// In en, this message translates to:
  /// **'Everything looks steady. Review your family spaces or jump into settings when you need them.'**
  String get parentDashboardControlRoomSteady;

  /// No description provided for @parentDashboardControlRoomExplainer.
  ///
  /// In en, this message translates to:
  /// **'The decisions that need a parent are up top in Start Here; this is your connection and safety health at a glance.'**
  String get parentDashboardControlRoomExplainer;

  /// No description provided for @parentDiagnosticsRefreshInFlight.
  ///
  /// In en, this message translates to:
  /// **'Refresh in flight'**
  String get parentDiagnosticsRefreshInFlight;

  /// No description provided for @parentDiagnosticsGeneration.
  ///
  /// In en, this message translates to:
  /// **'Generation {value}'**
  String parentDiagnosticsGeneration(int value);

  /// No description provided for @parentDiagnosticsRefreshTriggerDetail.
  ///
  /// In en, this message translates to:
  /// **'Trigger {trigger} · {subscriptions} active subscription(s) · {groups} tracked group(s)'**
  String parentDiagnosticsRefreshTriggerDetail(
    String trigger,
    int subscriptions,
    int groups,
  );

  /// No description provided for @parentDiagnosticsLastRefresh.
  ///
  /// In en, this message translates to:
  /// **'Last refresh {time}'**
  String parentDiagnosticsLastRefresh(String time);

  /// No description provided for @parentDiagnosticsStats.
  ///
  /// In en, this message translates to:
  /// **'Requests {requests} · Coalesced {coalesced} · Stream errors {streamErrors} · Unsubscribe failures {unsubscribeFailures}'**
  String parentDiagnosticsStats(
    int requests,
    int coalesced,
    int streamErrors,
    int unsubscribeFailures,
  );

  /// No description provided for @parentDiagnosticsLastError.
  ///
  /// In en, this message translates to:
  /// **'Last error: {error}'**
  String parentDiagnosticsLastError(String error);

  /// No description provided for @parentDiagnosticsPackageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Package identifier unavailable on this platform.'**
  String get parentDiagnosticsPackageUnavailable;

  /// No description provided for @parentDiagnosticsLaunchTriage.
  ///
  /// In en, this message translates to:
  /// **'Launch Triage'**
  String get parentDiagnosticsLaunchTriage;

  /// No description provided for @parentDiagnosticsLaunchIssuesNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# launch issue needs attention} other{# launch issues need attention}}'**
  String parentDiagnosticsLaunchIssuesNeedAttention(int count);

  /// No description provided for @parentDiagnosticsNoLaunchIssues.
  ///
  /// In en, this message translates to:
  /// **'No queued launch issues right now'**
  String get parentDiagnosticsNoLaunchIssues;

  /// No description provided for @parentDiagnosticsLaunchDetail.
  ///
  /// In en, this message translates to:
  /// **'{actions} queued action(s) · {shares} share issue(s) · {reports} report issue(s) · {downloads} download issue(s)'**
  String parentDiagnosticsLaunchDetail(
    int actions,
    int shares,
    int reports,
    int downloads,
  );

  /// No description provided for @parentDiagnosticsNoActiveSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No relay subscriptions are active right now.'**
  String get parentDiagnosticsNoActiveSubscriptions;

  /// No description provided for @parentDiagnosticsNoRetriesWaiting.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting for retry from shares, reports, or remote downloads.'**
  String get parentDiagnosticsNoRetriesWaiting;

  /// No description provided for @parentDiagnosticsReportsSection.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get parentDiagnosticsReportsSection;

  /// No description provided for @parentDiagnosticsRemoteDownloadsSection.
  ///
  /// In en, this message translates to:
  /// **'Remote downloads'**
  String get parentDiagnosticsRemoteDownloadsSection;

  /// No description provided for @parentJoiningEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Joining…'**
  String get parentJoiningEllipsis;

  /// No description provided for @parentPendingWelcomeDetail.
  ///
  /// In en, this message translates to:
  /// **'From {inviter} · {count, plural, =1{# member} other{# members}}'**
  String parentPendingWelcomeDetail(String inviter, int count);

  /// No description provided for @parentRetryWaitingDetail.
  ///
  /// In en, this message translates to:
  /// **'Retry when you want to push waiting work back through.'**
  String get parentRetryWaitingDetail;

  /// No description provided for @parentPinUnlockDetail.
  ///
  /// In en, this message translates to:
  /// **'Enter your four-digit PIN to open family settings, approvals, and safety controls.'**
  String get parentPinUnlockDetail;

  /// No description provided for @parentFamilyControls.
  ///
  /// In en, this message translates to:
  /// **'Family controls'**
  String get parentFamilyControls;

  /// No description provided for @parentPinSetupRequired.
  ///
  /// In en, this message translates to:
  /// **'PIN setup required'**
  String get parentPinSetupRequired;

  /// No description provided for @parentProtectedByPin.
  ///
  /// In en, this message translates to:
  /// **'Protected by parent PIN'**
  String get parentProtectedByPin;

  /// No description provided for @parentActivityRecentShares.
  ///
  /// In en, this message translates to:
  /// **'Recent Shares'**
  String get parentActivityRecentShares;

  /// No description provided for @parentActivityFamilyFeedback.
  ///
  /// In en, this message translates to:
  /// **'Family Feedback'**
  String get parentActivityFamilyFeedback;

  /// No description provided for @parentActivityNoIncoming.
  ///
  /// In en, this message translates to:
  /// **'No incoming family feedback right now.'**
  String get parentActivityNoIncoming;

  /// No description provided for @parentActivityOutbound.
  ///
  /// In en, this message translates to:
  /// **'Feedback You Shared'**
  String get parentActivityOutbound;

  /// No description provided for @parentActivityNoReports.
  ///
  /// In en, this message translates to:
  /// **'No reports yet. If a child flags a video, you will see delivery status here.'**
  String get parentActivityNoReports;

  /// No description provided for @parentActivityModeration.
  ///
  /// In en, this message translates to:
  /// **'Moderation Activity'**
  String get parentActivityModeration;

  /// No description provided for @parentActivityNoModeration.
  ///
  /// In en, this message translates to:
  /// **'No moderation actions yet.'**
  String get parentActivityNoModeration;

  /// No description provided for @playerSharingAction.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get playerSharingAction;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
