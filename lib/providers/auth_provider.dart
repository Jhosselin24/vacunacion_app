import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _usuarioData;
  bool _isLoading = false;

  // ── Getters ────────────────────────────────────────────────
  bool get isLoggedIn    => _supabase.auth.currentUser != null && _usuarioData != null;
  bool get isLoading     => _isLoading;
  String? get rol        => _usuarioData?['rol'];
  String? get userId     => _supabase.auth.currentUser?.id;
  String? get sectorId   => _usuarioData?['sector_id'];
  bool get primerLogin   => _usuarioData?['primer_login'] ?? false;
  Map<String, dynamic>? get usuarioData => _usuarioData;

  String get nombreCompleto {
    if (_usuarioData == null) return '';
    return '${_usuarioData!['nombres']} ${_usuarioData!['apellidos']}';
  }

  // ── Inicializar sesión guardada ────────────────────────────
  Future<void> inicializarSesion() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _cargarUsuario(user.id);
      }
    } catch (e) {
      debugPrint('Error inicializando sesión: $e');
      _usuarioData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Login ──────────────────────────────────────────────────
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) return 'Credenciales incorrectas';

      // ✅ Fix: reintentar carga de usuario hasta 3 veces con delay creciente
      // para dar tiempo a que la sesión JWT se propague en Supabase
      Map<String, dynamic>? data;
      for (int i = 0; i < 3; i++) {
        await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
        data = await _intentarCargarUsuario(response.user!.id);
        if (data != null) break;
        debugPrint('⏳ Intento ${i + 1} fallido, reintentando...');
      }

      if (data == null) {
        await _supabase.auth.signOut();
        return 'No se encontró el perfil del usuario. Contacta al administrador.';
      }

      _usuarioData = data;

      // Guardar en Hive para acceso offline
      final box = Hive.box(AppConstants.hiveBoxUsuario);
      await box.put('usuario', data);

      debugPrint('✅ Login exitoso: ${data['email']} | rol: ${data['rol']}');
      return null;

    } on AuthException catch (e) {
      debugPrint('AuthException en login: ${e.message}');
      return _mensajeError(e.message);
    } catch (e) {
      debugPrint('Error inesperado en login: $e');
      return 'Error inesperado: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Logout ─────────────────────────────────────────────────
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _usuarioData = null;
    final box = Hive.box(AppConstants.hiveBoxUsuario);
    await box.clear();
    notifyListeners();
  }

  // ── Cambiar contraseña ─────────────────────────────────────
  Future<String?> cambiarPassword(String nuevaPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: nuevaPassword),
      );

      await _supabase
          .from('usuarios')
          .update({'primer_login': false})
          .eq('id', userId!);

      _usuarioData!['primer_login'] = false;
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return _mensajeError(e.message);
    } catch (e) {
      return 'Error al cambiar contraseña: $e';
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
      return 'Error al enviar correo: $e';
    }
  }

  // ── Intentar cargar usuario (sin lanzar excepción) ─────────
  Future<Map<String, dynamic>?> _intentarCargarUsuario(String userId) async {
    try {
      final data = await _supabase
          .from('usuarios')
          .select()
          .eq('id', userId)
          .single();
      return data;
    } catch (e) {
      debugPrint('❌ Error cargando usuario ($userId): $e');
      return null;
    }
  }

  // ── Cargar datos del usuario desde Supabase ────────────────
  Future<void> _cargarUsuario(String userId) async {
    try {
      final data = await _supabase
          .from('usuarios')
          .select()
          .eq('id', userId)
          .single();

      _usuarioData = data;

      final box = Hive.box(AppConstants.hiveBoxUsuario);
      await box.put('usuario', data);

      debugPrint('✅ Usuario cargado: ${data['email']} | rol: ${data['rol']}');
    } catch (e) {
      _usuarioData = null;
      debugPrint('❌ Error cargando usuario ($userId): $e');
    }
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