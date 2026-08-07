/// Cadenas visibles para el usuario.
///
/// Centralizadas aquí para facilitar su migración a un sistema de
/// internacionalización (p. ej. ARB) en una fase posterior.
abstract final class AppStrings {
  static const String appName = 'Lector Inteligente';
  static const String appTagline =
      'Traduce tus libros digitales sin perder el texto original.';
  static const String home = 'Inicio';
  static const String gallery = 'Galería';
  static const String uploadDocument = 'Cargar documento';
  static const String openGallery = 'Ir a la galería';
  static const String recentlyViewed = 'Documentos recientes';
  static const String recentEmptyHint = 'Los documentos que abras aparecerán aquí.';
  static const String featurePlaceholder =
      'Esta funcionalidad estará disponible próximamente.';

  // Autenticación
  static const String login = 'Iniciar sesión';
  static const String register = 'Registrarse';
  static const String logout = 'Cerrar sesión';
  static const String profile = 'Perfil';
  static const String email = 'Correo electrónico';
  static const String password = 'Contraseña';
  static const String confirmPassword = 'Confirmar contraseña';
  static const String firstName = 'Nombre';
  static const String lastName = 'Apellido';
  static const String fullName = 'Nombre completo';
  static const String dontHaveAccount = '¿No tienes cuenta?';
  static const String alreadyHaveAccount = '¿Ya tienes cuenta?';
  static const String changePassword = 'Cambiar contraseña';
  static const String currentPassword = 'Contraseña actual';
  static const String newPassword = 'Nueva contraseña';
  static const String saveChanges = 'Guardar cambios';
  static const String deleteAccount = 'Eliminar cuenta';
  static const String deleteAccountConfirm =
      '¿Seguro que deseas eliminar tu cuenta? Esta acción no se puede deshacer.';
  static const String cancel = 'Cancelar';
  static const String confirm = 'Confirmar';
  static const String invalidEmail = 'Ingresa un correo electrónico válido.';
  static const String shortPassword = 'La contraseña debe tener al menos 8 caracteres.';
  static const String passwordMismatch = 'Las contraseñas no coinciden.';
  static const String requiredField = 'Este campo es obligatorio.';
  static const String profileUpdated = 'Perfil actualizado correctamente.';
  static const String passwordChanged = 'Contraseña actualizada correctamente.';
  static const String accountDeleted = 'Cuenta eliminada correctamente.';
  static const String sessionClosed = 'Sesión cerrada correctamente.';
  static const String welcomeBack = 'Bienvenido de nuevo';
  static const String createAccount = 'Crea tu cuenta';

  // Documentos
  static const String searchDocuments = 'Buscar en mis documentos';
  static const String emptyGallery =
      'Aún no tienes documentos. Sube tu primer libro para comenzar.';
  static const String uploadDocumentHint = 'Selecciona un archivo PDF o EPUB';
  static const String deleteDocument = 'Eliminar documento';
  static const String deleteDocumentConfirm =
      '¿Seguro que deseas eliminar este documento? No se puede deshacer.';
  static const String documentUploaded = 'Documento subido correctamente.';
  static const String documentDeleted = 'Documento eliminado correctamente.';
  static const String loadMore = 'Cargar más';
  static const String galleryLoginRequired =
      'Inicia sesión para ver tu galería de documentos.';
  static const String selectFile = 'Seleccionar archivo';
  static const String uploadingDocument = 'Subiendo documento…';
  static const String fileTooLarge = 'El archivo supera el tamaño máximo de 50 MB.';
  static const String invalidFileFormat = 'Solo se admiten archivos PDF o EPUB.';

  // Traducciones
  static const String translate = 'Traducir';
  static const String translating = 'Traduciendo…';
  static const String selectLanguage = 'Seleccionar idioma de destino';
  static const String translationStarted = 'Traducción iniciada.';
  static const String translationAvailable = 'Traducción disponible.';
  static const String translationFailed = 'No se pudo iniciar la traducción.';
  static const String deleteTranslation = 'Eliminar traducción';
  static const String deleteTranslationConfirm =
      '¿Seguro que deseas eliminar esta traducción?';
  static const String translationDeleted = 'Traducción eliminada correctamente.';
  static const String statusPending = 'Pendiente';
  static const String statusProcessing = 'En proceso';
  static const String statusCompleted = 'Completada';
  static const String statusPartial = 'Con errores';
  static const String statusFailed = 'Fallida';
  static const String translationsUnavailable = 'Traducciones no disponibles.';

  // Lector
  static const String readerOriginal = 'Original';
  static const String readerTranslation = 'Traducción';
  static const String readerOriginalOnly = 'Solo original';
  static const String readerNoTranslation =
      'Selecciona un idioma para ver la traducción.';
  static const String readerEmptyPage = 'Esta página no tiene contenido.';
  static const String readerPrevious = 'Página anterior';
  static const String readerNext = 'Página siguiente';
  static const String retry = 'Reintentar';
  static String readerPageOf(int page, int total) =>
      'Página $page de $total';
}
