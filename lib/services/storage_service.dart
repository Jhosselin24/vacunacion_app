import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

class StorageService {
  final _supabase = Supabase.instance.client;

  // ── Subir foto de vacunación ───────────────────────────────
  Future<Map<String, dynamic>> subirFoto({
    required File foto,
    required String vacunadorId,
  }) async {
    try {
      // Nombre único: vacunadorId_timestamp.jpg
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = foto.path.split('.').last.toLowerCase();
      final fileName  = '${vacunadorId}_$timestamp.$extension';
      final filePath  = 'vacunaciones/$fileName';

      // Subir a Supabase Storage
      await _supabase.storage
          .from(AppConstants.bucketFotos)
          .upload(
            filePath,
            foto,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Obtener URL pública
      final url = _supabase.storage
          .from(AppConstants.bucketFotos)
          .getPublicUrl(filePath);

      return {'url': url};
    } on StorageException catch (e) {
      return {'error': 'Error al subir foto: ${e.message}'};
    } catch (e) {
      return {'error': 'Error inesperado al subir foto'};
    }
  }

  // ── Eliminar foto ──────────────────────────────────────────
  Future<String?> eliminarFoto(String fotoUrl) async {
    try {
      // Extraer el path desde la URL pública
      final uri    = Uri.parse(fotoUrl);
      final path   = uri.pathSegments
          .skipWhile((s) => s != AppConstants.bucketFotos)
          .skip(1)
          .join('/');

      await _supabase.storage
          .from(AppConstants.bucketFotos)
          .remove([path]);

      return null;
    } catch (e) {
      return 'Error al eliminar foto: $e';
    }
  }

  // ── Obtener URL pública de una foto ───────────────────────
  String getUrlPublica(String filePath) {
    return _supabase.storage
        .from(AppConstants.bucketFotos)
        .getPublicUrl(filePath);
  }
}