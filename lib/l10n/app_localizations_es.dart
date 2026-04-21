// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Tubestr';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabCapture => 'Grabar';

  @override
  String get tabStudio => 'Editar';

  @override
  String get tabParent => 'Padres';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionHide => 'Ocultar';

  @override
  String get actionNext => 'Siguiente';

  @override
  String get actionRemove => 'Quitar';

  @override
  String get actionReveal => 'Mostrar';

  @override
  String get actionSend => 'Enviar';

  @override
  String get actionShare => 'Compartir';

  @override
  String get actionTryAgain => 'Reintentar';

  @override
  String get actionWatch => 'Ver';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionSkip => 'Omitir';

  @override
  String get actionSkipForNow => 'Omitir por ahora';

  @override
  String get actionRestore => 'Restaurar';

  @override
  String get actionRetryNow => 'Reintentar';

  @override
  String get actionApprove => 'Aprobar';

  @override
  String get actionReject => 'Rechazar';

  @override
  String get copiedToClipboard => 'Copiado';

  @override
  String get publicKeyCopied => 'Clave pública copiada';

  @override
  String get recoveryKeyCopied => 'Clave de recuperación copiada';

  @override
  String externalOpenFailed(String title) {
    return 'No se pudo abrir $title.';
  }

  @override
  String get themeSystem => 'Automático';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystemDescription => 'Igual que el dispositivo';

  @override
  String get themeLightDescription => 'Siempre claro';

  @override
  String get themeDarkDescription => 'Siempre oscuro';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Automático';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSystemDescription => 'Igual que el dispositivo';

  @override
  String get languageEnglishDescription => 'Usar inglés';

  @override
  String get languageSpanishDescription => 'Usar español';

  @override
  String get kidThemeCampfire => 'Fogata';

  @override
  String get kidThemeTreehouse => 'Casa del árbol';

  @override
  String get kidThemeBlanketFort => 'Fuerte de cobijas';

  @override
  String get kidThemeStarlight => 'Estrellas';

  @override
  String get switchProfile => 'Cambiar perfil';

  @override
  String get appearance => 'Apariencia';

  @override
  String get privateKeyBackupTitle => 'Respaldo de clave privada';

  @override
  String get privateKeyBackupSubtitle =>
      'Esta clave te da control total de tu cuenta de padre.';

  @override
  String get privateKeyBackupWarning =>
      'Guárdala en privado. Quien tenga esta clave puede controlar tu cuenta familiar.';

  @override
  String get profileSwitcherNoProfile => 'Sin perfil todavía';

  @override
  String get profileSwitcherProfileFallback => 'Perfil';

  @override
  String get scanQrTitle => 'Escanear QR';

  @override
  String get scanQrInstructions => 'Apunta la cámara al código QR.';

  @override
  String get qrNoCamera => 'No hay cámara disponible.';

  @override
  String qrOpenCameraFailed(String error) {
    return 'No se pudo abrir la cámara: $error';
  }

  @override
  String get reportFeelingPrompt => '¿Cómo te hace sentir este video?';

  @override
  String get reportActionPrompt => '¿Qué hacemos?';

  @override
  String get reportConfirmPrompt => '¿Listo para enviar?';

  @override
  String get reportFeelingUncomfortable => 'Se siente raro';

  @override
  String get reportFeelingSad => 'Me pone triste';

  @override
  String get reportFeelingConfused => 'No lo entiendo';

  @override
  String get reportFeelingScared => 'Me da miedo';

  @override
  String get reportFeelingAngry => 'Está muy mal';

  @override
  String get reportActionTell => 'Solo anotarlo';

  @override
  String get reportActionTellSubtitle => 'Guárdalo para ti.';

  @override
  String get reportActionHide => 'Ocultar sus videos';

  @override
  String get reportActionHideSubtitle => 'Avísale a tus papás en privado.';

  @override
  String get reportActionBlock => 'Bloquearlos';

  @override
  String get reportActionBlockSubtitle => 'Avisar a las dos familias.';

  @override
  String get reportDestinationLocal => 'Se queda en este dispositivo';

  @override
  String get reportDestinationParent => 'Tu papá o mamá';

  @override
  String get reportDestinationFamily => 'Las dos familias';

  @override
  String get reportLevelNoted => 'Nivel 1 · Anotado';

  @override
  String get reportLevelParentHelp => 'Nivel 2 · Ayuda de padres';

  @override
  String get reportLevelFamilyAlert => 'Nivel 3 · Alerta familiar';

  @override
  String get reportLevelOneExplanation =>
      'Esto se queda en tu dispositivo para que puedas platicarlo con un adulto después.';

  @override
  String get reportLevelTwoExplanation =>
      'Esto avisa a tus papás para que puedan hablar contigo.';

  @override
  String get reportLevelThreeExplanation =>
      'Esto manda una alerta a las dos familias para que los adultos lo resuelvan.';

  @override
  String get reportReasonInappropriate => 'Inapropiado';

  @override
  String get reportReasonHarassment => 'Acoso';

  @override
  String get reportReasonUnsafe => 'No seguro';

  @override
  String get reportReasonIllegal => 'Ilegal';

  @override
  String reportLevelValue(int level) {
    return 'nivel $level';
  }

  @override
  String get onboardingIntroTitle => 'El espacio privado de tu familia';

  @override
  String get onboardingIntroSubtitle =>
      'Tubestr es una app de videos hecha solo para familias. Sin anuncios, sin algoritmos, sin extraños.';

  @override
  String get onboardingParentKeyTitle => 'Crea tu clave de padre';

  @override
  String get onboardingParentKeySubtitle =>
      'Primero, configura una identidad segura de padre. Esta clave es solo tuya y controla la cuenta de tu familia.';

  @override
  String get onboardingKidsTitle => 'Agrega a tus hijos';

  @override
  String get onboardingKidsSubtitle =>
      'Crea un perfil para cada niño con su propio tema colorido. Cada uno tendrá su propia experiencia.';

  @override
  String get onboardingCreateTitle => 'Graba y edita juntos';

  @override
  String get onboardingCreateSubtitle =>
      'Los niños pueden grabar videos, agregar stickers, música y efectos en el Estudio. Creatividad sin riesgos.';

  @override
  String get onboardingApproveTitle => 'Tú apruebas todo';

  @override
  String get onboardingApproveSubtitle =>
      'Cada video pasa por ti primero. Revisa, aprueba y comparte solo con familiares de confianza.';

  @override
  String get onboardingStepOne => 'Paso 1';

  @override
  String get onboardingStepTwo => 'Paso 2';

  @override
  String get onboardingStepThree => 'Paso 3';

  @override
  String get onboardingStepFour => 'Paso 4';

  @override
  String get onboardingGetStarted => 'Empecemos';

  @override
  String get onboardingWelcomeTitle => 'Bienvenido a Tubestr';

  @override
  String get onboardingWelcomeBackTitle => 'Bienvenido de nuevo';

  @override
  String get onboardingGettingStarted => 'Primeros pasos';

  @override
  String get onboardingParentAccount => 'Cuenta de padre';

  @override
  String get onboardingChildProfiles => 'Perfiles de niños';

  @override
  String get onboardingAlmostDone => 'Casi listo';

  @override
  String get onboardingCreateNewAccount => 'Crear cuenta nueva';

  @override
  String get onboardingHaveBackupKey => 'Tengo clave de respaldo';

  @override
  String get onboardingParentDisplayName => 'Nombre visible del padre';

  @override
  String get onboardingParentBirthYear => 'Año de nacimiento';

  @override
  String get onboardingParentBackupKey => 'Clave de respaldo';

  @override
  String get onboardingGenerateParentKey => 'Generar clave de padre';

  @override
  String get onboardingContinueChildProfiles => 'Continuar a perfiles de niños';

  @override
  String get onboardingComplete => 'Terminar configuración';

  @override
  String get onboardingAddChildProfile => 'Agregar niño';

  @override
  String get onboardingScanQrCode => 'Escanear código QR';

  @override
  String get onboardingReadPrivacyPolicy => 'Leer política de privacidad';

  @override
  String get onboardingAllowAccess => 'Permitir acceso';

  @override
  String get onboardingRequestingAccess => 'Pidiendo acceso...';

  @override
  String get onboardingParentEligibilityMissingYear =>
      'Ingresa el año de nacimiento antes de continuar.';

  @override
  String get onboardingParentEligibilityInvalidYear =>
      'Ingresa un año de nacimiento válido de cuatro dígitos.';

  @override
  String onboardingParentEligibilityYearRange(int currentYear) {
    return 'Ingresa un año entre 1900 y $currentYear.';
  }

  @override
  String get onboardingParentEligibilityAdult =>
      'Las cuentas de padre deben ser creadas por un adulto mayor de 18 años.';

  @override
  String get onboardingParentEligibilityConsent =>
      'Confirma el consentimiento antes de generar la clave.';

  @override
  String get onboardingParentKeyCreated =>
      'Clave creada. Guarda tu respaldo antes de continuar.';

  @override
  String get onboardingBackupKeyAdded =>
      'Clave agregada. Restaura cuando quieras.';

  @override
  String get onboardingRestoreKeyIncomplete =>
      'Esa clave no parece completa. Pega la clave `nsec1...` completa o la clave de 64 caracteres.';

  @override
  String get onboardingRestoreKeyFailed =>
      'No pudimos restaurar esa clave. Revísala e intenta de nuevo.';

  @override
  String get onboardingChildNameRequired =>
      'Ingresa el nombre del niño antes de continuar.';

  @override
  String get onboardingAddChildFailed =>
      'No pudimos agregar ese perfil todavía.';

  @override
  String get onboardingNeedChildProfile =>
      'Agrega al menos un perfil de niño para terminar.';

  @override
  String get onboardingPermissionsFailed =>
      'No pudimos obtener acceso a la cámara y micrófono. Puedes reintentar o permitirlos en Configuración.';

  @override
  String get onboardingCheckingParentKey => 'Verificando tu clave guardada...';

  @override
  String get onboardingBootstrapNeedsMoment =>
      'Tubestr necesita un momento más';

  @override
  String get onboardingBootstrapChecking =>
      'Estamos verificando tu respaldo y preparando este dispositivo.';

  @override
  String get onboardingBootstrapReachFailed =>
      'No pudimos acceder a la configuración guardada. Intenta de nuevo en un momento.';

  @override
  String get onboardingBootstrapLibraryMoment =>
      'Tu biblioteca familiar necesita otro momento para abrirse. Intenta de nuevo.';

  @override
  String get onboardingBootstrapGeneric =>
      'Hubo un problema al abrir tu espacio familiar. No se perdió nada. Intenta de nuevo.';

  @override
  String get onboardingWhoFamily => '¿Quiénes están en tu familia?';

  @override
  String get onboardingWhoFamilySubtitle =>
      'Agrega un perfil para cada niño. Cada uno tendrá su propio espacio para ver y crear videos.';

  @override
  String get onboardingTheme => 'Tema';

  @override
  String get onboardingName => 'Nombre';

  @override
  String get onboardingPreparingKey => 'Preparando tu clave segura...';

  @override
  String get onboardingSaveParentKey => 'Guarda tu clave de padre';

  @override
  String get onboardingPrivateKeyHelp =>
      'Tu clave privada es el respaldo maestro de esta cuenta. Guárdala en un lugar seguro antes de continuar.';

  @override
  String get onboardingCompleteTitle => '¡Todo listo!';

  @override
  String get onboardingCompleteSubtitle =>
      'El Tubestr de tu familia está listo.';

  @override
  String onboardingBackupShareText(String key) {
    return 'Clave de respaldo de Tubestr\n\nGuarda esto en privado. Quien tenga esta clave puede controlar tu cuenta familiar.\n\n$key';
  }

  @override
  String get homeGoodMorning => 'Buenos días';

  @override
  String get homeGoodAfternoon => 'Buenas tardes';

  @override
  String get homeGoodEvening => 'Buenas noches';

  @override
  String homeGreeting(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get homeStartSubtitle =>
      'Empieza en Grabar, luego ve a Editar para agregar stickers, música o texto.';

  @override
  String get homeVideosNeedMoment => 'Tus videos necesitan un momento más';

  @override
  String get homeLibraryError =>
      'No pudimos cargar la biblioteca. Desliza hacia abajo para reintentar.';

  @override
  String get homeEmptyTitle => 'Tu estante de videos familiares empieza aquí';

  @override
  String get homeEmptySubtitle =>
      'Graba un primer clip o conéctate con otra familia antes de que este espacio se llene.';

  @override
  String get homeOpenCapture => 'Ir a Grabar';

  @override
  String get homeConnectFamilies => 'Conectar familias';

  @override
  String get homeCapturePrompt =>
      'Graba un clip, luego decóralo en el Estudio cuando quieras.';

  @override
  String get homeShareLater => 'Compartir después';

  @override
  String get homeConnectWithFriends => 'Conectar con amigos';

  @override
  String get homeShareTrustedFamilies =>
      'Comparte videos con familias de confianza';

  @override
  String get homeReady => 'Listo';

  @override
  String get homeTapDownloadLater => 'Toca para descargar después';

  @override
  String get homeDownloading => 'Descargando';

  @override
  String get homeNeedsRetry => 'Necesita reintento';

  @override
  String get approvalPending => 'Pendiente';

  @override
  String get captureCameraNeedsAttention => 'La cámara necesita atención';

  @override
  String get captureNoCamera =>
      'No encontramos una cámara en este dispositivo.';

  @override
  String get captureCheckingClip => 'Revisando tu clip';

  @override
  String get captureTryRecordingAgain => 'Intenta grabar de nuevo';

  @override
  String get captureVideoSaved => '¡Video guardado!';

  @override
  String get captureSavedNeedsReview =>
      'Guardado, pero necesita revisión de un padre';

  @override
  String get captureClipReady => 'Clip listo';

  @override
  String get captureReadyDetail =>
      'Tu clip está guardado, escaneado y listo para editar, ver o compartir.';

  @override
  String get captureShareNow => 'Compartir ahora';

  @override
  String get captureChooseChild => 'Elige un perfil de niño antes de grabar.';

  @override
  String get captureCameraTimeout =>
      'La cámara tardó mucho en abrir. Intenta de nuevo o cierra otras apps que la usen.';

  @override
  String get captureCameraDenied =>
      'El acceso a la cámara está desactivado. Permítelo en Configuración e intenta de nuevo.';

  @override
  String get captureMicrophoneDenied =>
      'El acceso al micrófono está desactivado. Actívalo en Configuración para grabar con sonido.';

  @override
  String get captureCameraStillDenied =>
      'El acceso a la cámara sigue desactivado. Permítelo en Configuración.';

  @override
  String get captureCameraBusy =>
      'La cámara está ocupada. Cierra otras apps que la usen e intenta de nuevo.';

  @override
  String get captureCameraStartFailed =>
      'No pudimos encender la cámara. Intenta de nuevo.';

  @override
  String get captureFinishSetupShare =>
      'Termina la configuración de padre antes de compartir clips.';

  @override
  String get captureNeedsParentReview =>
      'Este clip necesita revisión de un padre antes de compartirse.';

  @override
  String get captureConnectFamilyShare =>
      'Conéctate primero con un espacio familiar, luego podrás compartir este clip.';

  @override
  String get captureShareFailed =>
      'No pudimos compartir ese clip. Sigue guardado aquí de forma segura.';

  @override
  String captureSharing(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# espacios familiares',
      one: '# espacio familiar',
    );
    return 'Compartiendo \"$title\" con $_temp0...';
  }

  @override
  String get editorHubTitle => 'Estudio';

  @override
  String get editorHubNeedsMoment => 'El Estudio necesita un momento más';

  @override
  String get editorHubLoadFailed =>
      'No pudimos cargar tus clips para editar. Intenta cambiar de perfil o vuelve en un momento.';

  @override
  String get editorHubEmptyTitle => 'Necesitas un clip';

  @override
  String get editorHubEmptyDetail =>
      'Primero graba algo, luego tráelo aquí para stickers, música, texto y remezclas.';

  @override
  String get editorHubCaptureFirst => 'Grabar primero';

  @override
  String get editorToolTrim => 'Recortar';

  @override
  String get editorToolEffects => 'Efectos';

  @override
  String get editorToolStickers => 'Stickers';

  @override
  String get editorToolAudio => 'Audio';

  @override
  String get editorToolText => 'Texto';

  @override
  String get editorActionKeepEditing => 'Seguir editando luego';

  @override
  String get editorActionUseSticker => 'Usar sticker';

  @override
  String get editorActionRetake => 'Repetir';

  @override
  String get editorSearchStickers => 'Buscar stickers';

  @override
  String get editorSearchMusic => 'Buscar música';

  @override
  String get editorTypeSomething => 'Escribe algo...';

  @override
  String get editorAddText => 'Agregar texto';

  @override
  String get editorTapText => 'Toca un texto existente o agrega uno nuevo.';

  @override
  String get editorStickerPhotoTitle => 'Toma una foto para crear un sticker';

  @override
  String get editorSelfieCameraDenied =>
      'El acceso a la cámara está desactivado. Permítelo en Configuración.';

  @override
  String get editorSelfieCameraFailed =>
      'No pudimos abrir la cámara selfie. Intenta de nuevo.';

  @override
  String get editorStickerLiftFailed =>
      'No pudimos recortar el sticker de esa foto. Prueba otra selfie con un fondo más claro.';

  @override
  String get editorStickerCreateFailed =>
      'No pudimos hacer ese sticker. Prueba otra foto.';

  @override
  String get editorStickerSaveFailed =>
      'No pudimos guardar ese sticker. Intenta de nuevo.';

  @override
  String get editorExportSaved =>
      'Tu remezcla está en la biblioteca y lista para el siguiente paso.';

  @override
  String editorExportWarning(String warning) {
    return '$warning La remezcla sigue guardada y lista para continuar.';
  }

  @override
  String get editorExportGenericFailed =>
      'No pudimos guardar esa remezcla. Tus ediciones siguen aquí.';

  @override
  String get editorExportSaveFailed =>
      'No pudimos terminar de guardar esa remezcla. Intenta de nuevo en un momento.';

  @override
  String get editorShareNeedsReview =>
      'Esta remezcla necesita revisión de un padre antes de compartirse.';

  @override
  String get editorShareUploadFailed =>
      'No pudimos subir esa remezcla al servidor. Revisa tu conexión e intenta de nuevo.';

  @override
  String get editorShareConnectFamily =>
      'Conéctate primero con un espacio familiar, luego intenta compartir de nuevo.';

  @override
  String get editorShareFailed =>
      'No pudimos compartir esa remezcla. Sigue guardada en tu biblioteca.';

  @override
  String editorSharing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# espacios familiares',
      one: '# espacio familiar',
    );
    return 'Compartiendo con $_temp0...';
  }

  @override
  String get playerDownloadNow => 'Descargar';

  @override
  String get playerRepairDownload => 'Reparar descarga';

  @override
  String get playerDownloading => 'Descargando...';

  @override
  String get playerSharedDownloaded => 'Video compartido descargado';

  @override
  String get playerReportDelivered => 'Reporte entregado';

  @override
  String playerReportSaved(String status) {
    return 'Reporte guardado ($status)';
  }

  @override
  String get playerHideDetails => 'Ocultar detalles';

  @override
  String get playerShowDetails => 'Ver detalles';

  @override
  String get playerReact => 'Reaccionar';

  @override
  String get playerMyClip => 'Mi clip';

  @override
  String get playerFamilyShare => 'Compartido en familia';

  @override
  String get playerRemoteMissingTitle => 'Este video aún no está aquí';

  @override
  String get playerRemotePreparingTitle => 'Preparando tu video';

  @override
  String get playerRemoteFailedTitle => 'Intentemos esa descarga de nuevo';

  @override
  String get playerRemoteReadyTitle => 'Video familiar listo para ver';

  @override
  String get playerRemotePreparingDetail =>
      'Este clip todavía se está preparando en este dispositivo.';

  @override
  String get playerRemoteCheckingDetail =>
      'Verificando la copia guardada para que la reproducción sea fluida y segura.';

  @override
  String get playerRemoteReadyDetail =>
      'Descarga este clip familiar y presiona play cuando esté listo.';

  @override
  String get playerDownloadConnectionFailed =>
      'No pudimos descargar ese clip. Revisa tu conexión e intenta de nuevo.';

  @override
  String get playerDownloadVerificationFailed =>
      'La copia guardada necesita otra verificación. Intenta la descarga de nuevo en un momento.';

  @override
  String get playerDownloadFailed =>
      'No pudimos descargar ese clip. Intenta de nuevo.';

  @override
  String get playerShareNeedsReview =>
      'Este clip necesita revisión de un padre antes de compartirse.';

  @override
  String get playerShareUploadFailed =>
      'No pudimos subir ese clip al servidor. Revisa tu conexión e intenta de nuevo.';

  @override
  String get playerShareConnectFamily =>
      'Conéctate primero con un espacio familiar, luego intenta compartir de nuevo.';

  @override
  String get playerShareFailed =>
      'No pudimos compartir ese clip. Sigue guardado aquí de forma segura.';

  @override
  String get playerReportFailed =>
      'No pudimos enviar ese reporte. Tu nota sigue en este dispositivo, intenta de nuevo.';

  @override
  String get playerLikeFailed =>
      'Ese like no se envió. Intenta de nuevo en un momento.';

  @override
  String get playerReactionFailed =>
      'Esa reacción no se envió. Intenta de nuevo en un momento.';

  @override
  String playerSharing(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# espacios familiares',
      one: '# espacio familiar',
    );
    return 'Compartiendo \"$title\" con $_temp0...';
  }

  @override
  String get playerWatchingSoFar => 'Vistas hasta ahora';

  @override
  String get playerWatchingSoFarDevice => 'Vistas en este dispositivo';

  @override
  String playerPlayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# reproducciones',
      one: '# reproducción',
    );
    return '$_temp0';
  }

  @override
  String playerCompletion(int value) {
    return '$value% completado';
  }

  @override
  String playerReplays(int value) {
    return '$value% repeticiones';
  }

  @override
  String get playerNoLikes => 'Sin likes todavía';

  @override
  String playerLikeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# likes',
      one: '# like',
    );
    return '$_temp0';
  }

  @override
  String get playerAFamily => 'Una familia';

  @override
  String playerMoreLikes(int count) {
    return '+$count más';
  }

  @override
  String get playerReactions => 'Reacciones';

  @override
  String get parentZoneTitle => 'Zona de Padres';

  @override
  String get parentSectionDashboard => 'Panel';

  @override
  String get parentSectionChildren => 'Niños';

  @override
  String get parentSectionFamily => 'Espacios familiares';

  @override
  String get parentSectionActivity => 'Actividad';

  @override
  String get parentSectionNetwork => 'Red';

  @override
  String get parentSectionAccount => 'Cuenta';

  @override
  String get parentSectionDiagnostics => 'Diagnósticos';

  @override
  String get parentStartHere => 'Empieza aquí';

  @override
  String get parentControlRoom => 'Centro de control';

  @override
  String get parentOpenSections => 'Abrir secciones';

  @override
  String get parentPinIncorrect => 'PIN incorrecto';

  @override
  String get parentPinMismatch => 'Los PINs deben coincidir (4 dígitos)';

  @override
  String get parentCreatePinTitle => 'Crear PIN de padre';

  @override
  String get parentUnlockTitle => 'Desbloquear Zona de Padres';

  @override
  String get parentPinCreateDetail =>
      'Crea un código de cuatro dígitos para que los controles familiares estén separados de la app de niños.';

  @override
  String get parentPinUpdateLater =>
      'Puedes cambiarlo después en Configuración.';

  @override
  String get parentPinNew => 'Nuevo PIN (4 dígitos)';

  @override
  String get parentPinConfirm => 'Confirmar PIN';

  @override
  String get parentPinSave => 'Guardar PIN';

  @override
  String get parentPinUpdated => 'PIN actualizado';

  @override
  String get parentDisplayNameSaved => 'Nombre guardado';

  @override
  String get parentProfilePublished => 'Perfil de padre publicado';

  @override
  String get parentProfilePublishFailed =>
      'No pudimos publicar tu perfil de padre. Intenta de nuevo.';

  @override
  String parentJoinedFamily(String name) {
    return 'Te uniste a $name';
  }

  @override
  String get parentAlreadyConnected => 'Ya estás conectado.';

  @override
  String parentAlreadyConnectedGroup(String groupName) {
    return 'Ya estás conectado en $groupName.';
  }

  @override
  String get parentConnectionAlreadySent =>
      'Conexión ya enviada. Pueden aprobarla en su Zona de Padres.';

  @override
  String parentConnectionAlreadySentGroup(String groupName) {
    return 'Conexión ya enviada para $groupName. Pueden aprobarla en su Zona de Padres.';
  }

  @override
  String get parentConnectionSent =>
      'Conexión enviada. Pueden aprobarla en su Zona de Padres.';

  @override
  String get parentGroupCreated => 'Grupo creado.';

  @override
  String get parentJoinFailed =>
      'No pudimos terminar de unirte a ese espacio familiar. Intenta de nuevo.';

  @override
  String get parentCreateInviteFailed =>
      'No pudimos crear una invitación. Intenta de nuevo.';

  @override
  String get parentInviteUseFailed =>
      'No pudimos usar esa invitación. Revísala e intenta de nuevo.';

  @override
  String get parentInviteTitle => 'Tu código de invitación';

  @override
  String get parentInviteScanInstructions =>
      'Apunta la cámara a un QR de invitación familiar.';

  @override
  String parentInviteShareText(String payload) {
    return 'Invitación familiar de Tubestr\n\nAbre este enlace en el dispositivo del otro padre:\n$payload';
  }

  @override
  String get parentShareLink => 'Compartir enlace';

  @override
  String get parentCopyCode => 'Copiar código';

  @override
  String get parentOpenFamilySpace => 'Abrir un espacio familiar';

  @override
  String get parentOpenFamilySpaceDetail =>
      'Comparte un código de invitación, luego vuelve aquí cuando el otro padre te dé la bienvenida.';

  @override
  String get parentCreateInvite => 'Crear invitación';

  @override
  String get parentCreateInviteDetail =>
      'Muestra un QR o envía un enlace de invitación';

  @override
  String get parentScanInvite => 'Escanear invitación';

  @override
  String get parentScanInviteDetail =>
      'Únete al espacio familiar en un solo paso';

  @override
  String get parentPasteInvite => 'Pegar invitación';

  @override
  String get parentPasteInviteDetail =>
      'Ingresa un enlace o código de invitación manualmente';

  @override
  String get parentPasteInviteTitle => 'Pegar invitación';

  @override
  String get parentPasteInvitePrompt =>
      'Pega un enlace de invitación o código de otro padre.';

  @override
  String get parentInviteInputLabel => 'Enlace o código de invitación';

  @override
  String get parentUseInvite => 'Usar invitación';

  @override
  String get parentJoiningFamily => 'Uniéndose...';

  @override
  String get parentFamilyConnectionsFailed =>
      'No pudimos cargar las conexiones familiares.';

  @override
  String get parentNoFamiliesTitle => 'Sin familias de confianza todavía';

  @override
  String get parentNoFamiliesDetail =>
      'Crea una invitación o escanea una de otro padre para abrir tu primer espacio familiar.';

  @override
  String get parentPendingWelcomes => 'Bienvenidas pendientes';

  @override
  String get parentActiveFamilySpaces => 'Espacios familiares activos';

  @override
  String get parentManageConnection => 'Administrar conexión';

  @override
  String get parentFamilySpaceFallback => 'Espacio familiar';

  @override
  String parentFamilyFallback(String name) {
    return 'Familia $name';
  }

  @override
  String parentMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# miembros',
      one: '# miembro',
    );
    return '$_temp0';
  }

  @override
  String get parentConnectionHealth => 'Estado de conexión';

  @override
  String get parentConnectionHealthy =>
      'Compartir y reportar están conectados.';

  @override
  String get parentConnectionWaiting =>
      'Algunas acciones esperan conexión antes de completarse.';

  @override
  String get parentEverythingSynced => 'Todo sincronizado';

  @override
  String parentQueuedActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# acciones en cola',
      one: '# acción en cola',
    );
    return '$_temp0';
  }

  @override
  String get parentNoRetriesNeeded => 'No hay reintentos pendientes.';

  @override
  String get parentRelayAccess => 'Acceso a relays';

  @override
  String get parentRelayAccessDetail =>
      'Estas direcciones de relay transmiten invitaciones, reportes y actualizaciones familiares. Los cambios también se publican a otros clientes Nostr que usen tu clave.';

  @override
  String get parentNoCustomRelays => 'Sin relays personalizados todavía.';

  @override
  String get parentRelayInputLabel => 'Agregar URL de relay';

  @override
  String get parentRelaySave => 'Guardar relays';

  @override
  String get parentReconnect => 'Reconectar';

  @override
  String get parentUseDefaults => 'Usar predeterminados';

  @override
  String get parentRelaysReconnected => 'Relays reconectados';

  @override
  String parentLastPublished(String time) {
    return 'Última publicación $time';
  }

  @override
  String get parentMediaServers => 'Servidores de medios';

  @override
  String get parentMediaServersDetail =>
      'Elige dónde se guardan los archivos cifrados para entregas familiares. Se publican automáticamente para que otros dispositivos estén sincronizados.';

  @override
  String get parentBlossomInputLabel => 'Agregar servidor Blossom';

  @override
  String get parentServersSave => 'Guardar servidores';

  @override
  String get parentSafetyHq => 'Central de Seguridad';

  @override
  String get parentSafetyHqDetail =>
      'Mantén los reportes de mayor riesgo separados del hilo familiar y entrégalos a moderación de Tubestr.';

  @override
  String get parentSafetyHqRefreshPending =>
      'La Central de Seguridad necesita otro momento para actualizarse.';

  @override
  String get parentSafetyHqRefresh => 'Actualizar Central';

  @override
  String get parentSafetyHqCheck => 'Verificar Central';

  @override
  String get parentSafetyHqSetup => 'Configurar Central de Seguridad';

  @override
  String get parentSafetyHqReady =>
      'La Central de Seguridad está conectada y lista.';

  @override
  String get parentSafetyHqConnectingStarted =>
      'La Central de Seguridad se está conectando. Enviamos la bienvenida de configuración al servicio de moderación.';

  @override
  String get parentSafetyHqStillConnecting =>
      'La Central de Seguridad sigue conectándose. Deja la app en línea un momento y revisa de nuevo.';

  @override
  String get parentSafetySetupFailed =>
      'No pudimos configurar la Central de Seguridad. Intenta de nuevo.';

  @override
  String get parentHowSafetyWorks => 'Cómo funcionan los reportes de seguridad';

  @override
  String get parentSafetyWorksDetail =>
      'Los padres pueden verificar qué se queda privado, qué llega a la otra familia y a dónde se envían los reportes de abuso.';

  @override
  String get parentSafetyLevelOneTitle => 'El nivel 1 se queda aquí';

  @override
  String get parentSafetyLevelOneDetail =>
      'Los comentarios leves se quedan en este dispositivo para que el niño pueda hablar con un adulto después.';

  @override
  String get parentSafetyLevelTwoTitle =>
      'El nivel 2 alerta al padre en este dispositivo';

  @override
  String get parentSafetyLevelTwoDetail =>
      'Las preocupaciones más serias se quedan privadas para esta familia y aparecen solo en la Zona de Padres.';

  @override
  String get parentSafetyLevelThreeTitle =>
      'El nivel 3 alerta a ambas familias';

  @override
  String get parentSafetyLevelThreeDetail =>
      'El grupo familiar recibe el reporte primero. La Central de Seguridad guarda una copia separada si está configurada.';

  @override
  String get parentSafetyBud09Title =>
      'Las señales BUD-09 de abuso son mejor esfuerzo';

  @override
  String get parentSafetyBud09Detail =>
      'Si un padre elimina un video compartido, Tubestr también pide a los servidores que marquen ese blob, pero el estado de moderación en la app sigue siendo la fuente de verdad.';

  @override
  String parentStatus(String status) {
    return 'Estado: $status';
  }

  @override
  String parentStatusLastUpdated(String detail, String time) {
    return '$detail Última actualización $time';
  }

  @override
  String get parentLocalGroupId => 'ID de grupo local';

  @override
  String get parentJustNow => 'ahora mismo';

  @override
  String parentMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace # minutos',
      one: 'hace # minuto',
    );
    return '$_temp0';
  }

  @override
  String parentHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace # horas',
      one: 'hace # hora',
    );
    return '$_temp0';
  }

  @override
  String parentDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace # días',
      one: 'hace # día',
    );
    return '$_temp0';
  }

  @override
  String get parentChildrenTitle => 'Niños';

  @override
  String get parentChildrenDetail =>
      'Cada niño tiene su tema y perfil local para grabar, editar y ver videos.';

  @override
  String get parentAddChildPrompt =>
      'Agrega un perfil de niño para que la app tenga a alguien para grabar y editar.';

  @override
  String get parentAddChildProfile => 'Agregar perfil de niño';

  @override
  String get parentChildName => 'Nombre del niño';

  @override
  String get parentChooseChildTheme =>
      'Elige un nombre y tema para personalizar la grabación y edición.';

  @override
  String get parentSaveChild => 'Guardar perfil';

  @override
  String get parentApprovalTitle => 'Aprobaciones y escaneo';

  @override
  String get parentApprovalDetail =>
      'Decide cuánta revisión de padre se necesita antes de que un clip pueda salir del dispositivo.';

  @override
  String get parentRequireApproval =>
      'Requerir aprobación de padre antes de compartir';

  @override
  String get parentRequireApprovalDetail =>
      'Los clips siempre se escanean en el dispositivo. Activa esto si también quieres que cada clip nuevo espere a un padre.';

  @override
  String get parentApprovalQueueTitle => 'Cola de aprobación';

  @override
  String get parentApprovalWaitingScan => 'Esperando resultados del escaneo';

  @override
  String get parentUnsafeTopic => 'Tema no seguro';

  @override
  String get parentNeedsLook => 'Necesita revisión';

  @override
  String get parentVeryLoud => 'Muy ruidoso';

  @override
  String get parentLotsOfFaces => 'Muchas caras';

  @override
  String get parentLongClip => 'Clip largo';

  @override
  String get parentIntenseTitle => 'Título intenso';

  @override
  String get parentAccountTitle => 'Cuenta de padre';

  @override
  String get parentAccountNoIdentity =>
      'Crea o restaura la cuenta de padre antes de usar las herramientas familiares.';

  @override
  String get parentDisplayNameLabel => 'Nombre visible';

  @override
  String get parentDisplayNameHint => 'Lee y Emma';

  @override
  String get parentDisplayNameDetail =>
      'Elige el nombre que verán otras familias cuando te conectes o compartas.';

  @override
  String get parentUpdatePin => 'Cambiar PIN';

  @override
  String get parentUpdatePinDetail =>
      'Cambia el código de cuatro dígitos que protege el espacio de padres.';

  @override
  String get parentNewPinLabel => 'Nuevo PIN de 4 dígitos';

  @override
  String get parentPublicAddressReady =>
      'Tu dirección pública de padre está lista para invitaciones y compartir.';

  @override
  String get parentBackupKeyDescription =>
      'Esta es la clave de respaldo para tu cuenta de padre. Guárdala en un lugar privado y fácil de encontrar.';

  @override
  String get parentSupport => 'Soporte';

  @override
  String get parentPrivacyPolicy => 'Política de privacidad';

  @override
  String get parentTerms => 'Términos';

  @override
  String get parentSignOutReset => 'Cerrar sesión y resetear app';

  @override
  String get parentSignOutResetTitle => '¿Cerrar sesión y resetear app?';

  @override
  String get parentSignOutResetDetail =>
      'Esto eliminará la cuenta guardada de este dispositivo, borrará el PIN de la Zona de Padres, los videos locales y los archivos en caché, y borrará la copia del llavero de Apple que Tubestr usa para restaurar automáticamente. Asegúrate de guardar tu clave de recuperación primero.';

  @override
  String get parentResetFailed =>
      'No pudimos terminar de resetear este dispositivo. Intenta de nuevo.';

  @override
  String get parentDeleteAccountTitle => '¿Eliminar cuenta de padre?';

  @override
  String get parentDeleteAccountDetail =>
      'Esto elimina los registros de cuenta del backend para esta dirección de padre. Los medios ya copiados en otros dispositivos familiares aprobados pueden quedarse allí hasta que esos destinatarios también los eliminen.';

  @override
  String parentDeleteAccountDetailWithAddress(String address) {
    return 'Esto elimina permanentemente los registros de cuenta de Tubestr para $address. También cierra la sesión del dispositivo cuando la eliminación termina. Cualquier suscripción de App Store o Play debe cancelarse por separado en los ajustes de facturación de Apple o Google.';
  }

  @override
  String get parentDeleteAccount => 'Eliminar cuenta';

  @override
  String get parentKeepAccount => 'Mantener cuenta';

  @override
  String get parentDeleteAccountFailed =>
      'No pudimos eliminar la cuenta de padre. Intenta de nuevo.';

  @override
  String get parentAccountDeleted =>
      'Cuenta de padre eliminada de los registros de Tubestr.';

  @override
  String parentDeleteChildTitle(String childName) {
    return '¿Eliminar a $childName?';
  }

  @override
  String get parentDeleteChildFallback => 'este perfil de niño';

  @override
  String get parentDeleteChildDetail =>
      'Esto eliminará permanentemente el perfil del niño y borrará todos los videos y medios almacenados de los servidores de Tubestr. Los clips ya entregados a otros familiares se quedan en sus dispositivos.\n\nEsto no se puede deshacer.';

  @override
  String get parentDeleteProfile => 'Eliminar perfil';

  @override
  String parentChildDeleted(String childName) {
    return '$childName eliminado de los servidores de Tubestr.';
  }

  @override
  String parentChildDeletePartial(String childName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# archivos no se pudieron quitar',
      one: '# archivo no se pudo quitar',
    );
    return 'No pudimos terminar de eliminar a $childName porque $_temp0 de los servidores. Intenta de nuevo cuando la conexión esté estable.';
  }

  @override
  String get parentNoQueuedActions => 'No hay acciones en cola para reintentar';

  @override
  String parentQueuedActionsStillWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# acciones siguen esperando — revisa tu conexión',
      one: '# acción sigue esperando — revisa tu conexión',
    );
    return '$_temp0';
  }

  @override
  String parentQueuedActionsSent(int flushed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '# acciones en cola',
      one: '# acción en cola',
    );
    return 'Se enviaron $flushed de $_temp0';
  }

  @override
  String parentSharedVideoDeleted(String title) {
    return 'Se eliminó $title para esta familia';
  }

  @override
  String get parentDeleteSharedVideoFailed =>
      'No pudimos eliminar ese video compartido. Intenta de nuevo.';

  @override
  String get parentMemberRemoved => 'Miembro eliminado del grupo familiar';

  @override
  String get parentRemoveMemberFailed =>
      'No pudimos eliminar a ese miembro. Intenta de nuevo.';

  @override
  String get parentMemberPromoted => 'Miembro ascendido a admin';

  @override
  String get parentPromoteMemberFailed =>
      'No pudimos ascender a ese miembro. Intenta de nuevo.';

  @override
  String get parentLeaveFamilyTitle => '¿Salir de este espacio familiar?';

  @override
  String get parentLeaveFamilySolo =>
      'Eres el único miembro. Al salir se abandona el grupo y nadie más podrá recibir contenido aquí.';

  @override
  String parentLeaveFamilyAdmin(String groupName) {
    return 'Dejarás de ser admin y saldrás de \"$groupName\". Dejarás de recibir videos nuevos de esta familia y ya no podrás enviarles. Los clips anteriores se quedan en tu dispositivo.';
  }

  @override
  String parentLeaveFamilyMember(String groupName) {
    return 'Saldrás de \"$groupName\". Dejarás de recibir videos nuevos de esta familia y ya no podrás enviarles. Los clips anteriores se quedan en tu dispositivo.';
  }

  @override
  String get parentLeaveFamilyLastAdmin =>
      'Eres el único admin. Usa Hacer admin en otro miembro arriba e intenta de nuevo.';

  @override
  String get parentLeaveFamilyFailed =>
      'No pudimos salir de ese espacio familiar. Intenta de nuevo.';

  @override
  String parentLeftFamily(String groupName) {
    return 'Saliste de $groupName';
  }

  @override
  String get parentLeaveFamilyAdminGuidance =>
      'Dejarás de ser admin y publicarás una solicitud para salir. Otro miembro confirma la salida cuando se conecte.';

  @override
  String get parentLeaveFamilyMemberGuidance =>
      'Publicarás una solicitud para salir. Otro miembro confirma la salida cuando se conecte; dejarán de llegar videos nuevos a este espacio.';

  @override
  String get parentMakeAdmin => 'Hacer admin';

  @override
  String get parentWorking => 'Trabajando...';

  @override
  String get parentSharedVideos => 'Videos compartidos';

  @override
  String get parentCurrentParentIdentity => 'Identidad de padre actual';

  @override
  String get parentYou => 'Tú';

  @override
  String get parentAdmin => 'Admin';

  @override
  String get parentDeleted => 'Eliminado';

  @override
  String get parentDiagnosticsCurrentState => 'Estado actual';

  @override
  String get parentDiagnosticsActiveSubscriptions => 'Suscripciones activas';

  @override
  String get parentDiagnosticsAppBuild => 'Versión de la app';

  @override
  String get parentDiagnosticsRefreshSubscriptions =>
      'Actualizar suscripciones';

  @override
  String get parentDiagnosticsCopyDebugDump => 'Copiar diagnóstico';

  @override
  String get parentDiagnosticsRefreshPage => 'Actualizar página';

  @override
  String get parentDiagnosticsCopied => 'Diagnóstico de sync de relays copiado';

  @override
  String get parentDiagnosticsVersionLoading =>
      'La versión y número de compilación están cargando.';

  @override
  String get parentDiagnosticsBuildUnavailable => 'Versión no disponible';

  @override
  String get parentDiagnosticsBuildUnavailableDetail =>
      'Esta plataforma no devolvió los metadatos de versión.';

  @override
  String parentDiagnosticsVersionBuild(String version, String buildNumber) {
    return 'Versión $version · Build $buildNumber';
  }

  @override
  String get parentDiagnosticsUnknownVersion => 'versión desconocida';

  @override
  String get parentDiagnosticsUnknownBuild => 'build desconocido';

  @override
  String get parentDiagnosticsNotCompleted => 'aún no ha completado';

  @override
  String parentDiagnosticsCompleted(String value) {
    return 'completado $value';
  }

  @override
  String get parentDiagnosticsShares => 'Compartidos';

  @override
  String get parentDiagnosticsDeliveryIssues => 'Problemas de entrega';

  @override
  String get parentDiagnosticsRecentHistory => 'Historial reciente';

  @override
  String get parentDiagnosticsNoHistory =>
      'Sin actividad de plano de control capturada todavía.';

  @override
  String get parentDiagnosticsClear =>
      'Los compartidos, reportes y descargas remotas se ven bien desde este dispositivo.';

  @override
  String get parentActivityEmpty =>
      'Cuando compartas con otra familia, las entregas recientes aparecerán aquí.';

  @override
  String get parentReportGentle => 'Comentario leve de otra familia.';

  @override
  String get parentReportConcern =>
      'Una preocupación de otra familia necesita atención.';

  @override
  String get parentReportSafetyHq =>
      'Una preocupación seria fue escalada a la Central de Seguridad.';

  @override
  String get parentReportFamily =>
      'Una preocupación fue compartida con ambas familias.';

  @override
  String get parentDestinationDeviceOnly => 'Solo dispositivo';

  @override
  String get parentDestinationParentOnly => 'Solo padres';

  @override
  String get parentDestinationBothFamilies => 'Ambas familias';

  @override
  String get parentDestinationFamilyGroup => 'Grupo familiar';

  @override
  String get parentDestinationParentHelpers => 'Ayudantes de padres';

  @override
  String get parentAuditRemoveMember => 'Se eliminó a un miembro de la familia';

  @override
  String get parentAuditDeleteVideo => 'Se eliminó un video compartido';

  @override
  String get launchQueuedShares => 'Compartidos en cola';

  @override
  String get launchQueuedLikes => 'Likes en cola';

  @override
  String get launchQueuedReactions => 'Reacciones en cola';

  @override
  String get launchQueuedReports => 'Reportes en cola';

  @override
  String get launchQueuedProfileUpdates => 'Actualizaciones de perfil en cola';

  @override
  String get launchQueuedRelayUpdates =>
      'Actualizaciones de lista de relays en cola';

  @override
  String get launchQueuedMediaServerUpdates =>
      'Actualizaciones de servidor de medios en cola';

  @override
  String get launchQueuedMuteUpdates =>
      'Actualizaciones de lista de silenciados en cola';

  @override
  String get launchDelivered => 'Entregado';

  @override
  String get launchWaitingRetry => 'Esperando reintento';

  @override
  String get launchWaitingSafety => 'Esperando copia de Central de Seguridad';

  @override
  String get launchWaitingConnection => 'Esperando conexión';

  @override
  String get launchWaitingMediaReference =>
      'Esperando referencia de medios cifrados';

  @override
  String get launchDeliveryFailed => 'Entrega fallida';

  @override
  String get launchDownloadFailed =>
      'Descarga fallida. Reintenta cuando la conexión esté estable.';

  @override
  String get launchDownloadRelayFailed =>
      'Descarga fallida porque el relay o servidor de medios no estaba disponible.';

  @override
  String get launchDownloadUnlockFailed =>
      'Descarga fallida al desbloquear el paquete de video cifrado.';

  @override
  String get launchDownloadVerifyFailed =>
      'Descarga fallida porque la copia guardada no pasó la verificación.';

  @override
  String get launchDownloadMetadataFailed =>
      'Descarga fallida porque los metadatos del clip estaban incompletos.';

  @override
  String get launchDownloadGenericFailed =>
      'Descarga fallida. Reintenta para obtener una copia cifrada nueva.';

  @override
  String get safetyHqProvisioned => 'Configurado';

  @override
  String get safetyHqConnecting => 'Conectando';

  @override
  String get safetyHqQueued => 'En cola';

  @override
  String get safetyHqNotConfigured => 'No configurado';

  @override
  String get safetyHqProvisionedDetail =>
      'La Central de Seguridad está configurada y lista para recibir alertas familiares de mayor riesgo.';

  @override
  String get safetyHqConnectingDetail =>
      'Tubestr ya envió la bienvenida de configuración. Esto estará listo cuando el servicio de moderación se una al grupo a través de la red de relays.';

  @override
  String get safetyHqQueuedDetail =>
      'La configuración de la Central de Seguridad está en cola y comenzará cuando este dispositivo pueda alcanzar los relays de moderación.';

  @override
  String get safetyHqNotConfiguredDetail =>
      'Configura la Central de Seguridad para mantener una copia separada de las alertas familiares de mayor riesgo con moderación de Tubestr.';

  @override
  String get safetyHqMissingApiUrl =>
      'A este build le falta la URL de la API de Central de Seguridad de Tubestr.';

  @override
  String get safetyHqIncompleteBootstrap =>
      'Los datos de arranque de la Central de Seguridad de Tubestr están incompletos.';

  @override
  String get editorActionExport => 'Exportar';

  @override
  String get editorActionExporting => 'Exportando';

  @override
  String editorLoadTrackFailed(String track) {
    return 'No se pudo cargar $track. Intenta de nuevo.';
  }

  @override
  String editorRemixTitle(String title) {
    return 'Remix de $title';
  }

  @override
  String get editorBrightness => 'Brillo';

  @override
  String get editorContrast => 'Contraste';

  @override
  String get editorSaturation => 'Saturación';

  @override
  String get editorSharpness => 'Nitidez';

  @override
  String get editorVignette => 'Viñeta';

  @override
  String editorTrimKeepDuration(String duration) {
    return 'Mantener: $duration';
  }

  @override
  String get editorCategoryAll => 'Todo';

  @override
  String get editorCategoryYours => 'Tuyo';

  @override
  String get editorCategoryOriginals => 'Originales';

  @override
  String get editorCategoryFaces => 'Caras';

  @override
  String get editorCategoryHearts => 'Corazones';

  @override
  String get editorCategoryParty => 'Fiesta';

  @override
  String get editorCategoryAnimals => 'Animales';

  @override
  String get editorCategoryFood => 'Comida';

  @override
  String get editorCategorySports => 'Deportes';

  @override
  String get editorCategoryObjects => 'Objetos';

  @override
  String get editorCategoryTravel => 'Viajes';

  @override
  String get editorFilterNone => 'Ninguno';

  @override
  String get editorFilterVivid => 'Vívido';

  @override
  String get editorFilterMatte => 'Mate';

  @override
  String get editorFilterFade => 'Desvanecido';

  @override
  String get editorFilterWarm => 'Cálido';

  @override
  String get editorFilterCool => 'Frío';

  @override
  String get editorFilterNoir => 'Noir';

  @override
  String get editorNoStickersHereYet => 'Aún no hay stickers aquí';

  @override
  String get editorNoMatchingStickers => 'No hay stickers que coincidan';

  @override
  String get editorMusicReady => 'Listos';

  @override
  String get editorMusicDownload => 'Descargar';

  @override
  String get editorMusicLoading => 'Cargando';

  @override
  String get editorMusicHappy => 'Alegres';

  @override
  String get editorMusicEnergy => 'Energía';

  @override
  String get editorMusicChill => 'Chill';

  @override
  String get editorMusicChiptune => 'Chiptune';

  @override
  String get editorMusicDramatic => 'Dramático';

  @override
  String get editorMusicLoops => 'Loops';

  @override
  String get editorNoMusicHereYet => 'Aún no hay música aquí';

  @override
  String get editorNoMatchingMusic => 'No hay música que coincida';

  @override
  String get homeMakeFirstVideo => 'Haz tu primer video';

  @override
  String get homeMyVideos => 'Mis videos';

  @override
  String get homeFromFriendsFamily => 'De amigos y familia';

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
      'Termina la configuración de padre antes de compartir este clip.';

  @override
  String get editorHubMusic => 'Música';

  @override
  String get onboardingOpeningApp => 'Abriendo Tubestr';

  @override
  String get onboardingScanBackupKey => 'Escanear clave de respaldo';

  @override
  String get onboardingRestoreFirst => 'Restaurar primero';

  @override
  String get onboardingCamera => 'Cámara';

  @override
  String get onboardingMicrophone => 'Micrófono';

  @override
  String get onboardingCameraPermissionDetail =>
      'Usa la cámara para grabar videos y escanear invitaciones familiares.';

  @override
  String get onboardingMicrophonePermissionDetail =>
      'Captura audio mientras grabas videos.';

  @override
  String get onboardingAppPermissionsDetail =>
      'Tubestr usa la cámara para grabar videos y escanear invitaciones, y el micrófono para el sonido del video.';

  @override
  String get parentResetApp => 'Resetear app';

  @override
  String get parentLeave => 'Salir';

  @override
  String get parentSaveLocally => 'Guardar localmente';

  @override
  String get parentPublishProfile => 'Publicar perfil';

  @override
  String get parentPinTitle => 'PIN de padre';

  @override
  String get parentPermanentServerDeletion =>
      'Eliminación permanente del servidor';

  @override
  String get parentRecoveryKey => 'Clave de recuperación';

  @override
  String get parentCannotUndoDevice =>
      'Esto no se puede deshacer en este dispositivo';

  @override
  String parentProfileDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# archivos quitados',
      one: '# archivo quitado',
    );
    return 'Perfil eliminado. $_temp0 de los servidores de Tubestr.';
  }

  @override
  String get parentDiagnosticsReadingBuild => 'Leyendo versión de la app';

  @override
  String get parentFamilyConnection => 'Conexión familiar';

  @override
  String get parentQueueClear => 'Cola vacía';

  @override
  String get parentNoChildProfiles => 'Sin perfiles de niños todavía';

  @override
  String get parentDashboardReady => 'Listo';

  @override
  String get parentDashboardNotSet => 'No configurado';

  @override
  String get parentDashboardFamilySpaces => 'Espacios familiares';

  @override
  String get parentDashboardJoinCreate => 'Únete o crea un espacio familiar';

  @override
  String get parentDashboardClear => 'Todo en orden';

  @override
  String get parentDashboardOpenChildren => 'Abrir Niños';

  @override
  String get parentDashboardOpenNetwork => 'Abrir Red';

  @override
  String get parentDashboardNeedsReview => 'Necesita revisión';

  @override
  String get onboardingScanBackupInstructions =>
      'Apunta la cámara al código QR de respaldo de tus padres.';

  @override
  String get editorRemixSavedTitle => 'Remix guardado';

  @override
  String get editorReviewFirst => 'Revisar primero';

  @override
  String get captureMicrophoneNoticeOff =>
      'El micrófono está desactivado, así que los clips se guardarán sin sonido. Activa el acceso al micrófono en Configuración para agregar audio.';

  @override
  String get captureFinishingClipTitle => 'Terminando tu clip';

  @override
  String get captureFinishingClipDetail =>
      'Preparando el video y la miniatura para tu biblioteca.';

  @override
  String get captureSafetyScanDetail =>
      'Ejecutando un escaneo de seguridad en el dispositivo antes de compartir.';

  @override
  String get captureOpeningCamera => 'Abriendo la cámara';

  @override
  String get captureGettingReadyDetail =>
      'Preparando todo para que puedas grabar un nuevo clip.';

  @override
  String get captureMicSilent => 'Silenciado';

  @override
  String get capturePreparingCamera => 'Preparando la cámara';

  @override
  String get captureGettingReadyShort => 'Preparando todo.';

  @override
  String get editorHubNothingToRemix => 'Nada para remezclar todavía';

  @override
  String get editorHubRecordFirstDetail =>
      'Graba algo en Captura primero, luego vuelve aquí para agregar música, stickers, texto y recortes.';

  @override
  String editorHubFromLabel(String label) {
    return 'De $label';
  }

  @override
  String get editorStickerPreviewPrompt =>
      '¡Se ve genial! ¿Usarlo como sticker?';

  @override
  String get homeFallbackName => 'hola';

  @override
  String get homeFirstSteps => 'Primeros pasos';

  @override
  String get homeFirstStepsDetail =>
      'Este estante permanecerá simple hasta que tu familia empiece a grabar.';

  @override
  String get homeReadyToWatch => 'Listo para ver';

  @override
  String homeSavedFrom(String source) {
    return 'Guardado de $source';
  }

  @override
  String get onboardingParentRestoredLocal =>
      'Cuenta de padre restaurada en este dispositivo. En v2, los perfiles de niños son locales, así que puedes agregar a los niños que quieras a continuación.';

  @override
  String get onboardingOpeningAppDetail =>
      'Preparando tu espacio familiar en este dispositivo.';

  @override
  String get onboardingRoleSelectSubtitle =>
      'Primero, necesitamos crear tu cuenta de padre. Solo toma un minuto.';

  @override
  String get onboardingParentKeyHelp =>
      'Tu clave de padre es como la contraseña maestra de tu familia. Prueba que eres el padre y te permite administrar todo.';

  @override
  String get onboardingDisplayNameHint => 'Lee y Emma';

  @override
  String get onboardingBirthYearHint => '1988';

  @override
  String get onboardingConsentLabel =>
      'Tengo 18 años o más y acepto la política de privacidad de Tubestr en nombre de los niños cuyos perfiles cree.';

  @override
  String get onboardingBackupKeyCardTitle => 'Clave de respaldo de padre';

  @override
  String get onboardingBackupKeyCardDescription =>
      'Guarda esto antes de continuar. Es la vía de recuperación de tu cuenta de padre.';

  @override
  String get onboardingRestoreKeySubtitle =>
      'Pega tu clave `nsec1...` guardada o la clave de respaldo de 64 caracteres. También puedes escanear el código QR si guardaste uno. Si este dispositivo aún tiene tu cuenta de padre guardada en almacenamiento seguro o en el llavero de Apple, Tubestr la detectará automáticamente al iniciar.';

  @override
  String get onboardingRestoringParentAccount =>
      'Restaurando tu cuenta de padre';

  @override
  String get onboardingRecoveryComplete => 'Recuperación completa';

  @override
  String get onboardingRecoveryNeedsRetry =>
      'La recuperación necesita otro intento';

  @override
  String get onboardingParentKeyRecovered => 'Clave de padre recuperada';

  @override
  String get onboardingChildNameHint => 'Emma';

  @override
  String get onboardingOneLastThing => 'Una última cosa';

  @override
  String get onboardingParentPublicKey => 'Clave pública de padre';

  @override
  String get parentInviteQrInstructions =>
      'Pídele al otro padre que escanee esto desde su Zona de Padres. Se cerrará automáticamente cuando se conecten.';

  @override
  String get parentSafetyHqKeysRefreshing =>
      'La Central de Seguridad no está disponible temporalmente mientras Tubestr actualiza las claves del servicio de moderación. Intenta más tarde.';

  @override
  String get parentModerationLoadingDetail =>
      'Los detalles de moderación necesitan un momento más para cargar.';

  @override
  String get parentModerationControls => 'Controles de moderación';

  @override
  String get parentModerationControlsDetail =>
      'Elimina videos compartidos o retira miembros de la familia. Son acciones separadas.';

  @override
  String get parentMembersTitle => 'Miembros';

  @override
  String get parentNoMemberDetails =>
      'Sin detalles de miembros disponibles todavía.';

  @override
  String get parentNoSharedVideosFromFamily =>
      'Sin videos compartidos de esta familia todavía.';

  @override
  String get parentRemoveMemberCaveat =>
      'Retirar a un miembro no elimina automáticamente su contenido anterior.';

  @override
  String get parentLeaveFamilySpaceAction => 'Salir de este espacio familiar';

  @override
  String get parentProfilePinCardTitle => 'Perfil y PIN de padre';

  @override
  String get parentDeleteAccountCardTitle => 'Eliminar cuenta de padre';

  @override
  String get parentDeleteAccountCardDetail =>
      'Elimina permanentemente los registros de cuenta de Tubestr vinculados a esta dirección de padre de los sistemas de backend, luego cierra sesión en este dispositivo. Las suscripciones de App Store o Play deben cancelarse por separado con Apple o Google.';

  @override
  String get parentDeletingAccount => 'Eliminando cuenta de padre...';

  @override
  String get parentIdentityBackupTitle => 'Identidad y respaldo';

  @override
  String get parentIdentityBackupDetail =>
      'Guarda tus datos de recuperación en un lugar privado para poder restaurar el acceso de padre si cambias de dispositivo.';

  @override
  String get parentIdentityMissing => 'Identidad de padre no encontrada';

  @override
  String get parentIdentityReady => 'Cuenta de padre lista';

  @override
  String get parentAddressLabel => 'Dirección de padre';

  @override
  String get parentPoliciesSupportTitle => 'Políticas y soporte';

  @override
  String get parentPoliciesSupportDetail =>
      'Abre las páginas públicas de soporte, privacidad y términos que las familias y App Review deben poder encontrar dentro de la app.';

  @override
  String get parentResetDeviceTitle => 'Resetear este dispositivo';

  @override
  String get parentResetDeviceDetail =>
      'Resetea Tubestr en este dispositivo y elimina la cuenta de padre guardada, medios en caché, acciones en cola y el PIN de la Zona de Padres. Esto también borra la copia del llavero de Apple que Tubestr usa para restaurar automáticamente en este dispositivo.';

  @override
  String get parentResetDeviceWarning =>
      'Asegúrate de que tu clave de recuperación de padre esté guardada en un lugar seguro. Después del reset, este dispositivo no restaurará automáticamente la cuenta de padre hasta que importes esa clave de nuevo.';

  @override
  String get parentApprovalEmptySubtitle =>
      'No hay clips esperando revisión de un padre ahora mismo.';

  @override
  String get parentApprovalHasItemsSubtitle =>
      'Revisa los nuevos clips antes de que puedan compartirse fuera del dispositivo.';

  @override
  String get parentApprovalEmptyDetail =>
      'Los nuevos videos se escanean automáticamente. Lo que necesite tu aprobación aparecerá aquí.';

  @override
  String get parentDashboardFamilyHealth => 'Salud familiar';

  @override
  String get parentDashboardLoading => 'Cargando';

  @override
  String get parentDashboardNoFamilySpaceDetail =>
      'Necesitas al menos un espacio familiar para compartir clips. Escanea el QR de invitación de un padre o crea un nuevo espacio para invitar a alguien.';

  @override
  String get parentDashboardOpenFamilySpaces => 'Abrir espacios familiares';

  @override
  String get parentDashboardAllClearDetail =>
      'No hay aprobaciones pendientes, reportes pendientes ni reintentos sin conexión ahora mismo.';

  @override
  String get parentDashboardApprovalsClear => 'Cola de aprobación vacía';

  @override
  String parentDashboardClipsNeedReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# clips necesitan revisión',
      one: '# clip necesita revisión',
    );
    return '$_temp0';
  }

  @override
  String get parentDashboardApprovalsClearDetail =>
      'Los nuevos clips de niños pueden continuar sin revisión de padre ahora mismo.';

  @override
  String get parentDashboardApprovalsPendingDetail =>
      'Abre Niños para aprobar o rechazar nuevos clips antes de que puedan compartirse.';

  @override
  String get parentDashboardReportsUpToDate => 'Reportes al día';

  @override
  String parentDashboardReportsNeedAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# reportes necesitan atención',
      one: '# reporte necesita atención',
    );
    return '$_temp0';
  }

  @override
  String get parentDashboardReportsUpToDateDetail =>
      'Los comentarios familiares y reportes de seguridad están al día.';

  @override
  String get parentDashboardReportsPendingDetail =>
      'Algunos reportes todavía se están entregando o necesitan seguimiento.';

  @override
  String get parentDashboardConnectionHealthy => 'Conexión en buen estado';

  @override
  String parentDashboardActionsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# acciones están esperando sin conexión',
      one: '# acción está esperando sin conexión',
    );
    return '$_temp0';
  }

  @override
  String get parentDashboardConnectionHealthyDetail =>
      'Compartidos, reportes y actividad de relay están conectados.';

  @override
  String get parentDashboardConnectionPendingDetail =>
      'Abre Red para reintentar el trabajo en cola y reconectar relays si es necesario.';

  @override
  String get parentDashboardControlRoomFirstStep =>
      'Tu primer paso: únete o crea un espacio familiar para poder compartir clips con alguien.';

  @override
  String get parentDashboardControlRoomSteady =>
      'Todo está estable. Revisa tus espacios familiares o accede a la configuración cuando lo necesites.';

  @override
  String get parentDashboardControlRoomExplainer =>
      'Las decisiones que necesitan un padre están arriba en Empieza aquí; esto es un vistazo a tu conexión y salud de seguridad.';

  @override
  String get parentDiagnosticsRefreshInFlight => 'Actualización en curso';

  @override
  String parentDiagnosticsGeneration(int value) {
    return 'Generación $value';
  }

  @override
  String parentDiagnosticsRefreshTriggerDetail(
    String trigger,
    int subscriptions,
    int groups,
  ) {
    return 'Disparador $trigger · $subscriptions suscripción(es) activa(s) · $groups grupo(s) seguido(s)';
  }

  @override
  String parentDiagnosticsLastRefresh(String time) {
    return 'Última actualización $time';
  }

  @override
  String parentDiagnosticsStats(
    int requests,
    int coalesced,
    int streamErrors,
    int unsubscribeFailures,
  ) {
    return 'Solicitudes $requests · Fusionadas $coalesced · Errores de stream $streamErrors · Fallos al desuscribir $unsubscribeFailures';
  }

  @override
  String parentDiagnosticsLastError(String error) {
    return 'Último error: $error';
  }

  @override
  String get parentDiagnosticsPackageUnavailable =>
      'Identificador de paquete no disponible en esta plataforma.';

  @override
  String get parentDiagnosticsLaunchTriage => 'Diagnóstico de inicio';

  @override
  String parentDiagnosticsLaunchIssuesNeedAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# problemas de inicio necesitan atención',
      one: '# problema de inicio necesita atención',
    );
    return '$_temp0';
  }

  @override
  String get parentDiagnosticsNoLaunchIssues =>
      'Sin problemas de inicio en cola ahora mismo';

  @override
  String parentDiagnosticsLaunchDetail(
    int actions,
    int shares,
    int reports,
    int downloads,
  ) {
    return '$actions acción(es) en cola · $shares problema(s) de compartido · $reports problema(s) de reporte · $downloads problema(s) de descarga';
  }

  @override
  String get parentDiagnosticsNoActiveSubscriptions =>
      'Sin suscripciones de relay activas ahora mismo.';

  @override
  String get parentDiagnosticsNoRetriesWaiting =>
      'Nada está esperando reintento de compartidos, reportes o descargas remotas.';

  @override
  String get parentDiagnosticsReportsSection => 'Reportes';

  @override
  String get parentDiagnosticsRemoteDownloadsSection => 'Descargas remotas';

  @override
  String get parentJoiningEllipsis => 'Uniéndose...';

  @override
  String parentPendingWelcomeDetail(String inviter, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# miembros',
      one: '# miembro',
    );
    return 'De $inviter · $_temp0';
  }

  @override
  String get parentRetryWaitingDetail =>
      'Reintenta cuando quieras enviar el trabajo pendiente.';

  @override
  String get parentPinUnlockDetail =>
      'Ingresa tu PIN de cuatro dígitos para abrir la configuración familiar, aprobaciones y controles de seguridad.';

  @override
  String get parentFamilyControls => 'Controles familiares';

  @override
  String get parentPinSetupRequired => 'Debes configurar el PIN';

  @override
  String get parentProtectedByPin => 'Protegido por PIN de padre';

  @override
  String get parentActivityRecentShares => 'Compartidos recientes';

  @override
  String get parentActivityFamilyFeedback => 'Comentarios familiares';

  @override
  String get parentActivityNoIncoming =>
      'Sin comentarios familiares entrantes ahora mismo.';

  @override
  String get parentActivityOutbound => 'Comentarios que compartiste';

  @override
  String get parentActivityNoReports =>
      'Sin reportes todavía. Si un niño marca un video, verás el estado de entrega aquí.';

  @override
  String get parentActivityModeration => 'Actividad de moderación';

  @override
  String get parentActivityNoModeration =>
      'Sin acciones de moderación todavía.';

  @override
  String get playerSharingAction => 'Compartiendo';
}
