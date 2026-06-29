import 'dart:async'; // ✅ Fix: import necesario para TimeoutException
import 'package:geolocator/geolocator.dart';

class LocationService {
  // ── Obtener ubicación actual ───────────────────────────────
  Future<Map<String, dynamic>> obtenerUbicacion() async {
    try {
      // 1. Verificar si el servicio GPS está activo
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {'error': 'El GPS está desactivado. Actívalo para continuar.'};
      }

      // 2. Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {'error': 'Permiso de ubicación denegado'};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {
          'error': 'Permiso de ubicación denegado permanentemente. '
              'Habilítalo en la configuración del dispositivo.'
        };
      }

      // 3. Obtener posición
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return {
        'latitud':  position.latitude,
        'longitud': position.longitude,
        'precision': position.accuracy,
      };
    } on LocationServiceDisabledException {
      return {'error': 'GPS desactivado'};
    } on PermissionDeniedException {
      return {'error': 'Permiso de ubicación denegado'};
    } on TimeoutException {
      return {'error': 'Tiempo de espera agotado. Inténtalo de nuevo.'};
    } catch (e) {
      return {'error': 'Error al obtener ubicación: $e'};
    }
  }

  // ── Verificar si tiene permiso ─────────────────────────────
  Future<bool> tienePermiso() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // ── Abrir configuración del dispositivo ───────────────────
  Future<void> abrirConfiguracion() async {
    await Geolocator.openLocationSettings();
  }
}