import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:postgrest/postgrest.dart'; // ✅ Fix: import para PostgrestFilterBuilder
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/vacunacion.dart';
import '../core/constants.dart';
import 'storage_service.dart';
import 'package:flutter/foundation.dart';

class VacunacionService {
  final _supabase = Supabase.instance.client;
  final _uuid     = const Uuid();
  final _storageService = StorageService();

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
    debugPrint('❌ PostgrestException editarVacunacion: ${e.message} | code: ${e.code}'); // ← agrega
    return 'Error al actualizar: ${e.message}';
  } catch (e) {
    debugPrint('❌ Error inesperado editarVacunacion: $e'); // ← agrega
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
  // ✅ Fix: si el registro tiene foto local pendiente (tomada sin
  // conexión), primero se sube a Storage y se obtiene la URL antes
  // de insertar el registro en Supabase. Si la subida de la foto
  // falla, el registro NO se elimina de Hive y se reintenta en la
  // próxima sincronización.
  Future<int> sincronizarOffline() async {
    final pendientes = _getVacunacionesOffline();
    int sincronizados = 0;

    for (final vacunacion in pendientes) {
      try {
        var vacunacionFinal = vacunacion;

        // Si hay foto local y todavía no se subió, subirla ahora.
        if (vacunacion.fotoUrl == null &&
            vacunacion.fotoLocal != null &&
            vacunacion.fotoLocal!.isNotEmpty) {
          final file = File(vacunacion.fotoLocal!);
          if (await file.exists()) {
            final resultado = await _storageService.subirFoto(
              foto: file,
              vacunadorId: vacunacion.vacunadorId ?? 'unknown',
            );

            if (resultado.containsKey('error')) {
              // No se pudo subir la foto todavía (sigue sin haber
              // buena conexión, por ejemplo). Se deja pendiente.
              continue;
            }

            vacunacionFinal = vacunacion.copyWith(
              fotoUrl: resultado['url'] as String,
            );
          }
        }

        await _supabase
            .from('vacunaciones')
            .insert(vacunacionFinal.toInsertJson());
        await _hiveBox.delete(vacunacion.id);
        sincronizados++;
      } catch (_) {
        // Se mantiene en Hive para reintentar más adelante.
      }
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