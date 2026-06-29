import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sector.dart';

class SectorService {
  final _supabase = Supabase.instance.client;

  // ── Obtener todos los sectores ─────────────────────────────
  Future<List<Sector>> getSectores() async {
    try {
      final data = await _supabase
          .from('sectores')
          .select()
          .order('nombre', ascending: true);

      return (data as List).map((e) => Sector.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error al cargar sectores: $e');
    }
  }

  // ── Obtener sector por ID ──────────────────────────────────
  Future<Sector?> getSectorById(String id) async {
    try {
      final data = await _supabase
          .from('sectores')
          .select()
          .eq('id', id)
          .single();

      return Sector.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ── Crear sector ───────────────────────────────────────────
  Future<String?> crearSector({
    required String nombre,
    String? descripcion,
  }) async {
    try {
      await _supabase.from('sectores').insert({
        'nombre':      nombre.trim(),
        'descripcion': descripcion?.trim(),
      });

      return null; // null = éxito
    } on PostgrestException catch (e) {
      return 'Error al crear sector: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // ── Actualizar sector ──────────────────────────────────────
  Future<String?> actualizarSector({
    required String id,
    required String nombre,
    String? descripcion,
  }) async {
    try {
      await _supabase.from('sectores').update({
        'nombre':      nombre.trim(),
        'descripcion': descripcion?.trim(),
      }).eq('id', id);

      return null;
    } on PostgrestException catch (e) {
      return 'Error al actualizar sector: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // ── Eliminar sector ────────────────────────────────────────
  Future<String?> eliminarSector(String id) async {
    try {
      await _supabase.from('sectores').delete().eq('id', id);
      return null;
    } on PostgrestException catch (e) {
      return 'No se puede eliminar: tiene usuarios o vacunaciones asociadas';
    } catch (e) {
      return 'Error al eliminar: $e';
    }
  }

  // ── Sectores con conteo de vacunaciones (para dashboard) ───
  Future<List<Map<String, dynamic>>> getSectoresConConteo() async {
    try {
      final data = await _supabase.rpc('vacunas_por_sector');
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      throw Exception('Error al cargar estadísticas por sector: $e');
    }
  }
}