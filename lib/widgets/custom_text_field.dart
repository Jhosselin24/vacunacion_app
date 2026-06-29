import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Campo de texto reutilizable que sigue el mismo patrón usado
/// manualmente en login_page.dart, user_form_page.dart,
/// add_sector_page.dart y registro_vacunacion_page.dart:
/// label arriba del campo (AppTextStyles.label), prefixIcon, hint y
/// validator opcionales.
///
/// Ejemplo:
/// ```dart
/// CustomTextField(
///   label: 'Cédula del propietario *',
///   controller: _propCedulaCtrl,
///   hint: '10 dígitos',
///   icon: Icons.badge_outlined,
///   keyboardType: TextInputType.number,
///   maxLength: 10,
///   validator: (v) {
///     if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
///     if (v.trim().length != 10) return 'Deben ser 10 dígitos';
///     return null;
///   },
/// )
/// ```
class CustomTextField extends StatefulWidget {
  final String? label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int? maxLength;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLength,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText ? _obscure : false,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLength: widget.maxLength,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      textCapitalization: widget.textCapitalization,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        counterText: widget.maxLength != null ? '' : null,
        prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );

    if (widget.label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            widget.label!,
            style: AppTextStyles.label,
          ),
        ),
        field,
      ],
    );
  }
}
