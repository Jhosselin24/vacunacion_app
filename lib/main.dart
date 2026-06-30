import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/constants.dart';
import 'core/supabase.dart';

// Screens
import 'screens/login/login_page.dart';
import 'screens/login/change_password.dart';
import 'screens/login/forgot_password.dart';
import 'screens/dashboard/admin_dashboard.dart';
import 'screens/dashboard/brigada_dashboard.dart';
import 'screens/dashboard/vacunador_dashboard.dart';
import 'screens/sectores/sector_page.dart';
import 'screens/sectores/add_sector_page.dart';
import 'screens/sectores/mi_sector_page.dart';
import 'screens/usuarios/user_list_page.dart';
import 'screens/usuarios/user_form_page.dart';
import 'screens/vacunacion/registro_vacunacion_page.dart';
import 'screens/vacunacion/vacunacion_list_page.dart';

// Provider
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox(AppConstants.hiveBoxVacunaciones);
  await Hive.openBox(AppConstants.hiveBoxUsuario);

  await initializeDateFormatting('es', null);

  // ✅ Fix: la URL y la anon key ya no están duplicadas aquí; viven
  // únicamente en core/supabase.dart (SupabaseConfig).
  await SupabaseConfig.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider()..inicializarSesion();
    _router = _buildRouter(_authProvider);
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _authProvider,
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading && authProvider.usuarioData == null) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.theme,
              home: const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            );
          }

          return MaterialApp.router(
            title: 'Vacunación',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            routerConfig: _router,
          );
        },
      ),
    );
  }

  GoRouter _buildRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppConstants.routeLogin,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final logged    = authProvider.isLoggedIn;
        final location  = state.matchedLocation;
        final isPublica = location == AppConstants.routeLogin ||
                          location == AppConstants.routeForgotPassword ||
                          location == AppConstants.routeChangePassword;

        // No logueado: solo puede estar en rutas públicas
        if (!logged && !isPublica) return AppConstants.routeLogin;

        if (logged) {
          // Si es primer login, siempre ir a change-password
          if (authProvider.primerLogin &&
              location != AppConstants.routeChangePassword) {
            return AppConstants.routeChangePassword;
          }
          // Si ya cambió contraseña y está en login, ir al dashboard
          if (location == AppConstants.routeLogin) {
            return _routeByRole(authProvider.rol);
          }
        }
        return null;
      },
      routes: [
        GoRoute(
          path: AppConstants.routeLogin,
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: AppConstants.routeChangePassword,
          builder: (_, __) => const ChangePasswordPage(),
        ),
        GoRoute(
          path: AppConstants.routeForgotPassword,
          builder: (_, __) => const ForgotPasswordPage(),
        ),

        // Dashboards
        GoRoute(
          path: AppConstants.routeAdminDashboard,
          builder: (_, __) => const AdminDashboard(),
        ),
        GoRoute(
          path: AppConstants.routeBrigadaDashboard,
          builder: (_, __) => const BrigadaDashboard(),
        ),
        GoRoute(
          path: AppConstants.routeVacunadorDashboard,
          builder: (_, __) => const VacunadorDashboard(),
        ),

        // Sectores
        GoRoute(
          path: AppConstants.routeSectores,
          builder: (_, __) => const SectorPage(),
        ),
        GoRoute(
          path: AppConstants.routeAddSector,
          builder: (_, __) => const AddSectorPage(),
        ),
        GoRoute(
          path: AppConstants.routeMiSector,
          builder: (_, __) => const MiSectorPage(),
        ),

        // Usuarios
        // Usuarios
GoRoute(
  path: AppConstants.routeUsuarios,
  builder: (_, __) => const UserListPage(),  // ← lista, no formulario
),
GoRoute(
  path: AppConstants.routeAddUsuario,
  builder: (context, state) {
    final extra = state.extra;
    Map<String, dynamic>? usuarioEditar;
    if (extra is Map<String, dynamic>) {
      usuarioEditar = extra;
    }
    return UserFormPage(usuarioEditar: usuarioEditar);
  },
),

        // Vacunación
        GoRoute(
          path: AppConstants.routeRegistroVacunacion,
          builder: (_, __) => const RegistroVacunacionPage(),
        ),
        GoRoute(
          path: AppConstants.routeVacunaciones,
          builder: (_, __) => const VacunacionListPage(),
        ),
        GoRoute(
          path: AppConstants.routeEditVacunacion,
          builder: (_, state) => RegistroVacunacionPage(
            vacunacionEditar: state.extra as Map<String, dynamic>?,
          ),
        ),
      ],
    );
  }

  String _routeByRole(String? rol) {
    switch (rol) {
      case AppRoles.coordinadorCampania:
        return AppConstants.routeAdminDashboard;
      case AppRoles.coordinadorBrigada:
        return AppConstants.routeBrigadaDashboard;
      case AppRoles.vacunador:
        return AppConstants.routeVacunadorDashboard;
      default:
        return AppConstants.routeLogin;
    }
  }
}