import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import '../core/constants.dart';

class UserService {
  final _supabase = Supabase.instance.client;

  // ── Obtener todos los usuarios (coordinador campaña) ───────
  Future<List<Usuario>> getUsuarios() async {
    try {
      final data = await _supabase
          .from('usuarios')
          .select()
          .order('nombres', ascending: true);

      return (data as List).map((e) => Usuario.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error al cargar usuarios: $e');
    }
  }

  // ── Obtener usuarios por rol ───────────────────────────────
  Future<List<Usuario>> getUsuariosPorRol(String rol) async {
    try {
      final data = await _supabase
          .from('usuarios')
          .select()
          .eq('rol', rol)
          .order('nombres', ascending: true);

      return (data as List).map((e) => Usuario.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error al cargar usuarios: $e');
    }
  }

  // ── Obtener vacunadores de un sector ──────────────────────
  Future<List<Usuario>> getVacunadoresPorSector(String sectorId) async {
    try {
      final data = await _supabase
          .from('usuarios')
          .select()
          .eq('rol', AppRoles.vacunador)
          .eq('sector_id', sectorId)
          .order('nombres', ascending: true);

      return (data as List).map((e) => Usuario.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error al cargar vacunadores: $e');
    }
  }

  // ── Crear usuario via Database Function ────────────────────
  // ✅ Fix: usa RPC en lugar de auth.admin (que requiere service_role key)
  Future<String?> crearUsuario({
    required String cedula,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String email,
    required String rol,
    String? sectorId,
  }) async {
    try {
      final result = await _supabase.rpc('crear_usuario_auth', params: {
        'p_email':     email,
        'p_password':  AppConstants.passwordInicial,
        'p_cedula':    cedula,
        'p_nombres':   nombres,
        'p_apellidos': apellidos,
        'p_telefono':  telefono,
        'p_rol':       rol,
        'p_sector_id': sectorId,
      });

      if (result == null) {
        return 'El correo ya está registrado';
      }

      return null; // null = éxito
    } on PostgrestException catch (e) {
      if (e.message.contains('unique') || e.message.contains('duplicate')) {
        return 'La cédula o correo ya están registrados';
      }
      return 'Error al crear usuario: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }


  // ── Actualizar usuario ─────────────────────────────────────
  Future<String?> actualizarUsuario({
    required String id,
    required String cedula,
    required String nombres,
    required String apellidos,
    required String telefono,
    String? sectorId,
  }) async {
    try {
      await _supabase.from('usuarios').update({
        'cedula':    cedula,
        'nombres':   nombres,
        'apellidos': apellidos,
        'telefono':  telefono,
        'sector_id': sectorId,
      }).eq('id', id);

      return null;
    } on PostgrestException catch (e) {
      return 'Error al actualizar: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // ── Asignar sector a usuario ───────────────────────────────
  Future<String?> asignarSector({
    required String usuarioId,
    required String sectorId,
  }) async {
    try {
      await _supabase
          .from('usuarios')
          .update({'sector_id': sectorId})
          .eq('id', usuarioId);

      return null;
    } catch (e) {
      return 'Error al asignar sector: $e';
    }
  }

  // ── Reasignar sector ───────────────────────────────────────
  Future<String?> reasignarSector({
    required String usuarioId,
    String? nuevoSectorId,
  }) async {
    try {
      await _supabase
          .from('usuarios')
          .update({'sector_id': nuevoSectorId})
          .eq('id', usuarioId);

      return null;
    } catch (e) {
      return 'Error al reasignar sector: $e';
    }
  }

  // ── Eliminar usuario ───────────────────────────────────────
  Future<String?> eliminarUsuario(String id) async {
    try {
      await _supabase.from('usuarios').delete().eq('id', id);
      return null;
    } catch (e) {
      return 'Error al eliminar usuario: $e';
    }
  }

  // ── Buscar usuario por cédula ──────────────────────────────
  Future<Usuario?> buscarPorCedula(String cedula) async {
    try {
      final data = await _supabase
          .from('usuarios')
          .select()
          .eq('cedula', cedula)
          .maybeSingle();

      if (data == null) return null;
      return Usuario.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}