import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/local_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _localStorage = LocalStorageService();

  Map<String, dynamic>? _usuarioData;
  bool _isLoading = false;
  StreamSubscription? _authSubscription;

  // ── Constructor: escuchar cambios de sesión ────────────────
  AuthProvider() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final user  = data.session?.user;

      debugPrint('🔔 AuthEvent: $event');

      if (event == AuthChangeEvent.signedIn && user != null) {
        if (_usuarioData == null) {
          await _cargarUsuario(user.id);
          notifyListeners();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _usuarioData = null;
        notifyListeners();
      } else if (event == AuthChangeEvent.tokenRefreshed && user != null) {
        if (_usuarioData == null) {
          await _cargarUsuario(user.id);
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // ── Getters ────────────────────────────────────────────────
  bool get isLoggedIn  => _supabase.auth.currentUser != null && _usuarioData != null;
  bool get isLoading   => _isLoading;
  String? get rol      => _usuarioData?['rol'];
  String? get userId   => _supabase.auth.currentUser?.id;
  String? get sectorId => _usuarioData?['sector_id'];
  bool get primerLogin => _usuarioData?['primer_login'] ?? false;
  Map<String, dynamic>? get usuarioData => _usuarioData;

  String get nombreCompleto {
    if (_usuarioData == null) return '';
    return '${_usuarioData!['nombres']} ${_usuarioData!['apellidos']}';
  }

  // ── Inicializar sesión guardada ────────────────────────────
  // ✅ Fix: si no hay conexión, se usa el perfil guardado en Hive
  // (LocalStorageService) para no dejar al usuario sin sesión solo
  // porque la consulta a Supabase falló por falta de red. Si hay
  // conexión, se intenta refrescar el perfil desde el servidor.
  Future<void> inicializarSesion() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // 1. Cargar primero lo que haya en caché local (instantáneo,
        //    funciona sin conexión).
        final cache = _localStorage.leerUsuario();
        if (cache != null && cache['id'] == user.id) {
          _usuarioData = cache;
        }

        // 2. Intentar refrescar desde Supabase. Si falla (sin
        //    conexión, por ejemplo) y ya tenemos caché, se conserva
        //    la sesión con los datos locales.
        await _cargarUsuario(user.id, mantenerSiFalla: _usuarioData != null);
      }
    } catch (e) {
      debugPrint('Error inicializando sesión: $e');
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

      // Cargar usuario directamente sin depender del listener
      await _cargarUsuario(response.user!.id);

      if (_usuarioData == null) {
        await _supabase.auth.signOut();
        return 'No se encontró el perfil del usuario. Contacta al administrador.';
      }

      // ✅ Notificar ANTES de retornar, para que el router vea isLoggedIn = true
      _isLoading = false;
      notifyListeners();

      debugPrint('✅ Login exitoso: ${_usuarioData!['email']} | rol: ${_usuarioData!['rol']}');
      return null;

    } on AuthException catch (e) {
      debugPrint('AuthException en login: ${e.message}');
      return _mensajeError(e.message);
    } catch (e) {
      debugPrint('Error inesperado en login: $e');
      return 'Error inesperado: $e';
    } finally {
      // Solo actualiza si aún no lo hicimos (caso de error)
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // ── Logout ─────────────────────────────────────────────────
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _usuarioData = null;
    await _localStorage.limpiarSesion();
    notifyListeners();
  }

  // ── Cambiar contraseña ─────────────────────────────────────
  // ✅ Fix: antes, si el UPDATE de `primer_login` era bloqueado en
  // silencio por RLS (0 filas afectadas, sin lanzar excepción), el
  // cambio solo quedaba en memoria local. Al cerrar sesión y volver
  // a entrar, `_cargarUsuario()` releía `primer_login: true` desde
  // Supabase y la app pedía cambiar la contraseña otra vez. Ahora se
  // usa `.select()` para detectar si realmente se actualizó alguna
  // fila, y se informa el error en vez de fallar en silencio.
  Future<String?> cambiarPassword(String nuevaPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: nuevaPassword),
      );

      final actualizado = await _supabase
          .from('usuarios')
          .update({'primer_login': false})
          .eq('id', userId!)
          .select();

      if ((actualizado as List).isEmpty) {
        // El UPDATE no afectó ninguna fila: probablemente RLS lo
        // bloqueó. La contraseña en Auth SÍ se cambió, pero no se
        // pudo marcar primer_login = false.
        return 'La contraseña se cambió, pero no se pudo actualizar '
            'tu perfil. Contacta al administrador (revisar permisos '
            'de actualización en la tabla usuarios).';
      }

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

  // ── Cargar datos del usuario desde Supabase ────────────────
  // ✅ Fix: usa LocalStorageService en lugar de tocar la Hive box
  // directamente, y permite conservar los datos ya cargados
  // (de caché) si la consulta de red falla, en vez de borrarlos.
  Future<void> _cargarUsuario(String userId, {bool mantenerSiFalla = false}) async {
    try {
      final data = await _supabase
          .from('usuarios')
          .select()
          .eq('id', userId)
          .single();

      _usuarioData = data;
      await _localStorage.guardarUsuario(data);

      debugPrint('✅ Usuario cargado: ${data['email']} | rol: ${data['rol']}');
    } catch (e) {
      if (!mantenerSiFalla) {
        _usuarioData = null;
      }
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