import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // ── Usuario actual ─────────────────────────────────────────
  User? get currentAuthUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentAuthUser != null;

  // ── Login ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return {'error': 'Credenciales incorrectas'};
      }

      final usuario = await getUsuarioActual();
      if (usuario == null) {
        return {'error': 'Usuario no encontrado en el sistema'};
      }

      return {'usuario': usuario};
    } on AuthException catch (e) {
      return {'error': _mensajeError(e.message)};
    } catch (e) {
      return {'error': 'Error inesperado al iniciar sesión'};
    }
  }

  // ── Logout ─────────────────────────────────────────────────
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // ── Obtener usuario actual desde tabla usuarios ────────────
  Future<Usuario?> getUsuarioActual() async {
    try {
      final userId = currentAuthUser?.id;
      if (userId == null) return null;

      final data = await _supabase
          .from('usuarios')
          .select()
          .eq('id', userId)
          .single();

      return Usuario.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ── Cambiar contraseña ─────────────────────────────────────
  Future<String?> cambiarPassword(String nuevaPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: nuevaPassword),
      );

      final userId = currentAuthUser?.id;
      if (userId != null) {
        await _supabase
            .from('usuarios')
            .update({'primer_login': false})
            .eq('id', userId);
      }

      return null;
    } on AuthException catch (e) {
      return _mensajeError(e.message);
    } catch (e) {
      return 'Error al cambiar contraseña';
    }
  }

  // ── Recuperar contraseña por email ─────────────────────────
  Future<String?> recuperarPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return _mensajeError(e.message);
    } catch (e) {
      return 'Error al enviar correo de recuperación';
    }
  }

  // ── Crear usuario ──────────────────────────────────────────
  // ✅ Fix: eliminado auth.admin.createUser (requería service_role key)
  // La creación de usuarios ahora se hace via RPC en UserService
  Future<Map<String, dynamic>> crearUsuarioAuth({
    required String email,
    required String password,
  }) async {
    return {'error': 'Usar UserService.crearUsuario() en su lugar'};
  }

  // ── Mensajes de error legibles ─────────────────────────────
  String _mensajeError(String mensaje) {
    if (mensaje.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos';
    }
    if (mensaje.contains('Email not confirmed')) {
      return 'Correo no confirmado';
    }
    if (mensaje.contains('User already registered')) {
      return 'El correo ya está registrado';
    }
    if (mensaje.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return mensaje;
  }
}