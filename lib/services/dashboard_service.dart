import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

class DashboardService {
  final _supabase = Supabase.instance.client;

  Box get _hiveBox => Hive.box(AppConstants.hiveBoxVacunaciones);

  // ── Stats generales (coordinador campaña) ─────────────────
  // FIX Bug 5: ya no depende de RPCs; calcula todo con queries
  // normales igual que getStatsPorSector, más conteo offline.
  Future<Map<String, dynamic>> getStatsGenerales() async {
    try {
      // Un solo query con JOIN a sectores y usuarios
      final data = await _supabase
          .from('vacunaciones')
          .select(
            'tipo_mascota, sincronizado, vacunador_id, sector_id, '
            'usuarios(nombres, apellidos), '
            'sectores(nombre)',
          ) as List;

      final total  = data.length;
      final perros = data.where((v) => v['tipo_mascota'] == 'perro').length;
      final gatos  = data.where((v) => v['tipo_mascota'] == 'gato').length;

      // Pendientes en Supabase marcados como no sincronizados
      final pendientesRemoto =
          data.where((v) => v['sincronizado'] == false).length;
      // Pendientes en Hive local (aún no subidos)
      final pendientesLocal = _hiveBox.values.length;

      // Por sector
      final Map<String, int> porSectorMap = {};
      for (final item in data) {
        final nombre = item['sectores'] != null
            ? item['sectores']['nombre'] as String
            : 'Sin sector';
        porSectorMap[nombre] = (porSectorMap[nombre] ?? 0) + 1;
      }

      // Por vacunador
      final Map<String, int> porVacunadorMap = {};
      for (final item in data) {
        final nombre = item['usuarios'] != null
            ? '${item['usuarios']['nombres']} ${item['usuarios']['apellidos']}'
            : 'Sin nombre';
        porVacunadorMap[nombre] = (porVacunadorMap[nombre] ?? 0) + 1;
      }

      return {
        'total':         total,
        'perros':        perros,
        'gatos':         gatos,
        'offline':       pendientesRemoto + pendientesLocal,
        'por_sector':    porSectorMap.entries
            .map((e) => {'sector_nombre': e.key, 'total': e.value})
            .toList(),
        'por_vacunador': porVacunadorMap.entries
            .map((e) => {'vacunador_nombre': e.key, 'total': e.value})
            .toList(),
      };
    } catch (e) {
      // Fallback offline: leer Hive
      final localTotal = _hiveBox.values.length;
      final localData  = _hiveBox.values.map((v) => v as Map).toList();
      final perros = localData.where((v) => v['tipo_mascota'] == 'perro').length;
      final gatos  = localData.where((v) => v['tipo_mascota'] == 'gato').length;

      return {
        'total':         localTotal,
        'perros':        perros,
        'gatos':         gatos,
        'offline':       localTotal,
        'por_sector':    <Map<String, dynamic>>[],
        'por_vacunador': <Map<String, dynamic>>[],
      };
    }
  }

  // ── Stats por sector (coordinador brigada) ─────────────────
  Future<Map<String, dynamic>> getStatsPorSector(String sectorId) async {
    try {
      final data = await _supabase
          .from('vacunaciones')
          .select('tipo_mascota, vacunador_id, sincronizado, usuarios(nombres, apellidos)')
          .eq('sector_id', sectorId) as List;

      final total      = data.length;
      final perros     = data.where((v) => v['tipo_mascota'] == 'perro').length;
      final gatos      = data.where((v) => v['tipo_mascota'] == 'gato').length;
      final pendientes = data.where((v) => v['sincronizado'] == false).length;
      final pendientesLocal = _hiveBox.values
          .where((v) {
            final map = v as Map;
            return map['sector_id'] == sectorId;
          })
          .length;

      final Map<String, int> porVacunadorMap = {};
      for (final item in data) {
        final nombre = item['usuarios'] != null
            ? '${item['usuarios']['nombres']} ${item['usuarios']['apellidos']}'
            : 'Sin nombre';
        porVacunadorMap[nombre] = (porVacunadorMap[nombre] ?? 0) + 1;
      }

      return {
        'total':         total,
        'perros':        perros,
        'gatos':         gatos,
        'pendientes':    pendientes + pendientesLocal,
        'por_vacunador': porVacunadorMap.entries
            .map((e) => {'vacunador_nombre': e.key, 'total': e.value})
            .toList(),
      };
    } catch (e) {
      final localData = _hiveBox.values
          .map((v) => v as Map)
          .where((v) => v['sector_id'] == sectorId)
          .toList();

      final total  = localData.length;
      final perros = localData.where((v) => v['tipo_mascota'] == 'perro').length;
      final gatos  = localData.where((v) => v['tipo_mascota'] == 'gato').length;

      return {
        'total':         total,
        'perros':        perros,
        'gatos':         gatos,
        'pendientes':    total,
        'por_vacunador': <Map<String, dynamic>>[],
      };
    }
  }

  // ── Stats del vacunador ────────────────────────────────────
  Future<Map<String, dynamic>> getStatsVacunador(String vacunadorId) async {
    try {
      final data = await _supabase
          .from('vacunaciones')
          .select('tipo_mascota, fecha, sincronizado')
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

      final pendientesRemoto = data.where((v) => v['sincronizado'] == false).length;
      final pendientesLocal  = _hiveBox.values
          .where((v) {
            final map = v as Map;
            return map['vacunador_id'] == vacunadorId;
          })
          .length;

      return {
        'total':      total,
        'perros':     perros,
        'gatos':      gatos,
        'hoy':        hoyCount,
        'pendientes': pendientesRemoto + pendientesLocal,
      };
    } catch (e) {
      final localData = _hiveBox.values
          .map((v) => v as Map)
          .where((v) => v['vacunador_id'] == vacunadorId)
          .toList();

      return {
        'total':      localData.length,
        'perros':     localData.where((v) => v['tipo_mascota'] == 'perro').length,
        'gatos':      localData.where((v) => v['tipo_mascota'] == 'gato').length,
        'hoy':        0,
        'pendientes': localData.length,
      };
    }
  }
}