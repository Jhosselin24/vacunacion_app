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

  // ── Crear usuario via Edge Function ─────────────────────────
  // ✅ Fix: la creación de usuarios de Auth requiere la Admin API de
  // Supabase (service_role key), que nunca debe vivir en el cliente
  // Flutter. Por eso se invoca una Edge Function (`crear-usuario`)
  // que corre en el servidor con esa clave y crea tanto el usuario
  // de Auth como su fila en `public.usuarios` de forma atómica.
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
      final response = await _supabase.functions.invoke(
        'crear-usuario',
        body: {
          'email':     email,
          'password':  AppConstants.passwordInicial,
          'cedula':    cedula,
          'nombres':   nombres,
          'apellidos': apellidos,
          'telefono':  telefono,
          'rol':       rol,
          'sector_id': sectorId,
        },
      );

      final data = response.data;

      // La Edge Function responde con status != 200 en caso de error,
      // pero el cliente de supabase_flutter igual entrega `data` con
      // el cuerpo del error en ese caso.
      if (data is Map && data['error'] != null) {
        return data['error'] as String;
      }

      return null; // null = éxito
    } on FunctionException catch (e) {
      final detalle = e.details;
      if (detalle is Map && detalle['error'] != null) {
        return detalle['error'] as String;
      }
      return 'Error al crear usuario (${e.status})';
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

  // ── Eliminar usuario via Edge Function ─────────────────────
  // ✅ Fix: eliminar el auth user requiere la Admin API (service_role
  // key), igual que crearlo. Antes solo se borraba la fila de
  // `public.usuarios`, lo cual además podía no hacer nada en
  // silencio si RLS bloqueaba el DELETE (sin lanzar excepción).
  Future<String?> eliminarUsuario(String id) async {
    try {
      final response = await _supabase.functions.invoke(
        'eliminar-usuario',
        body: {'id': id},
      );

      final data = response.data;
      if (data is Map && data['error'] != null) {
        return data['error'] as String;
      }

      return null; // null = éxito
    } on FunctionException catch (e) {
      final detalle = e.details;
      if (detalle is Map && detalle['error'] != null) {
        return detalle['error'] as String;
      }
      return 'Error al eliminar usuario (${e.status})';
    } catch (e) {
      return 'Error inesperado: $e';
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