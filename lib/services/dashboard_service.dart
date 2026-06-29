import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final _supabase = Supabase.instance.client;

  // ── Stats generales (coordinador campaña) ─────────────────
  Future<Map<String, dynamic>> getStatsGenerales() async {
    try {
      // Total + tipo mascota en una sola query
      final data = await _supabase
          .from('vacunaciones')
          .select('tipo_mascota') as List;

      final total  = data.length;
      final perros = data.where((v) => v['tipo_mascota'] == 'perro').length;
      final gatos  = data.where((v) => v['tipo_mascota'] == 'gato').length;

      // Por sector
      final porSector = await _supabase.rpc('vacunas_por_sector');

      // Por vacunador
      final porVacunador = await _supabase.rpc('vacunas_por_vacunador');

      return {
        'total':         total,
        'perros':        perros,
        'gatos':         gatos,
        'por_sector':    List<Map<String, dynamic>>.from(porSector as List),
        'por_vacunador': List<Map<String, dynamic>>.from(porVacunador as List),
      };
    } catch (e) {
      return {
        'total': 0, 'perros': 0, 'gatos': 0,
        'por_sector': [], 'por_vacunador': [],
      };
    }
  }

  // ── Stats por sector (coordinador brigada) ─────────────────
  Future<Map<String, dynamic>> getStatsPorSector(String sectorId) async {
    try {
      final data = await _supabase
          .from('vacunaciones')
          .select('tipo_mascota, vacunador_id, usuarios(nombres, apellidos)')
          .eq('sector_id', sectorId) as List;

      final total  = data.length;
      final perros = data.where((v) => v['tipo_mascota'] == 'perro').length;
      final gatos  = data.where((v) => v['tipo_mascota'] == 'gato').length;

      final Map<String, int> porVacunador = {};
      for (final item in data) {
        final nombre = item['usuarios'] != null
            ? '${item['usuarios']['nombres']} ${item['usuarios']['apellidos']}'
            : 'Sin nombre';
        porVacunador[nombre] = (porVacunador[nombre] ?? 0) + 1;
      }

      return {
        'total':  total,
        'perros': perros,
        'gatos':  gatos,
        'por_vacunador': porVacunador.entries
            .map((e) => {'vacunador_nombre': e.key, 'total': e.value})
            .toList(),
      };
    } catch (e) {
      return {'total': 0, 'perros': 0, 'gatos': 0, 'por_vacunador': []};
    }
  }

  // ── Stats del vacunador ────────────────────────────────────
  Future<Map<String, dynamic>> getStatsVacunador(String vacunadorId) async {
    try {
      final data = await _supabase
          .from('vacunaciones')
          .select('tipo_mascota, fecha')
          .eq('vacunador_id', vacunadorId) as List;

      final total  = data.length;
      final perros = data.where((v) => v['tipo_mascota'] == 'perro').length;
      final gatos  = data.where((v) => v['tipo_mascota'] == 'gato').length;

      final hoy       = DateTime.now();
      final hoyInicio = DateTime(hoy.year, hoy.month, hoy.day);
      final hoyFin    = hoyInicio.add(const Duration(days: 1));

      final hoyCount = data.where((v) {
        final fecha = DateTime.tryParse(v['fecha'] as String? ?? '');
        if (fecha == null) return false;
        return fecha.isAfter(hoyInicio) && fecha.isBefore(hoyFin);
      }).length;

      return {
        'total':  total,
        'perros': perros,
        'gatos':  gatos,
        'hoy':    hoyCount,
      };
    } catch (e) {
      return {'total': 0, 'perros': 0, 'gatos': 0, 'hoy': 0};
    }
  }
}