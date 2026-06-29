import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';

/// Selector de fotografía reutilizable, con el mismo comportamiento y
/// estilo que hoy vive duplicado dentro de registro_vacunacion_page.dart:
/// un recuadro de 200px de alto que, al tocarlo, abre un bottom sheet
/// con las opciones "Tomar foto", "Elegir de galería" y, si ya hay una
/// foto, "Quitar foto".
///
/// El widget es autocontenido: maneja la cámara/galería internamente
/// y solo notifica el resultado hacia afuera mediante [onFotoFile]
/// (cuando se toma/selecciona una foto nueva) y [onQuitarFoto] (cuando
/// el usuario decide quitarla). La pantalla que lo usa sigue siendo la
/// dueña del estado (igual que antes), este widget solo evita repetir
/// la UI del selector en cada formulario que necesite una foto.
///
/// Ejemplo:
/// ```dart
/// PhotoPickerWidget(
///   fotoFile: _fotoFile,
///   fotoUrlExistente: _fotoUrlExistente,
///   onFotoFile: (file) => setState(() => _fotoFile = file),
///   onQuitarFoto: () => setState(() {
///     _fotoFile = null;
///     _fotoUrlExistente = null;
///   }),
/// )
/// ```
class PhotoPickerWidget extends StatelessWidget {
  final File? fotoFile;
  final String? fotoUrlExistente;
  final void Function(File foto) onFotoFile;
  final VoidCallback onQuitarFoto;
  final double height;

  const PhotoPickerWidget({
    super.key,
    required this.onFotoFile,
    required this.onQuitarFoto,
    this.fotoFile,
    this.fotoUrlExistente,
    this.height = 200,
  });

  bool get _tieneFoto => fotoFile != null || fotoUrlExistente != null;

  Future<void> _tomarFoto(BuildContext context, ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (picked == null) return;
      onFotoFile(File(picked.path));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al acceder a la cámara'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _mostrarOpciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Seleccionar foto', style: AppTextStyles.heading3),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _tomarFoto(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Elegir de galería'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _tomarFoto(context, ImageSource.gallery);
                },
              ),
              if (_tieneFoto)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                  ),
                  title: const Text('Quitar foto'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onQuitarFoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _mostrarOpciones(context),
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _tieneFoto
                ? AppColors.primary
                : const Color(0xFFE0E0E0),
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildContenido(context),
      ),
    );
  }

  Widget _buildContenido(BuildContext context) {
    if (fotoFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(fotoFile!, fit: BoxFit.cover),
          _buildBotonEditar(context),
        ],
      );
    }

    if (fotoUrlExistente != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            fotoUrlExistente!,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined,
                  color: AppColors.primaryLight, size: 48),
            ),
          ),
          _buildBotonEditar(context),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_a_photo_outlined,
            color: AppColors.primaryLight, size: 48),
        const SizedBox(height: 10),
        Text('Toca para agregar foto', style: AppTextStyles.bodySecondary),
        const SizedBox(height: 4),
        Text('Cámara o galería', style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildBotonEditar(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: () => _mostrarOpciones(context),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.edit_rounded,
              color: AppColors.white, size: 16),
        ),
      ),
    );
  }
}
