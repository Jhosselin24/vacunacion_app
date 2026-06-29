import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Overlay de carga reutilizable, igual al usado manualmente en
/// registro_vacunacion_page.dart mientras se sube la foto: un fondo
/// semi-transparente con un spinner y un mensaje centrados, encima
/// del contenido de la pantalla.
///
/// Se usa envolviendo el contenido de la pantalla en un [Stack]:
/// ```dart
/// Stack(
///   children: [
///     contenidoDeLaPantalla,
///     if (isLoading) const LoadingOverlay(message: 'Subiendo foto...'),
///   ],
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({super.key, this.message = 'Cargando...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppColors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
