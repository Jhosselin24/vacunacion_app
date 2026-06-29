import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// COLORES - Tema Rosa
// ══════════════════════════════════════════════════════════════
class AppColors {
  // Primarios
  static const Color primary        = Color(0xFFE91E8C); // Rosa fuerte
  static const Color primaryLight   = Color(0xFFF06292); // Rosa claro
  static const Color primaryDark    = Color(0xFFC2185B); // Rosa oscuro
  static const Color primarySurface = Color(0xFFFCE4EC); // Fondo rosa muy suave

  // Secundarios
  static const Color secondary      = Color(0xFFFF80AB); // Rosa pastel
  static const Color secondaryDark  = Color(0xFFF50057); // Acento fuerte

  // Neutros
  static const Color white          = Color(0xFFFFFFFF);
  static const Color background     = Color(0xFFFFF0F5); // Fondo general rosado
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color cardColor      = Color(0xFFFFFFFF);

  // Texto
  static const Color textPrimary    = Color(0xFF212121);
  static const Color textSecondary  = Color(0xFF757575);
  static const Color textOnPrimary  = Color(0xFFFFFFFF);

  // Estado
  static const Color success        = Color(0xFF4CAF50);
  static const Color error          = Color(0xFFF44336);
  static const Color warning        = Color(0xFFFF9800);
  static const Color info           = Color(0xFF2196F3);

  // Dashboard cards
  static const Color cardPerros     = Color(0xFF7C4DFF); // Morado
  static const Color cardGatos      = Color(0xFF00BCD4); // Cyan
  static const Color cardTotal      = Color(0xFFE91E8C); // Rosa
  static const Color cardPendientes = Color(0xFFFF9800); // Naranja
}

// ══════════════════════════════════════════════════════════════
// TEMA GLOBAL
// ══════════════════════════════════════════════════════════════
class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      brightness: Brightness.light,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textOnPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: AppColors.textOnPrimary),
    ),

    // Scaffold
    scaffoldBackgroundColor: AppColors.background,

    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // OutlinedButton
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // TextButton
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // InputDecoration (campos de texto)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      floatingLabelStyle: const TextStyle(color: AppColors.primary),
      prefixIconColor: AppColors.primary,
      suffixIconColor: AppColors.textSecondary,
    ),

    // Card
    cardTheme: CardThemeData(
      elevation: 2,
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    ),

    // FloatingActionButton
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 4,
    ),

    // BottomNavigationBar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppColors.white,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primarySurface,
      labelStyle: const TextStyle(color: AppColors.primary),
      side: const BorderSide(color: AppColors.primaryLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEEEEEE),
      thickness: 1,
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: const TextStyle(color: AppColors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// ROLES
// ══════════════════════════════════════════════════════════════
class AppRoles {
  static const String coordinadorCampania = 'coordinador_campania';
  static const String coordinadorBrigada  = 'coordinador_brigada';
  static const String vacunador           = 'vacunador';

  static String nombreLegible(String rol) {
    switch (rol) {
      case coordinadorCampania: return 'Coordinador de Campaña';
      case coordinadorBrigada:  return 'Coordinador de Brigada';
      case vacunador:           return 'Vacunador';
      default:                  return 'Desconocido';
    }
  }

  static IconData iconoPorRol(String rol) {
    switch (rol) {
      case coordinadorCampania: return Icons.admin_panel_settings;
      case coordinadorBrigada:  return Icons.groups;
      case vacunador:           return Icons.medical_services;
      default:                  return Icons.person;
    }
  }
}

// ══════════════════════════════════════════════════════════════
// CONSTANTES GENERALES
// ══════════════════════════════════════════════════════════════
class AppConstants {
  // Contraseña inicial
  static const String passwordInicial = 'Ecuador2026';

  // Supabase Storage
  static const String bucketFotos = 'fotos-vacunacion';

  // Tipos de mascota
  static const List<String> tiposMascota = ['perro', 'gato'];

  // Sexos
  static const List<String> sexos = ['macho', 'hembra'];

  // Vacunas disponibles
  static const List<String> vacunas = [
    'Antirrábica',
    'Polivalente (DHPPI)',
    'Bordetella',
    'Leptospirosis',
    'Triple Felina (HRCPi)',
    'Leucemia Felina (FeLV)',
  ];

  // Nombres de rutas
  static const String routeLogin          = '/';
  static const String routeChangePassword = '/change-password';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeAdminDashboard = '/admin';
  static const String routeBrigadaDashboard = '/brigada';
  static const String routeVacunadorDashboard = '/vacunador';
  static const String routeSectores       = '/sectores';
  static const String routeAddSector      = '/sectores/add';
  static const String routeUsuarios       = '/usuarios';
  static const String routeAddUsuario     = '/usuarios/form';
  static const String routeVacunaciones   = '/vacunaciones';
  static const String routeRegistroVacunacion = '/vacunaciones/registro';
  static const String routeEditVacunacion = '/vacunaciones/edit';

  // Hive box names (offline)
  static const String hiveBoxVacunaciones = 'vacunaciones_offline';
  static const String hiveBoxUsuario      = 'usuario_sesion';
}

// ══════════════════════════════════════════════════════════════
// ESTILOS DE TEXTO REUTILIZABLES
// ══════════════════════════════════════════════════════════════
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle dashboardNumber = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle dashboardLabel = TextStyle(
    fontSize: 13,
    color: AppColors.white,
    fontWeight: FontWeight.w500,
  );
}