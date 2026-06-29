import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/vacunacion.dart';
import '../../models/sector.dart';
import '../../services/vacunacion_service.dart';
import '../../services/storage_service.dart';
import '../../services/location_service.dart';
import '../../services/sector_service.dart';

class RegistroVacunacionPage extends StatefulWidget {
  final Map<String, dynamic>? vacunacionEditar;

  const RegistroVacunacionPage({super.key, this.vacunacionEditar});

  @override
  State<RegistroVacunacionPage> createState() => _RegistroVacunacionPageState();
}

class _RegistroVacunacionPageState extends State<RegistroVacunacionPage> {
  final _formKey        = GlobalKey<FormState>();
  final _propNombreCtrl = TextEditingController();
  final _propCedulaCtrl = TextEditingController();
  final _propTelCtrl    = TextEditingController();
  final _mascNombreCtrl = TextEditingController();
  final _edadCtrl       = TextEditingController();
  final _obsCtrl        = TextEditingController();

  final _vacunacionService = VacunacionService();
  final _storageService    = StorageService();
  final _locationService   = LocationService();
  final _sectorService     = SectorService();
  final _uuid              = const Uuid();
  final _picker            = ImagePicker();

  // Selecciones
  String? _tipoMascota;
  String? _sexo;
  String? _vacuna;
  String? _sectorId;

  // GPS
  double? _latitud;
  double? _longitud;
  bool    _cargandoGps = false;
  String? _gpsError;

  // Foto
  File?   _fotoFile;
  String? _fotoUrlExistente; // en edición
  bool    _subiendoFoto = false;

  // Sectores
  List<Sector> _sectores = [];

  // Estado
  bool    _isLoading = false;
  bool    _isEditing = false;
  String? _editId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarSectores();
    _inicializarForm();
    // Capturar GPS automáticamente al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) => _capturarGps());
  }

  @override
  void dispose() {
    _propNombreCtrl.dispose();
    _propCedulaCtrl.dispose();
    _propTelCtrl.dispose();
    _mascNombreCtrl.dispose();
    _edadCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  void _inicializarForm() {
    final extra = widget.vacunacionEditar;
    if (extra == null) return;

    final v = extra['vacunacion'] as Vacunacion?;
    if (v == null) return;

    _isEditing            = true;
    _editId               = v.id;
    _propNombreCtrl.text  = v.propietarioNombre;
    _propCedulaCtrl.text  = v.propietarioCedula;
    _propTelCtrl.text     = v.telefono;
    _mascNombreCtrl.text  = v.mascotaNombre;
    _edadCtrl.text        = v.edadAprox ?? '';
    _obsCtrl.text         = v.observaciones ?? '';
    _tipoMascota          = v.tipoMascota;
    _sexo                 = v.sexo;
    _vacuna               = v.vacuna;
    _sectorId             = v.sectorId;
    _latitud              = v.latitud;
    _longitud             = v.longitud;
    _fotoUrlExistente     = v.fotoUrl;
  }

  Future<void> _cargarSectores() async {
    try {
      final auth = context.read<AuthProvider>();
      List<Sector> sectores;

      if (auth.rol == AppRoles.vacunador && auth.sectorId != null) {
        // Vacunador solo tiene su sector
        final s = await _sectorService.getSectorById(auth.sectorId!);
        sectores = s != null ? [s] : [];
        if (sectores.isNotEmpty && !_isEditing) {
          setState(() => _sectorId = sectores.first.id);
        }
      } else {
        sectores = await _sectorService.getSectores();
      }

      setState(() => _sectores = sectores);
    } catch (_) {}
  }

  // ── GPS ────────────────────────────────────────────────────
  Future<void> _capturarGps() async {
    setState(() { _cargandoGps = true; _gpsError = null; });

    final result = await _locationService.obtenerUbicacion();

    if (!mounted) return;

    if (result.containsKey('error')) {
      setState(() {
        _gpsError    = result['error'] as String;
        _cargandoGps = false;
      });
      return;
    }

    setState(() {
      _latitud     = result['latitud'] as double;
      _longitud    = result['longitud'] as double;
      _cargandoGps = false;
    });
  }

  // ── Foto ───────────────────────────────────────────────────
  Future<void> _tomarFoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (picked == null) return;
      setState(() => _fotoFile = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al acceder a la cámara'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
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
                  Navigator.pop(context);
                  _tomarFoto(ImageSource.camera);
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
                  Navigator.pop(context);
                  _tomarFoto(ImageSource.gallery);
                },
              ),
              if (_fotoFile != null || _fotoUrlExistente != null)
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
                    Navigator.pop(context);
                    setState(() {
                      _fotoFile         = null;
                      _fotoUrlExistente = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Guardar ────────────────────────────────────────────────
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tipoMascota == null) {
      setState(() => _error = 'Selecciona el tipo de mascota');
      return;
    }
    if (_vacuna == null) {
      setState(() => _error = 'Selecciona la vacuna aplicada');
      return;
    }
    if (_latitud == null || _longitud == null) {
      setState(() => _error = 'Se requiere la ubicación GPS. Toca "Obtener GPS"');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    final auth = context.read<AuthProvider>();

    // 1. Subir foto si hay una nueva
    String? fotoUrl = _fotoUrlExistente;
    if (_fotoFile != null) {
      setState(() => _subiendoFoto = true);
      final result = await _storageService.subirFoto(
        foto:       _fotoFile!,
        vacunadorId: auth.userId ?? 'unknown',
      );
      setState(() => _subiendoFoto = false);

      if (result.containsKey('error')) {
        // Si no se pudo subir, guardamos la ruta local para sync posterior
        fotoUrl = null;
      } else {
        fotoUrl = result['url'] as String;
      }
    }

    // 2. Construir objeto vacunacion
    final vacunacion = Vacunacion(
      id:                _isEditing ? _editId! : _uuid.v4(),
      propietarioNombre: _propNombreCtrl.text.trim(),
      propietarioCedula: _propCedulaCtrl.text.trim(),
      telefono:          _propTelCtrl.text.trim(),
      tipoMascota:       _tipoMascota!,
      mascotaNombre:     _mascNombreCtrl.text.trim(),
      edadAprox:         _edadCtrl.text.trim().isEmpty ? null : _edadCtrl.text.trim(),
      sexo:              _sexo,
      vacuna:            _vacuna!,
      observaciones:     _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      fotoUrl:           fotoUrl,
      fotoLocal:         _fotoFile?.path,
      latitud:           _latitud,
      longitud:          _longitud,
      vacunadorId:       auth.userId,
      sectorId:          _sectorId,
      fecha:             DateTime.now(),
      sincronizado:      fotoUrl != null,
    );

    // 3. Guardar
    String? error;
    if (_isEditing) {
      error = await _vacunacionService.editarVacunacion(vacunacion);
    } else {
      error = await _vacunacionService.registrarVacunacion(vacunacion);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? '✅ Registro actualizado'
            : '✅ Vacunación registrada exitosamente'),
        backgroundColor: AppColors.success,
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar vacunación' : 'Registrar vacunación'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ══ SECCIÓN: Propietario ══════════════════
                  _buildSeccionHeader('👤 Datos del propietario',
                      AppColors.primary),
                  const SizedBox(height: 16),

                  _buildLabel('Nombre del propietario *'),
                  TextFormField(
                    controller: _propNombreCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Cédula del propietario *'),
                  TextFormField(
                    controller: _propCedulaCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: '10 dígitos',
                      prefixIcon: Icon(Icons.badge_outlined),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                      if (v.trim().length != 10) return 'Deben ser 10 dígitos';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Teléfono *'),
                  TextFormField(
                    controller: _propTelCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: '09XXXXXXXX',
                      prefixIcon: Icon(Icons.phone_outlined),
                      counterText: '',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Campo obligatorio' : null,
                  ),

                  const SizedBox(height: 28),

                  // ══ SECCIÓN: Mascota ══════════════════════
                  _buildSeccionHeader('🐾 Datos de la mascota',
                      AppColors.cardPerros),
                  const SizedBox(height: 16),

                  // Tipo mascota (chips)
                  _buildLabel('Tipo de mascota *'),
                  Row(
                    children: AppConstants.tiposMascota.map((tipo) {
                      final selected = _tipoMascota == tipo;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _tipoMascota = tipo),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(
                                right: tipo == 'perro' ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : const Color(0xFFE0E0E0),
                                width: selected ? 2 : 1,
                              ),
                              boxShadow: selected ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ] : [],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  tipo == 'perro' ? '🐶' : '🐱',
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tipo == 'perro' ? 'Perro' : 'Gato',
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  _buildLabel('Nombre de la mascota *'),
                  TextFormField(
                    controller: _mascNombreCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Nombre de la mascota',
                      prefixIcon: Icon(Icons.pets_rounded),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Edad aprox.'),
                            TextFormField(
                              controller: _edadCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'Ej: 2 años',
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Sexo'),
                            DropdownButtonFormField<String>(
                              value: _sexo,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.male_rounded),
                              ),
                              hint: const Text('Sexo'),
                              items: AppConstants.sexos.map((s) =>
                                  DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                          s[0].toUpperCase() + s.substring(1))
                                  )).toList(),
                              onChanged: (v) => setState(() => _sexo = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ══ SECCIÓN: Vacuna ═══════════════════════
                  _buildSeccionHeader('💉 Vacuna aplicada',
                      AppColors.cardGatos),
                  const SizedBox(height: 16),

                  _buildLabel('Vacuna *'),
                  DropdownButtonFormField<String>(
                    value: _vacuna,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.vaccines_rounded),
                      hintText: 'Selecciona la vacuna',
                    ),
                    items: AppConstants.vacunas.map((v) =>
                        DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) => setState(() => _vacuna = v),
                    validator: (v) =>
                        v == null ? 'Selecciona la vacuna' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Observaciones'),
                  TextFormField(
                    controller: _obsCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Observaciones adicionales...',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 48),
                        child: Icon(Icons.notes_rounded),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sector
                  if (_sectores.isNotEmpty) ...[
                    _buildLabel('Sector *'),
                    DropdownButtonFormField<String>(
                      value: _sectorId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.map_outlined),
                        hintText: 'Selecciona el sector',
                      ),
                      items: _sectores.map((s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.nombre))
                      ).toList(),
                      onChanged: (v) => setState(() => _sectorId = v),
                      validator: (v) =>
                          v == null ? 'Selecciona el sector' : null,
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ══ SECCIÓN: Foto ═════════════════════════
                  _buildSeccionHeader('📷 Fotografía', AppColors.cardTotal),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: _mostrarOpcionesFoto,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _fotoFile != null || _fotoUrlExistente != null
                              ? AppColors.primary
                              : const Color(0xFFE0E0E0),
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildFotoWidget(),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ══ SECCIÓN: GPS ══════════════════════════
                  _buildSeccionHeader('📍 Ubicación GPS', AppColors.success),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _latitud != null
                            ? AppColors.success.withOpacity(0.5)
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: _buildGpsWidget(),
                  ),

                  // Error global
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_error!,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.error)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Botón guardar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _guardar,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: AppColors.white),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isEditing
                          ? 'Actualizar registro'
                          : 'Guardar vacunación'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Overlay de subida de foto
          if (_subiendoFoto)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Subiendo foto...',
                        style: TextStyle(color: AppColors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Widgets internos ────────────────────────────────────────

  Widget _buildSeccionHeader(String titulo, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(titulo,
              style: AppTextStyles.heading3.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.label),
    );
  }

  Widget _buildFotoWidget() {
    if (_fotoFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_fotoFile!, fit: BoxFit.cover),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: _mostrarOpcionesFoto,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded,
                    color: AppColors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    if (_fotoUrlExistente != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _fotoUrlExistente!,
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
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: _mostrarOpcionesFoto,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded,
                    color: AppColors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_a_photo_outlined,
            color: AppColors.primaryLight, size: 48),
        const SizedBox(height: 10),
        Text('Toca para agregar foto',
            style: AppTextStyles.bodySecondary),
        const SizedBox(height: 4),
        Text('Cámara o galería',
            style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildGpsWidget() {
    if (_cargandoGps) {
      return const Row(
        children: [
          SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
          SizedBox(width: 12),
          Text('Obteniendo ubicación...'),
        ],
      );
    }

    if (_latitud != null && _longitud != null) {
      return Row(
        children: [
          const Icon(Icons.location_on_rounded,
              color: AppColors.success, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ubicación capturada',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.success)),
                Text(
                  'Lat: ${_latitud!.toStringAsFixed(6)}\n'
                  'Lng: ${_longitud!.toStringAsFixed(6)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _capturarGps,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Actualizar'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_gpsError != null) ...[
          Row(
            children: [
              const Icon(Icons.location_off_rounded,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_gpsError!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.error)),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _capturarGps,
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('Obtener GPS'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              side: const BorderSide(color: AppColors.success),
            ),
          ),
        ),
      ],
    );
  }
}