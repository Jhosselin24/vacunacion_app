import '../core/supabase.dart';

class VacunacionService {

  Future<void> createVacunacion(Map<String, dynamic> data) async {
    await supabase.from('vacunaciones').insert(data);
  }

  Future<List<Map<String, dynamic>>> getVacunaciones() async {
    final data = await supabase.from('vacunaciones').select();
    return List<Map<String, dynamic>>.from(data);
  }
}