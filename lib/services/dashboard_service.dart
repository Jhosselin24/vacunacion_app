import '../core/supabase.dart';

class DashboardService {

  Future<int> totalVacunaciones() async {
    final data = await supabase
        .from('vacunaciones')
        .select('id');

    return data.length;
  }

  Future<int> totalPerros() async {
    final data = await supabase
        .from('vacunaciones')
        .select('id')
        .eq('tipo_mascota', 'perro');

    return data.length;
  }

  Future<int> totalGatos() async {
    final data = await supabase
        .from('vacunaciones')
        .select('id')
        .eq('tipo_mascota', 'gato');

    return data.length;
  }

  Future<List<Map<String, dynamic>>> porSector() async {
    final data = await supabase.rpc('vacunas_por_sector');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> porVacunador() async {
    final data = await supabase.rpc('vacunas_por_vacunador');
    return List<Map<String, dynamic>>.from(data);
  }
}