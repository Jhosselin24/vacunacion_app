import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'core/constants.dart';

// Screens
import 'screens/login/login_page.dart';
import 'screens/login/change_password.dart';
import 'screens/login/forgot_password.dart';
import 'screens/dashboard/admin_dashboard.dart';
import 'screens/dashboard/brigada_dashboard.dart';
import 'screens/dashboard/vacunador_dashboard.dart';
import 'screens/sectores/sector_page.dart';
import 'screens/sectores/add_sector_page.dart';
import 'screens/usuarios/user_list_page.dart';
import 'screens/usuarios/user_form_page.dart' as user_form; // ✅ Fix: prefijo para evitar conflicto
import 'screens/vacunacion/registro_vacunacion_page.dart';

// Providers
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive (offline)
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.hiveBoxVacunaciones);
  await Hive.openBox(AppConstants.hiveBoxUsuario);

  // Fechas en español
  await initializeDateFormatting('es', null);

  // Supabase
  await Supabase.initialize(
    url: 'https://fafpvmnoxzhwqwbfqeso.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZhZnB2bW5veHpod3F3YmZxZXNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI0MjcyMzEsImV4cCI6MjA5ODAwMzIzMX0.gLV1v6TkOslsSo8oxudoX5Rau2FyYAPo2wjt8R-AQu0',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'Vacunación Canina y Felina',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            routerConfig: _buildRouter(authProvider),
          );
        },
      ),
    );
  }

  GoRouter _buildRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppConstants.routeLogin,
      redirect: (context, state) {
        final isLoggedIn  = authProvider.isLoggedIn;
        final isLoggingIn = state.matchedLocation == AppConstants.routeLogin;
        final isForgot    = state.matchedLocation == AppConstants.routeForgotPassword;

        if (!isLoggedIn && !isLoggingIn && !isForgot) {
          return AppConstants.routeLogin;
        }
        if (isLoggedIn && isLoggingIn) {
          return _routePorRol(authProvider.rol);
        }
        return null;
      },
      routes: [
        GoRoute(
          path: AppConstants.routeLogin,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppConstants.routeChangePassword,
          builder: (context, state) => const ChangePasswordPage(),
        ),
        GoRoute(
          path: AppConstants.routeForgotPassword,
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: AppConstants.routeAdminDashboard,
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: AppConstants.routeSectores,
          builder: (context, state) => const SectorPage(),
        ),
        GoRoute(
          path: AppConstants.routeAddSector,
          builder: (context, state) => const AddSectorPage(),
        ),
        GoRoute(
          path: AppConstants.routeUsuarios,
          builder: (context, state) => const UserListPage(),
        ),
        GoRoute(
          path: AppConstants.routeAddUsuario,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return user_form.UserFormPage(usuarioEditar: extra); // ✅ Fix: uso con prefijo
          },
        ),
        GoRoute(
          path: AppConstants.routeBrigadaDashboard,
          builder: (context, state) => const BrigadaDashboard(),
        ),
        GoRoute(
          path: AppConstants.routeVacunadorDashboard,
          builder: (context, state) => const VacunadorDashboard(),
        ),
        GoRoute(
          path: AppConstants.routeRegistroVacunacion,
          builder: (context, state) => RegistroVacunacionPage(), // ✅ Fix: sin const
        ),
        GoRoute(
          path: AppConstants.routeEditVacunacion,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return RegistroVacunacionPage(vacunacionEditar: extra); // ✅ Fix: sin const
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Página no encontrada')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Ruta no encontrada', style: AppTextStyles.body),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppConstants.routeLogin),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _routePorRol(String? rol) {
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