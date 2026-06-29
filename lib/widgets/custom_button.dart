import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Botón reutilizable que sigue el mismo patrón usado manualmente en
/// login_page.dart, change_password.dart, add_sector_page.dart,
/// user_form_page.dart y registro_vacunacion_page.dart:
/// - Ancho completo, alto 52 (configurable).
/// - Mientras `isLoading` es true, muestra un spinner en vez del texto
///   y deshabilita el botón.
/// - Variante principal (ElevatedButton) o secundaria (OutlinedButton).
///
/// Ejemplo:
/// ```dart
/// CustomButton(
///   label: 'Ingresar',
///   isLoading: isLoading,
///   onPressed: _login,
/// )
/// ```
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final double height;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: isSecondary ? AppColors.primary : AppColors.white,
            ),
          )
        : icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: isSecondary
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              child: child,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              child: child,
            ),
    );
  }
}
