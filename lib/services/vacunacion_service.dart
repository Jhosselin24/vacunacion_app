import 'package:hive_flutter/hive_flutter.dart';
import 'package:postgrest/postgrest.dart'; // ✅ Fix: import para PostgrestFilterBuilder
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/vacunacion.dart';
import '../core/constants.dart';

class VacunacionService {
  final _supabase = Supabase.instance.client;
  final _uuid     = const Uuid();

  Box get _hiveBox => Hive.box(AppConstants.hiveBoxVacunaciones);

  // ── Pendientes offline ─────────────────────────────────────
  int get pendientesOffline => _hiveBox.length;

  // ── Obtener vacunaciones ───────────────────────────────────
  Future<List<Vacunacion>> getVacunaciones({
    String? vacunadorId,
    String? sectorId,
  }) async {
    try {
      // ✅ Fix: aplicar .eq() antes de .order() para evitar error de tipo
      PostgrestFilterBuilder query = _supabase
          .from('vacunaciones')
          .select('*, usuarios(nombres, apellidos), sectores(nombre)');

      if (vacunadorId != null) {
        query = query.eq('vacunador_id', vacunadorId);
      }
      if (sectorId != null) {
        query = query.eq('sector_id', sectorId);
      }

      final data = await query.order('fecha', ascending: false);
      return (data as List).map((e) => Vacunacion.fromJson(e)).toList();
    } catch (e) {
      return _getVacunacionesOffline(
        vacunadorId: vacunadorId,
        sectorId: sectorId,
      );
    }
  }

  // ── Registrar vacunación ───────────────────────────────────
  Future<String?> registrarVacunacion(Vacunacion vacunacion) async {
    try {
      await _supabase
          .from('vacunaciones')
          .insert(vacunacion.toInsertJson());
      return null;
    } catch (e) {
      await _guardarOffline(vacunacion.copyWith(sincronizado: false));
      return null;
    }
  }

  // ── Editar vacunación ──────────────────────────────────────
  Future<String?> editarVacunacion(Vacunacion vacunacion) async {
    try {
      await _supabase
          .from('vacunaciones')
          .update(vacunacion.toUpdateJson())
          .eq('id', vacunacion.id);
      return null;
    } on PostgrestException catch (e) {
      return 'Error al actualizar: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // ── Eliminar vacunación ────────────────────────────────────
  Future<String?> eliminarVacunacion(String id) async {
    try {
      await _supabase.from('vacunaciones').delete().eq('id', id);
      return null;
    } catch (e) {
      return 'Error al eliminar: $e';
    }
  }

  // ── Sincronizar offline ────────────────────────────────────
  Future<int> sincronizarOffline() async {
    final pendientes = _getVacunacionesOffline();
    int sincronizados = 0;

    for (final vacunacion in pendientes) {
      try {
        await _supabase
            .from('vacunaciones')
            .insert(vacunacion.toInsertJson());
        await _hiveBox.delete(vacunacion.id);
        sincronizados++;
      } catch (_) {}
    }

    return sincronizados;
  }

  // ── Stats para dashboard ───────────────────────────────────
  Future<Map<String, dynamic>> getEstadisticas({String? sectorId}) async {
    try {
      // ✅ Fix: aplicar .eq() antes de ejecutar la query
      PostgrestFilterBuilder query = _supabase
          .from('vacunaciones')
          .select('tipo_mascota, sincronizado');

      if (sectorId != null) {
        query = query.eq('sector_id', sectorId);
      }

      final data = await query as List;
      final total  = data.length;
      final perros = data.where((v) => v['tipo_mascota'] == 'perro').length;
      final gatos  = data.where((v) => v['tipo_mascota'] == 'gato').length;

      return {
        'total':   total,
        'perros':  perros,
        'gatos':   gatos,
        'offline': pendientesOffline,
      };
    } catch (e) {
      return {
        'total': 0, 'perros': 0, 'gatos': 0,
        'offline': pendientesOffline,
      };
    }
  }

  // ── Stats por sector ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> getVacunasPorSector() async {
    try {
      final data = await _supabase.rpc('vacunas_por_sector');
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      return [];
    }
  }

  // ── Stats por vacunador ────────────────────────────────────
  Future<List<Map<String, dynamic>>> getVacunasPorVacunador() async {
    try {
      final data = await _supabase.rpc('vacunas_por_vacunador');
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      return [];
    }
  }

  // ── Privados Hive ──────────────────────────────────────────
  Future<void> _guardarOffline(Vacunacion vacunacion) async {
    final id = vacunacion.id.isEmpty ? _uuid.v4() : vacunacion.id;
    await _hiveBox.put(id, vacunacion.toHiveMap());
  }

  List<Vacunacion> _getVacunacionesOffline({
    String? vacunadorId,
    String? sectorId,
  }) {
    return _hiveBox.values
        .map((v) => Vacunacion.fromHiveMap(v as Map))
        .where((v) {
          if (vacunadorId != null && v.vacunadorId != vacunadorId) return false;
          if (sectorId != null && v.sectorId != sectorId) return false;
          return true;
        })
        .toList();
  }
}