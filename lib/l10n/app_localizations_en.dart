// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tubestr';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCapture => 'Capture';

  @override
  String get tabStudio => 'Studio';

  @override
  String get tabParent => 'Parent';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionHide => 'Hide';

  @override
  String get actionNext => 'Next';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionReveal => 'Reveal';

  @override
  String get actionSend => 'Send';

  @override
  String get actionShare => 'Share';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get actionWatch => 'Watch';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionSkipForNow => 'Skip for now';

  @override
  String get actionRestore => 'Restore';

  @override
  String get actionRetryNow => 'Retry now';

  @override
  String get actionApprove => 'Approve';

  @override
  String get actionReject => 'Reject';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get publicKeyCopied => 'Public key copied';

  @override
  String get recoveryKeyCopied => 'Recovery key copied';

  @override
  String externalOpenFailed(String title) {
    return 'Could not open $title in a browser.';
  }

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystemDescription => 'Follow device';

  @override
  String get themeLightDescription => 'Keep it bright';

  @override
  String get themeDarkDescription => 'Keep it cozy';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageSystemDescription => 'Follow device language';

  @override
  String get languageEnglishDescription => 'Use English';

  @override
  String get languageSpanishDescription => 'Use Spanish';

  @override
  String get kidThemeCampfire => 'Campfire';

  @override
  String get kidThemeTreehouse => 'Treehouse';

  @override
  String get kidThemeBlanketFort => 'Blanket Fort';

  @override
  String get kidThemeStarlight => 'Starlight';

  @override
  String get switchProfile => 'Switch Profile';

  @override
  String get appearance => 'Appearance';

  @override
  String get privateKeyBackupTitle => 'Private key backup';

  @override
  String get privateKeyBackupSubtitle =>
      'This private key gives full control of your parent account.';

  @override
  String get privateKeyBackupWarning =>
      'Keep this private. Anyone with this key can control your family account.';

  @override
  String get profileSwitcherNoProfile => 'No profile yet';

  @override
  String get profileSwitcherProfileFallback => 'Profile';

  @override
  String get scanQrTitle => 'Scan QR';

  @override
  String get scanQrInstructions => 'Point the camera at a QR code.';

  @override
  String get qrNoCamera => 'No camera available.';

  @override
  String qrOpenCameraFailed(String error) {
    return 'Could not open camera: $error';
  }

  @override
  String get reportFeelingPrompt => 'How does this video make you feel?';

  @override
  String get reportActionPrompt => 'What should we do?';

  @override
  String get reportConfirmPrompt => 'Ready to send?';

  @override
  String get reportFeelingUncomfortable => 'Feels Weird';

  @override
  String get reportFeelingSad => 'Makes Me Sad';

  @override
  String get reportFeelingConfused => 'Confusing';

  @override
  String get reportFeelingScared => 'Scary';

  @override
  String get reportFeelingAngry => 'Really Bad';

  @override
  String get reportActionTell => 'Just Tell Them';

  @override
  String get reportActionTellSubtitle => 'Note it for yourself.';

  @override
  String get reportActionHide => 'Hide Their Videos';

  @override
  String get reportActionHideSubtitle => 'Let your parent know privately.';

  @override
  String get reportActionBlock => 'Block Them';

  @override
  String get reportActionBlockSubtitle => 'Alert both families.';

  @override
  String get reportDestinationLocal => 'Stays on this device';

  @override
  String get reportDestinationParent => 'Your parent';

  @override
  String get reportDestinationFamily => 'Both families';

  @override
  String get reportLevelNoted => 'Level 1 · Noted';

  @override
  String get reportLevelParentHelp => 'Level 2 · Parent help';

  @override
  String get reportLevelFamilyAlert => 'Level 3 · Family alert';

  @override
  String get reportLevelOneExplanation =>
      'This stays on your device so you can talk about it with a grown-up later.';

  @override
  String get reportLevelTwoExplanation =>
      'This lets your parent know so they can check in with you.';

  @override
  String get reportLevelThreeExplanation =>
      'This sends an alert to both families so the grown-ups can sort it out.';

  @override
  String get reportReasonInappropriate => 'Inappropriate';

  @override
  String get reportReasonHarassment => 'Harassment';

  @override
  String get reportReasonUnsafe => 'Unsafe';

  @override
  String get reportReasonIllegal => 'Illegal';

  @override
  String reportLevelValue(int level) {
    return 'level $level';
  }

  @override
  String get onboardingIntroTitle => 'Your Family\'s Private Space';

  @override
  String get onboardingIntroSubtitle =>
      'Tubestr is a video app built just for families. No ads, no algorithms, no strangers.';

  @override
  String get onboardingParentKeyTitle => 'Create Your Parent Key';

  @override
  String get onboardingParentKeySubtitle =>
      'First, you\'ll set up a secure parent identity. This key is yours alone and controls your family\'s account.';

  @override
  String get onboardingKidsTitle => 'Add Your Kids';

  @override
  String get onboardingKidsSubtitle =>
      'Create a profile for each child with their own colorful theme. Each kid gets a personalized experience.';

  @override
  String get onboardingCreateTitle => 'Record & Edit Together';

  @override
  String get onboardingCreateSubtitle =>
      'Kids can capture videos, add stickers, music, and effects in the Edit Studio. Creativity without the risk.';

  @override
  String get onboardingApproveTitle => 'You Approve Everything';

  @override
  String get onboardingApproveSubtitle =>
      'Every video goes through you first. Review, approve, and share only with family members you trust.';

  @override
  String get onboardingStepOne => 'Step 1';

  @override
  String get onboardingStepTwo => 'Step 2';

  @override
  String get onboardingStepThree => 'Step 3';

  @override
  String get onboardingStepFour => 'Step 4';

  @override
  String get onboardingGetStarted => 'Let\'s Get Started';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Tubestr';

  @override
  String get onboardingWelcomeBackTitle => 'Welcome Back';

  @override
  String get onboardingGettingStarted => 'Getting started';

  @override
  String get onboardingParentAccount => 'Parent account';

  @override
  String get onboardingChildProfiles => 'Child profiles';

  @override
  String get onboardingAlmostDone => 'Almost done';

  @override
  String get onboardingCreateNewAccount => 'Create new account';

  @override
  String get onboardingHaveBackupKey => 'I have a backup key';

  @override
  String get onboardingParentDisplayName => 'Parent display name';

  @override
  String get onboardingParentBirthYear => 'Parent birth year';

  @override
  String get onboardingParentBackupKey => 'Parent backup key';

  @override
  String get onboardingGenerateParentKey => 'Generate Parent Key';

  @override
  String get onboardingContinueChildProfiles => 'Continue to Child Profiles';

  @override
  String get onboardingComplete => 'Complete Onboarding';

  @override
  String get onboardingAddChildProfile => 'Add Child Profile';

  @override
  String get onboardingScanQrCode => 'Scan QR Code';

  @override
  String get onboardingReadPrivacyPolicy => 'Read privacy policy';

  @override
  String get onboardingAllowAccess => 'Allow Access';

  @override
  String get onboardingRequestingAccess => 'Requesting Access...';

  @override
  String get onboardingParentEligibilityMissingYear =>
      'Enter the parent account holder\'s birth year before continuing.';

  @override
  String get onboardingParentEligibilityInvalidYear =>
      'Enter a valid four-digit birth year.';

  @override
  String onboardingParentEligibilityYearRange(int currentYear) {
    return 'Enter a birth year between 1900 and $currentYear.';
  }

  @override
  String get onboardingParentEligibilityAdult =>
      'Tubestr parent accounts must be created by an adult who is 18 or older.';

  @override
  String get onboardingParentEligibilityConsent =>
      'Confirm the parent consent statement before generating the parent key.';

  @override
  String get onboardingParentKeyCreated =>
      'Parent key created. Save your backup before you continue.';

  @override
  String get onboardingBackupKeyAdded =>
      'Backup key added. Restore when you are ready.';

  @override
  String get onboardingRestoreKeyIncomplete =>
      'That backup key doesn\'t look complete yet. Paste the full `nsec1...` key or 64-character backup key and try again.';

  @override
  String get onboardingRestoreKeyFailed =>
      'We could not restore that backup key yet. Please double-check it and try again.';

  @override
  String get onboardingChildNameRequired =>
      'Enter a child name before continuing.';

  @override
  String get onboardingAddChildFailed =>
      'We could not add that child profile yet.';

  @override
  String get onboardingNeedChildProfile =>
      'Add at least one child profile to finish setup.';

  @override
  String get onboardingPermissionsFailed =>
      'We could not get camera and microphone access yet. You can try again now or allow them later in Settings.';

  @override
  String get onboardingCheckingParentKey => 'Checking your saved parent key...';

  @override
  String get onboardingBootstrapNeedsMoment => 'Tubestr needs another moment';

  @override
  String get onboardingBootstrapChecking =>
      'We are checking your parent backup and preparing this device.';

  @override
  String get onboardingBootstrapReachFailed =>
      'We could not reach this device\'s saved family setup just yet. Please try again in a moment.';

  @override
  String get onboardingBootstrapLibraryMoment =>
      'Your family library needs another moment to open on this device. Please try again.';

  @override
  String get onboardingBootstrapGeneric =>
      'We hit a setup snag while opening your family space. Nothing is lost. Please try again.';

  @override
  String get onboardingWhoFamily => 'Who\'s in Your Family?';

  @override
  String get onboardingWhoFamilySubtitle =>
      'Add a profile for each child. They\'ll each get their own themed space to watch and create videos.';

  @override
  String get onboardingTheme => 'Theme';

  @override
  String get onboardingName => 'Name';

  @override
  String get onboardingPreparingKey => 'Preparing your secure parent key...';

  @override
  String get onboardingSaveParentKey => 'Save your parent key';

  @override
  String get onboardingPrivateKeyHelp =>
      'Your private key is the master backup for this parent account. Save it somewhere safe before continuing.';

  @override
  String get onboardingCompleteTitle => 'You\'re All Set!';

  @override
  String get onboardingCompleteSubtitle => 'Your family\'s Tubestr is ready.';

  @override
  String onboardingBackupShareText(String key) {
    return 'Tubestr Parent Backup Key\n\nKeep this private. Anyone with this key can control your family account.\n\n$key';
  }

  @override
  String get homeGoodMorning => 'Good Morning';

  @override
  String get homeGoodAfternoon => 'Good Afternoon';

  @override
  String get homeGoodEvening => 'Good Evening';

  @override
  String homeGreeting(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get homeStartSubtitle =>
      'Start in Capture, then head to Edit Studio to add stickers, music, or text.';

  @override
  String get homeVideosNeedMoment => 'Your videos need another moment';

  @override
  String get homeLibraryError =>
      'We couldn\'t load this child\'s library just yet. Pull down to try again.';

  @override
  String get homeEmptyTitle => 'Your family video shelf starts here';

  @override
  String get homeEmptySubtitle =>
      'Capture a first clip or connect with a trusted family before this space fills up.';

  @override
  String get homeOpenCapture => 'Open Capture';

  @override
  String get homeConnectFamilies => 'Connect Families';

  @override
  String get homeCapturePrompt =>
      'Capture a clip, then decorate it in Edit Studio when you\'re ready.';

  @override
  String get homeShareLater => 'Share later';

  @override
  String get homeConnectWithFriends => 'Connect with Friends';

  @override
  String get homeShareTrustedFamilies => 'Share videos with trusted families';

  @override
  String get homeReady => 'Ready';

  @override
  String get homeTapDownloadLater => 'Tap to download later';

  @override
  String get homeDownloading => 'Downloading';

  @override
  String get homeNeedsRetry => 'Needs retry';

  @override
  String get approvalPending => 'Pending';

  @override
  String get captureCameraNeedsAttention => 'Camera needs attention';

  @override
  String get captureNoCamera =>
      'We couldn\'t find a camera on this device right now.';

  @override
  String get captureCheckingClip => 'Checking your clip';

  @override
  String get captureTryRecordingAgain => 'Try recording again';

  @override
  String get captureVideoSaved => 'Video Saved!';

  @override
  String get captureSavedNeedsReview => 'Saved, but needs a parent look';

  @override
  String get captureClipReady => 'Clip ready';

  @override
  String get captureReadyDetail =>
      'Your clip is saved, scanned, and ready to edit, watch, or share.';

  @override
  String get captureShareNow => 'Share now';

  @override
  String get captureChooseChild =>
      'Choose a child profile before recording a clip.';

  @override
  String get captureCameraTimeout =>
      'The camera took too long to open. Try again, or close any other app using the camera.';

  @override
  String get captureCameraDenied =>
      'Camera access is turned off. Allow camera access in Settings, then try again.';

  @override
  String get captureMicrophoneDenied =>
      'Microphone access is off. Try again, or turn microphone access on in Settings to record with sound.';

  @override
  String get captureCameraStillDenied =>
      'Camera access is still turned off. Allow access in Settings, then try again.';

  @override
  String get captureCameraBusy =>
      'The camera is busy right now. Close any other app using it and try again.';

  @override
  String get captureCameraStartFailed =>
      'We couldn\'t start the camera just yet. Give it another try.';

  @override
  String get captureFinishSetupShare =>
      'Finish parent setup before sharing clips with family.';

  @override
  String get captureNeedsParentReview =>
      'This clip needs a parent review before it can be shared.';

  @override
  String get captureConnectFamilyShare =>
      'Connect with a family space first, then you can share this clip.';

  @override
  String get captureShareFailed =>
      'We couldn\'t share that clip yet. It\'s still saved safely here.';

  @override
  String captureSharing(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# family spaces',
      one: '# family space',
    );
    return 'Sharing \"$title\" to $_temp0...';
  }

  @override
  String get editorHubTitle => 'Edit Studio';

  @override
  String get editorHubNeedsMoment => 'Edit Studio needs another moment';

  @override
  String get editorHubLoadFailed =>
      'We couldn\'t load your clips for editing just yet. Try switching profiles or come back in a moment.';

  @override
  String get editorHubEmptyTitle => 'Need a clip';

  @override
  String get editorHubEmptyDetail =>
      'Capture something first, then bring it here for stickers, music, text, and remixes.';

  @override
  String get editorHubCaptureFirst => 'Capture First';

  @override
  String get editorToolTrim => 'Trim';

  @override
  String get editorToolEffects => 'Effects';

  @override
  String get editorToolStickers => 'Stickers';

  @override
  String get editorToolAudio => 'Audio';

  @override
  String get editorToolText => 'Text';

  @override
  String get editorToolDraw => 'Draw';

  @override
  String get editorActionKeepEditing => 'Keep editing later';

  @override
  String get editorActionUseSticker => 'Use Sticker';

  @override
  String get editorActionRetake => 'Retake';

  @override
  String get editorSearchStickers => 'Search stickers';

  @override
  String get editorSearchMusic => 'Search music';

  @override
  String get editorTypeSomething => 'Type something...';

  @override
  String get editorAddText => 'Add text';

  @override
  String get editorTapText => 'Tap existing text or add a new one.';

  @override
  String get editorDrawToolPencil => 'Pencil';

  @override
  String get editorDrawToolMarker => 'Marker';

  @override
  String get editorDrawToolEraser => 'Eraser';

  @override
  String get editorDrawWidthLabel => 'Width';

  @override
  String get editorDrawUndo => 'Undo stroke';

  @override
  String get editorDrawClear => 'Clear drawing';

  @override
  String get editorStickerPhotoTitle => 'Take a photo to create a sticker';

  @override
  String get editorSelfieCameraDenied =>
      'Camera access is turned off. Allow it in Settings, then try again.';

  @override
  String get editorSelfieCameraFailed =>
      'We couldn\'t open the selfie camera just yet. Please try again.';

  @override
  String get editorStickerLiftFailed =>
      'We couldn\'t lift the sticker from that photo. Try another selfie with a clearer background.';

  @override
  String get editorStickerCreateFailed =>
      'We couldn\'t make that sticker just yet. Try another photo.';

  @override
  String get editorStickerSaveFailed =>
      'We couldn\'t save that sticker yet. Please try again.';

  @override
  String get editorExportSaved =>
      'Your remix is in the library and ready for the next step.';

  @override
  String editorExportWarning(String warning) {
    return '$warning The remix is still saved and ready to keep going.';
  }

  @override
  String get editorExportGenericFailed =>
      'We couldn\'t save that remix yet. Your edit choices are still here.';

  @override
  String get editorExportSaveFailed =>
      'We couldn\'t finish saving that remix yet. Try again in a moment.';

  @override
  String get editorShareNeedsReview =>
      'This remix still needs a parent review before it can be shared.';

  @override
  String get editorShareUploadFailed =>
      'We couldn\'t upload that remix to the family media server yet. Check your connection and try again.';

  @override
  String get editorShareConnectFamily =>
      'Connect with a family space first, then try sharing this remix again.';

  @override
  String get editorShareFailed =>
      'We couldn\'t share that remix yet. It\'s still saved safely in your library.';

  @override
  String editorSharing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# family spaces',
      one: '# family space',
    );
    return 'Sharing to $_temp0...';
  }

  @override
  String get playerDownloadNow => 'Download Now';

  @override
  String get playerRepairDownload => 'Repair Download';

  @override
  String get playerDownloading => 'Downloading...';

  @override
  String get playerSharedDownloaded => 'Shared video downloaded';

  @override
  String get playerReportDelivered => 'Report delivered';

  @override
  String playerReportSaved(String status) {
    return 'Report saved ($status)';
  }

  @override
  String get playerHideDetails => 'Hide details';

  @override
  String get playerShowDetails => 'Show details';

  @override
  String get playerReact => 'React';

  @override
  String get playerMyClip => 'My clip';

  @override
  String get playerFamilyShare => 'Family share';

  @override
  String get playerRemoteMissingTitle => 'This video isn\'t here yet';

  @override
  String get playerRemotePreparingTitle => 'Getting your video ready';

  @override
  String get playerRemoteFailedTitle => 'Let\'s try that download again';

  @override
  String get playerRemoteReadyTitle => 'Family video ready to watch';

  @override
  String get playerRemotePreparingDetail =>
      'This clip is still getting ready on this device.';

  @override
  String get playerRemoteCheckingDetail =>
      'Checking the saved copy so playback stays smooth and safe.';

  @override
  String get playerRemoteReadyDetail =>
      'Download this family clip and press play when it is ready.';

  @override
  String get playerDownloadConnectionFailed =>
      'We couldn\'t download that clip right now. Check your connection and try again.';

  @override
  String get playerDownloadVerificationFailed =>
      'The saved copy needs another pass. Try the download again in a moment.';

  @override
  String get playerDownloadFailed =>
      'We couldn\'t download that clip yet. Please try again.';

  @override
  String get playerShareNeedsReview =>
      'This clip still needs a parent review before it can be shared.';

  @override
  String get playerShareUploadFailed =>
      'We couldn\'t upload that clip to the family media server yet. Check your connection and try again.';

  @override
  String get playerShareConnectFamily =>
      'Connect with a family space first, then try sharing again.';

  @override
  String get playerShareFailed =>
      'We couldn\'t share that clip yet. It\'s still saved safely here.';

  @override
  String get playerReportFailed =>
      'We couldn\'t send that report just yet. Your note is still on this device, so please try again.';

  @override
  String get playerLikeFailed =>
      'That like didn\'t go through yet. Please try again in a moment.';

  @override
  String get playerReactionFailed =>
      'That reaction didn\'t go through yet. Please try again in a moment.';

  @override
  String playerSharing(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# family spaces',
      one: '# family space',
    );
    return 'Sharing \"$title\" to $_temp0...';
  }

  @override
  String get playerWatchingSoFar => 'Watching so far';

  @override
  String get playerWatchingSoFarDevice => 'Watching so far on this device';

  @override
  String playerPlayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# Plays',
      one: '# Play',
    );
    return '$_temp0';
  }

  @override
  String playerCompletion(int value) {
    return '$value% Completion';
  }

  @override
  String playerReplays(int value) {
    return '$value% Replays';
  }

  @override
  String get playerNoLikes => 'No likes yet';

  @override
  String playerLikeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# Likes',
      one: '# Like',
    );
    return '$_temp0';
  }

  @override
  String get playerAFamily => 'A family';

  @override
  String playerMoreLikes(int count) {
    return '+$count more';
  }

  @override
  String get playerReactions => 'Reactions';

  @override
  String get parentZoneTitle => 'Parent Zone';

  @override
  String get parentSectionDashboard => 'Dashboard';

  @override
  String get parentSectionChildren => 'Children';

  @override
  String get parentSectionFamily => 'Family Spaces';

  @override
  String get parentSectionActivity => 'Activity';

  @override
  String get parentSectionNetwork => 'Network';

  @override
  String get parentSectionAccount => 'Account';

  @override
  String get parentSectionDiagnostics => 'Diagnostics';

  @override
  String get parentStartHere => 'Start Here';

  @override
  String get parentControlRoom => 'Control Room';

  @override
  String get parentOpenSections => 'Open sections';

  @override
  String get parentPinIncorrect => 'Incorrect PIN';

  @override
  String get parentPinMismatch => 'PINs must match (4 digits)';

  @override
  String get parentCreatePinTitle => 'Create Parent PIN';

  @override
  String get parentUnlockTitle => 'Unlock Parent Zone';

  @override
  String get parentPinCreateDetail =>
      'Set a four-digit code so family controls stay separate from the kid-facing app.';

  @override
  String get parentPinUpdateLater => 'You can update this later in Settings.';

  @override
  String get parentPinNew => 'New PIN (4 digits)';

  @override
  String get parentPinConfirm => 'Confirm PIN';

  @override
  String get parentPinSave => 'Save PIN';

  @override
  String get parentPinUpdated => 'PIN updated';

  @override
  String get parentDisplayNameSaved => 'Saved display name';

  @override
  String get parentProfilePublished => 'Published parent profile';

  @override
  String get parentProfilePublishFailed =>
      'We couldn\'t publish your parent profile just yet. Please try again.';

  @override
  String parentJoinedFamily(String name) {
    return 'Joined $name';
  }

  @override
  String get parentAlreadyConnected => 'You\'re already connected.';

  @override
  String parentAlreadyConnectedGroup(String groupName) {
    return 'You\'re already connected in $groupName.';
  }

  @override
  String get parentConnectionAlreadySent =>
      'Connection already sent. They can approve it in Parent Zone.';

  @override
  String parentConnectionAlreadySentGroup(String groupName) {
    return 'Connection already sent for $groupName. They can approve it in Parent Zone.';
  }

  @override
  String get parentConnectionSent =>
      'Connection sent. They can approve it in Parent Zone.';

  @override
  String get parentGroupCreated => 'Group created.';

  @override
  String get parentJoinFailed =>
      'We couldn\'t finish joining that family space yet. Please try again.';

  @override
  String get parentCreateInviteFailed =>
      'We couldn\'t create an invite just yet. Please try again.';

  @override
  String get parentInviteUseFailed =>
      'We couldn\'t use that invite yet. Double-check it and try again.';

  @override
  String get parentInviteTitle => 'Your Invite Code';

  @override
  String get parentInviteScanInstructions =>
      'Point the camera at a family invite QR code.';

  @override
  String parentInviteShareText(String payload) {
    return 'Tubestr Family Invite\n\nOpen this link on the other parent\'s device:\n$payload';
  }

  @override
  String get parentShareLink => 'Share link';

  @override
  String get parentCopyCode => 'Copy code';

  @override
  String get parentOpenFamilySpace => 'Open A Family Space';

  @override
  String get parentOpenFamilySpaceDetail =>
      'Share one invite code, then come back here when the other parent sends their welcome.';

  @override
  String get parentCreateInvite => 'Create invite';

  @override
  String get parentCreateInviteDetail =>
      'Show a QR code or send a shareable invite link';

  @override
  String get parentScanInvite => 'Scan invite';

  @override
  String get parentScanInviteDetail =>
      'Join the shared family space in one step';

  @override
  String get parentPasteInvite => 'Paste invite';

  @override
  String get parentPasteInviteDetail => 'Enter an invite link or code manually';

  @override
  String get parentPasteInviteTitle => 'Paste Invite';

  @override
  String get parentPasteInvitePrompt =>
      'Paste an invite link or code from another parent.';

  @override
  String get parentInviteInputLabel => 'Invite link or code';

  @override
  String get parentUseInvite => 'Use invite';

  @override
  String get parentJoiningFamily => 'Joining family…';

  @override
  String get parentFamilyConnectionsFailed =>
      'We could not load family connections right now.';

  @override
  String get parentNoFamiliesTitle => 'No trusted families yet';

  @override
  String get parentNoFamiliesDetail =>
      'Create an invite or scan one from another parent to open your first family space.';

  @override
  String get parentPendingWelcomes => 'Pending Welcomes';

  @override
  String get parentActiveFamilySpaces => 'Active Family Spaces';

  @override
  String get parentManageConnection => 'Manage connection';

  @override
  String get parentFamilySpaceFallback => 'Family Space';

  @override
  String parentFamilyFallback(String name) {
    return '$name Family';
  }

  @override
  String parentMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# members',
      one: '# member',
    );
    return '$_temp0';
  }

  @override
  String get parentConnectionHealth => 'Connection Health';

  @override
  String get parentConnectionHealthy =>
      'Sharing and reporting are connected right now.';

  @override
  String get parentConnectionWaiting =>
      'Some actions are waiting for a relay connection before they can finish.';

  @override
  String get parentEverythingSynced => 'Everything has synced';

  @override
  String parentQueuedActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# queued actions',
      one: '# queued action',
    );
    return '$_temp0';
  }

  @override
  String get parentNoRetriesNeeded => 'No retries needed.';

  @override
  String get parentRelayAccess => 'Relay Access';

  @override
  String get parentRelayAccessDetail =>
      'These relay addresses carry invites, reports, and family updates. Changes here also publish to other Nostr clients that use your key.';

  @override
  String get parentNoCustomRelays => 'No custom relays saved yet.';

  @override
  String get parentRelayInputLabel => 'Add relay URL';

  @override
  String get parentRelaySave => 'Save relays';

  @override
  String get parentReconnect => 'Reconnect';

  @override
  String get parentUseDefaults => 'Use defaults';

  @override
  String get parentRelaysReconnected => 'Relays reconnected';

  @override
  String parentLastPublished(String time) {
    return 'Last published $time';
  }

  @override
  String get parentMediaServers => 'Media Servers';

  @override
  String get parentMediaServersDetail =>
      'Choose where encrypted media uploads can live for family delivery. Saves publish automatically so other devices and clients stay in sync.';

  @override
  String get parentBlossomInputLabel => 'Add Blossom server';

  @override
  String get parentServersSave => 'Save servers';

  @override
  String get parentSafetyHq => 'Safety HQ';

  @override
  String get parentSafetyHqDetail =>
      'Keep higher-risk reports separate from the main family thread and deliver them to Tubestr moderation once Safety HQ is connected.';

  @override
  String get parentSafetyHqRefreshPending =>
      'Safety HQ needs another moment to refresh.';

  @override
  String get parentSafetyHqRefresh => 'Refresh Safety HQ';

  @override
  String get parentSafetyHqCheck => 'Check Safety HQ';

  @override
  String get parentSafetyHqSetup => 'Set Up Safety HQ';

  @override
  String get parentSafetyHqReady => 'Safety HQ is connected and ready.';

  @override
  String get parentSafetyHqConnectingStarted =>
      'Safety HQ is connecting. We sent the setup welcome to the moderation service.';

  @override
  String get parentSafetyHqStillConnecting =>
      'Safety HQ is still connecting. Leave the app online for a moment and check again.';

  @override
  String get parentSafetySetupFailed =>
      'We couldn\'t set up Safety HQ yet. Please try again.';

  @override
  String get parentHowSafetyWorks => 'How Safety Reporting Works';

  @override
  String get parentSafetyWorksDetail =>
      'Parents can verify what stays private, what reaches the other family, and where media abuse reports are sent.';

  @override
  String get parentSafetyLevelOneTitle => 'Level 1 stays here';

  @override
  String get parentSafetyLevelOneDetail =>
      'Gentle feedback stays on this device so a child can talk with a grown-up later.';

  @override
  String get parentSafetyLevelTwoTitle =>
      'Level 2 alerts the parent on this device';

  @override
  String get parentSafetyLevelTwoDetail =>
      'Stronger concerns stay private to this family and show up in Parent Zone only.';

  @override
  String get parentSafetyLevelThreeTitle => 'Level 3 alerts both families';

  @override
  String get parentSafetyLevelThreeDetail =>
      'The family group gets the report first. Safety HQ keeps a separate copy when it has been set up.';

  @override
  String get parentSafetyBud09Title => 'BUD-09 abuse signals are best effort';

  @override
  String get parentSafetyBud09Detail =>
      'If a parent deletes a shared video, Tubestr also asks the media servers to flag that blob, but the in-app moderation state remains the source of truth.';

  @override
  String parentStatus(String status) {
    return 'Status: $status';
  }

  @override
  String parentStatusLastUpdated(String detail, String time) {
    return '$detail Last updated $time';
  }

  @override
  String get parentLocalGroupId => 'Local group ID';

  @override
  String get parentJustNow => 'just now';

  @override
  String parentMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# minutes ago',
      one: '# minute ago',
    );
    return '$_temp0';
  }

  @override
  String parentHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# hours ago',
      one: '# hour ago',
    );
    return '$_temp0';
  }

  @override
  String parentDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# days ago',
      one: '# day ago',
    );
    return '$_temp0';
  }

  @override
  String get parentChildrenTitle => 'Children';

  @override
  String get parentChildrenDetail =>
      'Each child keeps a theme and local profile for capture, editing, and playback.';

  @override
  String get parentAddChildPrompt =>
      'Add a child profile below so the app has someone to capture and edit for.';

  @override
  String get parentAddChildProfile => 'Add Child Profile';

  @override
  String get parentChildName => 'Child name';

  @override
  String get parentChooseChildTheme =>
      'Choose a name and theme so capture and editing stay personalized.';

  @override
  String get parentSaveChild => 'Save child';

  @override
  String get parentApprovalTitle => 'Approvals & Scanning';

  @override
  String get parentApprovalDetail =>
      'Decide how much parent review happens before a clip can leave the device.';

  @override
  String get parentRequireApproval => 'Require parent approval before sharing';

  @override
  String get parentRequireApprovalDetail =>
      'Clips are always scanned on-device. Turn this on if you also want every new clip to wait for a parent.';

  @override
  String get parentApprovalQueueTitle => 'Approval Queue';

  @override
  String get parentApprovalWaitingScan => 'Waiting on scan results';

  @override
  String get parentUnsafeTopic => 'Unsafe topic';

  @override
  String get parentNeedsLook => 'Needs a look';

  @override
  String get parentVeryLoud => 'Very loud';

  @override
  String get parentLotsOfFaces => 'Lots of faces';

  @override
  String get parentLongClip => 'Long clip';

  @override
  String get parentIntenseTitle => 'Intense title';

  @override
  String get parentAccountTitle => 'Parent account';

  @override
  String get parentAccountNoIdentity =>
      'Create or restore the parent account before using family tools.';

  @override
  String get parentDisplayNameLabel => 'Display name';

  @override
  String get parentDisplayNameHint => 'Lee and Emma';

  @override
  String get parentDisplayNameDetail =>
      'Choose the name other families will see when you connect or share.';

  @override
  String get parentUpdatePin => 'Update PIN';

  @override
  String get parentUpdatePinDetail =>
      'Update the four-digit code that protects the parent workspace.';

  @override
  String get parentNewPinLabel => 'New 4-digit PIN';

  @override
  String get parentPublicAddressReady =>
      'Your public parent address is ready for invites and sharing.';

  @override
  String get parentBackupKeyDescription =>
      'This is the backup key for your parent account. Keep it somewhere private and easy for you to find later.';

  @override
  String get parentSupport => 'Support';

  @override
  String get parentPrivacyPolicy => 'Privacy Policy';

  @override
  String get parentTerms => 'Terms';

  @override
  String get parentSignOutReset => 'Sign out & reset app';

  @override
  String get parentSignOutResetTitle => 'Sign out & reset app?';

  @override
  String get parentSignOutResetDetail =>
      'This will remove the saved parent account from this device, clear the Parent Zone PIN, wipe local videos and cached shares, and clear the synced Apple-keychain copy Tubestr uses for automatic restore here. Make sure your recovery key is saved first.';

  @override
  String get parentResetFailed =>
      'We couldn\'t finish resetting this device yet. Please try again.';

  @override
  String get parentDeleteAccountTitle => 'Delete parent account?';

  @override
  String get parentDeleteAccountDetail =>
      'This removes backend account records for this parent address. Media already copied onto other approved family devices may still remain there until those recipients delete it too.';

  @override
  String parentDeleteAccountDetailWithAddress(String address) {
    return 'This permanently deletes Tubestr backend account records for $address. This also signs the device out after deletion succeeds. Any App Store or Play subscription must still be cancelled separately in Apple or Google billing settings.';
  }

  @override
  String get parentDeleteAccount => 'Delete account';

  @override
  String get parentKeepAccount => 'Keep account';

  @override
  String get parentDeleteAccountFailed =>
      'We couldn\'t delete the parent account yet. Please try again.';

  @override
  String get parentAccountDeleted =>
      'Parent account deleted from Tubestr backend records.';

  @override
  String parentDeleteChildTitle(String childName) {
    return 'Delete $childName?';
  }

  @override
  String get parentDeleteChildFallback => 'this child profile';

  @override
  String get parentDeleteChildDetail =>
      'This will permanently remove the child profile and delete any videos and media stored on behalf of this profile from Tubestr-managed servers. Clips already delivered to other family members remain on their devices.\n\nThis cannot be undone.';

  @override
  String get parentDeleteProfile => 'Delete profile';

  @override
  String parentChildDeleted(String childName) {
    return '$childName removed from Tubestr servers.';
  }

  @override
  String parentChildDeletePartial(String childName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# files could not be removed',
      one: '# file could not be removed',
    );
    return 'We could not finish deleting $childName yet because $_temp0 from Tubestr servers. Try again when the connection is stable.';
  }

  @override
  String get parentNoQueuedActions => 'No queued actions to retry';

  @override
  String parentQueuedActionsStillWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# actions still waiting — check your connection',
      one: '# action still waiting — check your connection',
    );
    return '$_temp0';
  }

  @override
  String parentQueuedActionsSent(int flushed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '# queued actions',
      one: '# queued action',
    );
    return 'Sent $flushed of $_temp0';
  }

  @override
  String parentSharedVideoDeleted(String title) {
    return 'Deleted $title for this family';
  }

  @override
  String get parentDeleteSharedVideoFailed =>
      'We couldn\'t delete that shared video just yet. Please try again.';

  @override
  String get parentMemberRemoved => 'Removed member from family group';

  @override
  String get parentRemoveMemberFailed =>
      'We couldn\'t remove that member just yet. Please try again.';

  @override
  String get parentMemberPromoted => 'Promoted member to admin';

  @override
  String get parentPromoteMemberFailed =>
      'We couldn\'t promote that member just yet. Please try again.';

  @override
  String get parentLeaveFamilyTitle => 'Leave this family space?';

  @override
  String get parentLeaveFamilySolo =>
      'You are the only member. Leaving abandons the group — nobody else can receive new shares here.';

  @override
  String parentLeaveFamilyAdmin(String groupName) {
    return 'You\'ll step down as admin and leave \"$groupName\". You will stop receiving new shares from this family and will no longer be able to send to it. Past clips already stay on your device.';
  }

  @override
  String parentLeaveFamilyMember(String groupName) {
    return 'You will leave \"$groupName\". You will stop receiving new shares from this family and will no longer be able to send to it. Past clips already stay on your device.';
  }

  @override
  String get parentLeaveFamilyLastAdmin =>
      'You\'re the only admin. Use Make admin on another member above, then try again.';

  @override
  String get parentLeaveFamilyFailed =>
      'We couldn\'t leave that family space just yet. Please try again.';

  @override
  String parentLeftFamily(String groupName) {
    return 'Left $groupName';
  }

  @override
  String get parentLeaveFamilyAdminGuidance =>
      'You\'ll self-demote, then publish a leave request. Another member commits the removal when they come online.';

  @override
  String get parentLeaveFamilyMemberGuidance =>
      'You\'ll publish a leave request. Another member commits the removal when they come online; new shares stop arriving in this space.';

  @override
  String get parentMakeAdmin => 'Make admin';

  @override
  String get parentWorking => 'Working…';

  @override
  String get parentSharedVideos => 'Shared Videos';

  @override
  String get parentCurrentParentIdentity => 'Current parent identity';

  @override
  String get parentYou => 'You';

  @override
  String get parentAdmin => 'Admin';

  @override
  String get parentDeleted => 'Deleted';

  @override
  String get parentDiagnosticsCurrentState => 'Current State';

  @override
  String get parentDiagnosticsActiveSubscriptions => 'Active Subscriptions';

  @override
  String get parentDiagnosticsAppBuild => 'App Build';

  @override
  String get parentDiagnosticsRefreshSubscriptions => 'Refresh subscriptions';

  @override
  String get parentDiagnosticsCopyDebugDump => 'Copy debug dump';

  @override
  String get parentDiagnosticsRefreshPage => 'Refresh page';

  @override
  String get parentDiagnosticsCopied => 'Copied relay sync diagnostics';

  @override
  String get parentDiagnosticsVersionLoading =>
      'Version and build number are loading.';

  @override
  String get parentDiagnosticsBuildUnavailable => 'App build unavailable';

  @override
  String get parentDiagnosticsBuildUnavailableDetail =>
      'This platform did not return version and build metadata.';

  @override
  String parentDiagnosticsVersionBuild(String version, String buildNumber) {
    return 'Version $version · Build $buildNumber';
  }

  @override
  String get parentDiagnosticsUnknownVersion => 'unknown version';

  @override
  String get parentDiagnosticsUnknownBuild => 'unknown build';

  @override
  String get parentDiagnosticsNotCompleted => 'has not completed yet';

  @override
  String parentDiagnosticsCompleted(String value) {
    return 'completed $value';
  }

  @override
  String get parentDiagnosticsShares => 'Shares';

  @override
  String get parentDiagnosticsDeliveryIssues => 'Delivery Issues';

  @override
  String get parentDiagnosticsRecentHistory => 'Recent History';

  @override
  String get parentDiagnosticsNoHistory =>
      'No control-plane activity captured yet.';

  @override
  String get parentDiagnosticsClear =>
      'Shares, reports, and remote downloads look clear from this device.';

  @override
  String get parentActivityEmpty =>
      'When you share with another family, the latest deliveries will appear here.';

  @override
  String get parentReportGentle => 'Gentle feedback from another family.';

  @override
  String get parentReportConcern =>
      'A concern from another family needs a look.';

  @override
  String get parentReportSafetyHq =>
      'A serious concern was escalated to Safety HQ.';

  @override
  String get parentReportFamily => 'A concern was shared with both families.';

  @override
  String get parentDestinationDeviceOnly => 'Device only';

  @override
  String get parentDestinationParentOnly => 'Parent only';

  @override
  String get parentDestinationBothFamilies => 'Both families';

  @override
  String get parentDestinationFamilyGroup => 'Family group';

  @override
  String get parentDestinationParentHelpers => 'Parent helpers';

  @override
  String get parentAuditRemoveMember => 'Removed a family member';

  @override
  String get parentAuditDeleteVideo => 'Deleted shared video';

  @override
  String get launchQueuedShares => 'Queued shares';

  @override
  String get launchQueuedLikes => 'Queued likes';

  @override
  String get launchQueuedReactions => 'Queued reactions';

  @override
  String get launchQueuedReports => 'Queued reports';

  @override
  String get launchQueuedProfileUpdates => 'Queued profile updates';

  @override
  String get launchQueuedRelayUpdates => 'Queued relay list updates';

  @override
  String get launchQueuedMediaServerUpdates => 'Queued media server updates';

  @override
  String get launchQueuedMuteUpdates => 'Queued mute list updates';

  @override
  String get launchDelivered => 'Delivered';

  @override
  String get launchWaitingRetry => 'Waiting for retry';

  @override
  String get launchWaitingSafety => 'Waiting on Safety HQ copy';

  @override
  String get launchWaitingConnection => 'Waiting for connection';

  @override
  String get launchWaitingMediaReference =>
      'Waiting for encrypted media reference';

  @override
  String get launchDeliveryFailed => 'Delivery failed';

  @override
  String get launchDownloadFailed =>
      'Download failed. Retry when the connection is stable.';

  @override
  String get launchDownloadRelayFailed =>
      'Download failed because the relay or media server was unreachable.';

  @override
  String get launchDownloadUnlockFailed =>
      'Download failed while unlocking the encrypted video package.';

  @override
  String get launchDownloadVerifyFailed =>
      'Download failed because the saved copy did not pass verification.';

  @override
  String get launchDownloadMetadataFailed =>
      'Download failed because the shared clip metadata was incomplete.';

  @override
  String get launchDownloadGenericFailed =>
      'Download failed. Retry to fetch a fresh encrypted copy.';

  @override
  String get safetyHqProvisioned => 'Provisioned';

  @override
  String get safetyHqConnecting => 'Connecting';

  @override
  String get safetyHqQueued => 'Queued';

  @override
  String get safetyHqNotConfigured => 'Not configured';

  @override
  String get safetyHqProvisionedDetail =>
      'Safety HQ is provisioned and ready to receive higher-risk family alerts.';

  @override
  String get safetyHqConnectingDetail =>
      'Tubestr has already sent the setup welcome. This turns ready once the moderation service joins the group over the relay network.';

  @override
  String get safetyHqQueuedDetail =>
      'Safety HQ setup is queued and will start as soon as this device can reach the moderation relays.';

  @override
  String get safetyHqNotConfiguredDetail =>
      'Set up Safety HQ to keep a separate copy of higher-risk family alerts in Tubestr moderation.';

  @override
  String get safetyHqMissingApiUrl =>
      'This build is missing the Tubestr Safety HQ API URL.';

  @override
  String get safetyHqIncompleteBootstrap =>
      'Tubestr Safety HQ bootstrap data is incomplete.';

  @override
  String get editorActionExport => 'Export';

  @override
  String get editorActionExporting => 'Exporting';

  @override
  String editorLoadTrackFailed(String track) {
    return 'Could not load $track. Please try again.';
  }

  @override
  String editorRemixTitle(String title) {
    return '$title Remix';
  }

  @override
  String get editorBrightness => 'Brightness';

  @override
  String get editorSpeedLabel => 'Speed';

  @override
  String get editorContrast => 'Contrast';

  @override
  String get editorSaturation => 'Saturation';

  @override
  String get editorSharpness => 'Sharpness';

  @override
  String get editorVignette => 'Vignette';

  @override
  String editorTrimKeepDuration(String duration) {
    return 'Keep: $duration';
  }

  @override
  String get editorCategoryAll => 'All';

  @override
  String get editorCategoryYours => 'Yours';

  @override
  String get editorCategoryOriginals => 'Originals';

  @override
  String get editorCategoryFaces => 'Faces';

  @override
  String get editorCategoryHearts => 'Hearts';

  @override
  String get editorCategoryParty => 'Party';

  @override
  String get editorCategoryAnimals => 'Animals';

  @override
  String get editorCategoryFood => 'Food';

  @override
  String get editorCategorySports => 'Sports';

  @override
  String get editorCategoryObjects => 'Objects';

  @override
  String get editorCategoryTravel => 'Travel';

  @override
  String get editorFilterNone => 'None';

  @override
  String get editorFilterVivid => 'Vivid';

  @override
  String get editorFilterMatte => 'Matte';

  @override
  String get editorFilterFade => 'Fade';

  @override
  String get editorFilterWarm => 'Warm';

  @override
  String get editorFilterCool => 'Cool';

  @override
  String get editorFilterNoir => 'Noir';

  @override
  String get editorNoStickersHereYet => 'No stickers here yet';

  @override
  String get editorNoMatchingStickers => 'No matching stickers';

  @override
  String get editorMusicReady => 'Ready';

  @override
  String get editorMusicDownload => 'Download';

  @override
  String get editorMusicLoading => 'Loading';

  @override
  String get editorMusicHappy => 'Happy';

  @override
  String get editorMusicEnergy => 'Energy';

  @override
  String get editorMusicChill => 'Chill';

  @override
  String get editorMusicChiptune => 'Chiptune';

  @override
  String get editorMusicDramatic => 'Dramatic';

  @override
  String get editorMusicLoops => 'Loops';

  @override
  String get editorNoMusicHereYet => 'No music here yet';

  @override
  String get editorNoMatchingMusic => 'No matching music';

  @override
  String get homeMakeFirstVideo => 'Make your first video';

  @override
  String get homeMyVideos => 'My Videos';

  @override
  String get homeFromFriendsFamily => 'From Friends & Family';

  @override
  String homeLikeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# likes',
      one: '# like',
    );
    return '$_temp0';
  }

  @override
  String get captureFinishSetupShareThisClip =>
      'Finish parent setup before sharing this clip.';

  @override
  String get editorHubMusic => 'Music';

  @override
  String get onboardingOpeningApp => 'Opening Tubestr';

  @override
  String get onboardingScanBackupKey => 'Scan Backup Key';

  @override
  String get onboardingRestoreFirst => 'Restore first';

  @override
  String get onboardingCamera => 'Camera';

  @override
  String get onboardingMicrophone => 'Microphone';

  @override
  String get onboardingCameraPermissionDetail =>
      'Use the camera for recording videos and scanning family invites.';

  @override
  String get onboardingMicrophonePermissionDetail =>
      'Capture audio while recording videos.';

  @override
  String get onboardingAppPermissionsDetail =>
      'Tubestr uses the camera for recording videos and scanning family invites, and the microphone for video sound.';

  @override
  String get parentResetApp => 'Reset app';

  @override
  String get parentLeave => 'Leave';

  @override
  String get parentSaveLocally => 'Save locally';

  @override
  String get parentPublishProfile => 'Publish profile';

  @override
  String get parentPinTitle => 'Parent PIN';

  @override
  String get parentPermanentServerDeletion => 'Permanent server-side deletion';

  @override
  String get parentRecoveryKey => 'Recovery key';

  @override
  String get parentCannotUndoDevice => 'This cannot be undone on this device';

  @override
  String parentProfileDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# files removed',
      one: '# file removed',
    );
    return 'Profile deleted. $_temp0 from Tubestr servers.';
  }

  @override
  String get parentDiagnosticsReadingBuild => 'Reading app build';

  @override
  String get parentFamilyConnection => 'Family connection';

  @override
  String get parentQueueClear => 'Queue is clear';

  @override
  String get parentNoChildProfiles => 'No child profiles yet';

  @override
  String get parentDashboardReady => 'Ready';

  @override
  String get parentDashboardNotSet => 'Not set';

  @override
  String get parentDashboardFamilySpaces => 'Family spaces';

  @override
  String get parentDashboardJoinCreate => 'Join or create a family space';

  @override
  String get parentDashboardClear => 'Everything is clear';

  @override
  String get parentDashboardOpenChildren => 'Open Children';

  @override
  String get parentDashboardOpenNetwork => 'Open Network';

  @override
  String get parentDashboardNeedsReview => 'Needs review';

  @override
  String get onboardingScanBackupInstructions =>
      'Point the camera at your saved parent backup QR code.';

  @override
  String get editorRemixSavedTitle => 'Remix saved';

  @override
  String get editorReviewFirst => 'Review first';

  @override
  String get captureMicrophoneNoticeOff =>
      'Microphone access is off, so clips will save without sound. Turn microphone access on in Settings to add audio.';

  @override
  String get captureFinishingClipTitle => 'Finishing your clip';

  @override
  String get captureFinishingClipDetail =>
      'Preparing the video and thumbnail for your library.';

  @override
  String get captureSafetyScanDetail =>
      'Running an on-device safety scan before sharing.';

  @override
  String get captureOpeningCamera => 'Opening camera';

  @override
  String get captureGettingReadyDetail =>
      'Getting everything ready so you can record a new clip.';

  @override
  String get captureMicSilent => 'Silent';

  @override
  String get capturePreparingCamera => 'Preparing camera';

  @override
  String get captureGettingReadyShort => 'Getting everything ready.';

  @override
  String get editorHubNothingToRemix => 'Nothing to remix yet';

  @override
  String get editorHubRecordFirstDetail =>
      'Record something in Capture first, then come back here to add music, stickers, text, and trims.';

  @override
  String editorHubFromLabel(String label) {
    return 'From $label';
  }

  @override
  String get editorStickerPreviewPrompt => 'Looking good! Use it as a sticker?';

  @override
  String get homeFallbackName => 'there';

  @override
  String get homeFirstSteps => 'First steps';

  @override
  String get homeFirstStepsDetail =>
      'This shelf stays simple until your family actually starts recording.';

  @override
  String get homeReadyToWatch => 'Ready to watch';

  @override
  String homeSavedFrom(String source) {
    return 'Saved from $source';
  }

  @override
  String get onboardingParentRestoredLocal =>
      'Parent account restored on this device. In v2, child profiles are local, so you can add the children you want on this device next.';

  @override
  String get onboardingOpeningAppDetail =>
      'Getting your family space ready on this device.';

  @override
  String get onboardingRoleSelectSubtitle =>
      'First, we need to create your parent account. This only takes a minute.';

  @override
  String get onboardingParentKeyHelp =>
      'Your parent key is like your family\'s master password. It proves you\'re the parent and lets you manage everything.';

  @override
  String get onboardingDisplayNameHint => 'Lee & Emma';

  @override
  String get onboardingBirthYearHint => '1988';

  @override
  String get onboardingConsentLabel =>
      'I am 18 or older and I agree to the Tubestr privacy policy on behalf of any children whose profiles I create.';

  @override
  String get onboardingBackupKeyCardTitle => 'Parent backup key';

  @override
  String get onboardingBackupKeyCardDescription =>
      'Save this before you continue. It is the recovery path for your parent account.';

  @override
  String get onboardingRestoreKeySubtitle =>
      'Paste your saved `nsec1...` key or 64-character backup key. You can also scan the QR code if you saved one. If this device still has your parent account saved in secure storage or synced Apple Keychain, Tubestr will pick it up automatically on launch.';

  @override
  String get onboardingRestoringParentAccount =>
      'Restoring your parent account';

  @override
  String get onboardingRecoveryComplete => 'Recovery complete';

  @override
  String get onboardingRecoveryNeedsRetry => 'Recovery needs another try';

  @override
  String get onboardingParentKeyRecovered => 'Parent key recovered';

  @override
  String get onboardingChildNameHint => 'Emma';

  @override
  String get onboardingOneLastThing => 'One Last Thing';

  @override
  String get onboardingParentPublicKey => 'Parent public key';

  @override
  String get parentInviteQrInstructions =>
      'Have the other parent scan this from their Parent Zone. This will close automatically once they connect.';

  @override
  String get parentSafetyHqKeysRefreshing =>
      'Safety HQ is temporarily unavailable while Tubestr refreshes the moderation service keys. Please try again later.';

  @override
  String get parentModerationLoadingDetail =>
      'Moderation details need another moment to load.';

  @override
  String get parentModerationControls => 'Moderation Controls';

  @override
  String get parentModerationControlsDetail =>
      'Delete shared videos or remove family members. These are separate actions.';

  @override
  String get parentMembersTitle => 'Members';

  @override
  String get parentNoMemberDetails => 'No member details available yet.';

  @override
  String get parentNoSharedVideosFromFamily =>
      'No shared videos from this family yet.';

  @override
  String get parentRemoveMemberCaveat =>
      'Removing a member does not delete their past content automatically.';

  @override
  String get parentLeaveFamilySpaceAction => 'Leave this family space';

  @override
  String get parentProfilePinCardTitle => 'Parent Profile & PIN';

  @override
  String get parentDeleteAccountCardTitle => 'Delete Parent Account';

  @override
  String get parentDeleteAccountCardDetail =>
      'Permanently delete Tubestr account records tied to this parent address from Tubestr-operated backend systems, then sign this device out. Any App Store or Play subscription must still be cancelled separately with Apple or Google.';

  @override
  String get parentDeletingAccount => 'Deleting parent account...';

  @override
  String get parentIdentityBackupTitle => 'Identity & Backup';

  @override
  String get parentIdentityBackupDetail =>
      'Keep your recovery details somewhere private so you can restore parent access if you switch devices.';

  @override
  String get parentIdentityMissing => 'Parent identity missing';

  @override
  String get parentIdentityReady => 'Parent account is ready';

  @override
  String get parentAddressLabel => 'Parent address';

  @override
  String get parentPoliciesSupportTitle => 'Policies & Support';

  @override
  String get parentPoliciesSupportDetail =>
      'Open the public support, privacy, and terms pages that families and App Review should be able to find from inside the app.';

  @override
  String get parentResetDeviceTitle => 'Reset This Device';

  @override
  String get parentResetDeviceDetail =>
      'Reset Tubestr on this device and remove the saved parent account, cached media, queued actions, and Parent Zone PIN. This also clears the synced Apple-keychain copy Tubestr uses for automatic restore on this device.';

  @override
  String get parentResetDeviceWarning =>
      'Make sure your parent recovery key is saved somewhere safe. After reset, this device will not auto-restore the parent account until you import that key again.';

  @override
  String get parentApprovalEmptySubtitle =>
      'No clips are waiting for a parent review right now.';

  @override
  String get parentApprovalHasItemsSubtitle =>
      'Review new clips before they can be shared outside the device.';

  @override
  String get parentApprovalEmptyDetail =>
      'New videos are scanned automatically. Anything that needs your approval will appear here.';

  @override
  String get parentDashboardFamilyHealth => 'Family Health';

  @override
  String get parentDashboardLoading => 'Loading';

  @override
  String get parentDashboardNoFamilySpaceDetail =>
      'You need at least one family space to share clips with. Scan a parent\'s invite QR or create a new space to invite someone.';

  @override
  String get parentDashboardOpenFamilySpaces => 'Open Family Spaces';

  @override
  String get parentDashboardAllClearDetail =>
      'No waiting approvals, pending reports, or offline retries right now.';

  @override
  String get parentDashboardApprovalsClear => 'Approval queue is clear';

  @override
  String parentDashboardClipsNeedReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# clips need review',
      one: '# clip needs review',
    );
    return '$_temp0';
  }

  @override
  String get parentDashboardApprovalsClearDetail =>
      'New kid clips can move ahead without a parent check right now.';

  @override
  String get parentDashboardApprovalsPendingDetail =>
      'Open Children to approve or reject new clips before they can be shared.';

  @override
  String get parentDashboardReportsUpToDate => 'Reports are up to date';

  @override
  String parentDashboardReportsNeedAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# reports need attention',
      one: '# report needs attention',
    );
    return '$_temp0';
  }

  @override
  String get parentDashboardReportsUpToDateDetail =>
      'Family feedback and safety reports are up to date.';

  @override
  String get parentDashboardReportsPendingDetail =>
      'Some reports are still being delivered or need follow-up.';

  @override
  String get parentDashboardConnectionHealthy => 'Connection health looks good';

  @override
  String parentDashboardActionsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# actions are waiting offline',
      one: '# action is waiting offline',
    );
    return '$_temp0';
  }

  @override
  String get parentDashboardConnectionHealthyDetail =>
      'Shares, reports, and relay activity are connected.';

  @override
  String get parentDashboardConnectionPendingDetail =>
      'Open Network to retry queued work and reconnect relays if needed.';

  @override
  String get parentDashboardControlRoomFirstStep =>
      'Your first step: join or create a family space so you can share clips with someone.';

  @override
  String get parentDashboardControlRoomSteady =>
      'Everything looks steady. Review your family spaces or jump into settings when you need them.';

  @override
  String get parentDashboardControlRoomExplainer =>
      'The decisions that need a parent are up top in Start Here; this is your connection and safety health at a glance.';

  @override
  String get parentDiagnosticsRefreshInFlight => 'Refresh in flight';

  @override
  String parentDiagnosticsGeneration(int value) {
    return 'Generation $value';
  }

  @override
  String parentDiagnosticsRefreshTriggerDetail(
    String trigger,
    int subscriptions,
    int groups,
  ) {
    return 'Trigger $trigger · $subscriptions active subscription(s) · $groups tracked group(s)';
  }

  @override
  String parentDiagnosticsLastRefresh(String time) {
    return 'Last refresh $time';
  }

  @override
  String parentDiagnosticsStats(
    int requests,
    int coalesced,
    int streamErrors,
    int unsubscribeFailures,
  ) {
    return 'Requests $requests · Coalesced $coalesced · Stream errors $streamErrors · Unsubscribe failures $unsubscribeFailures';
  }

  @override
  String parentDiagnosticsLastError(String error) {
    return 'Last error: $error';
  }

  @override
  String get parentDiagnosticsPackageUnavailable =>
      'Package identifier unavailable on this platform.';

  @override
  String get parentDiagnosticsLaunchTriage => 'Launch Triage';

  @override
  String parentDiagnosticsLaunchIssuesNeedAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# launch issues need attention',
      one: '# launch issue needs attention',
    );
    return '$_temp0';
  }

  @override
  String get parentDiagnosticsNoLaunchIssues =>
      'No queued launch issues right now';

  @override
  String parentDiagnosticsLaunchDetail(
    int actions,
    int shares,
    int reports,
    int downloads,
  ) {
    return '$actions queued action(s) · $shares share issue(s) · $reports report issue(s) · $downloads download issue(s)';
  }

  @override
  String get parentDiagnosticsNoActiveSubscriptions =>
      'No relay subscriptions are active right now.';

  @override
  String get parentDiagnosticsNoRetriesWaiting =>
      'Nothing is waiting for retry from shares, reports, or remote downloads.';

  @override
  String get parentDiagnosticsReportsSection => 'Reports';

  @override
  String get parentDiagnosticsRemoteDownloadsSection => 'Remote downloads';

  @override
  String get parentJoiningEllipsis => 'Joining…';

  @override
  String parentPendingWelcomeDetail(String inviter, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# members',
      one: '# member',
    );
    return 'From $inviter · $_temp0';
  }

  @override
  String get parentRetryWaitingDetail =>
      'Retry when you want to push waiting work back through.';

  @override
  String get parentPinUnlockDetail =>
      'Enter your four-digit PIN to open family settings, approvals, and safety controls.';

  @override
  String get parentFamilyControls => 'Family controls';

  @override
  String get parentPinSetupRequired => 'PIN setup required';

  @override
  String get parentProtectedByPin => 'Protected by parent PIN';

  @override
  String get parentActivityRecentShares => 'Recent Shares';

  @override
  String get parentActivityFamilyFeedback => 'Family Feedback';

  @override
  String get parentActivityNoIncoming =>
      'No incoming family feedback right now.';

  @override
  String get parentActivityOutbound => 'Feedback You Shared';

  @override
  String get parentActivityNoReports =>
      'No reports yet. If a child flags a video, you will see delivery status here.';

  @override
  String get parentActivityModeration => 'Moderation Activity';

  @override
  String get parentActivityNoModeration => 'No moderation actions yet.';

  @override
  String get playerSharingAction => 'Sharing';
}
