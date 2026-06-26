import '../core/supabase.dart';
import '../models/sector.dart';

class SectorService {

  Future<List<Sector>> getSectores() async {
    final data = await supabase
        .from('sectores')
        .select();

    return (data as List)
        .map((e) => Sector.fromMap(e))
        .toList();
  }

  Future<void> createSector(String nombre) async {
    await supabase.from('sectores').insert({
      'nombre': nombre,
    });
  }

  Future<void> updateSector(String id, String nombre) async {
    await supabase
        .from('sectores')
        .update({'nombre': nombre})
        .eq('id', id);
  }

  Future<void> deleteSector(String id) async {
    await supabase
        .from('sectores')
        .delete()
        .eq('id', id);
  }
}