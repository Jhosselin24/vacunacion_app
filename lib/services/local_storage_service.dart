import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';

/// Persiste la sesión del usuario localmente para que la app
/// funcione offline (leer nombre, rol, sectorId sin Supabase).
class LocalStorageService {
  Box get _boxUsuario => Hive.box(AppConstants.hiveBoxUsuario);

  // ── Guardar datos del usuario ──────────────────────────────
  Future<void> guardarUsuario(Map<String, dynamic> data) async {
    try {
      await _boxUsuario.put('usuario', data);
    } catch (e) {
      debugPrint('❌ LocalStorage guardarUsuario: $e');
    }
  }

  // ── Leer datos del usuario ─────────────────────────────────
  Map<String, dynamic>? leerUsuario() {
    try {
      final raw = _boxUsuario.get('usuario');
      if (raw == null) return null;
      return Map<String, dynamic>.from(raw as Map);
    } catch (e) {
      debugPrint('❌ LocalStorage leerUsuario: $e');
      return null;
    }
  }

  // ── Borrar sesión ──────────────────────────────────────────
  Future<void> limpiarSesion() async {
    try {
      await _boxUsuario.clear();
    } catch (e) {
      debugPrint('❌ LocalStorage limpiarSesion: $e');
    }
  }

  // ── Getters de conveniencia ────────────────────────────────
  String? get rolGuardado     => leerUsuario()?['rol'] as String?;
  String? get sectorIdGuardado => leerUsuario()?['sector_id'] as String?;
  String? get nombreGuardado  {
    final u = leerUsuario();
    if (u == null) return null;
    return '${u['nombres']} ${u['apellidos']}';
  }
  bool get primerLoginGuardado =>
      leerUsuario()?['primer_login'] as bool? ?? false;
}