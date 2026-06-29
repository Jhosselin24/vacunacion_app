import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/sector.dart';
import '../../services/user_service.dart';
import '../../services/sector_service.dart';

class UserFormPage extends StatefulWidget {
  final Map<String, dynamic>? usuarioEditar;

  const UserFormPage({super.key, this.usuarioEditar});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey      = GlobalKey<FormState>();
  final _cedulaCtrl   = TextEditingController();
  final _nombresCtrl  = TextEditingController();
  final _apellCtrl    = TextEditingController();
  final _telCtrl      = TextEditingController();
  final _emailCtrl    = TextEditingController();

  final _userService   = UserService();
  final _sectorService = SectorService();

  List<Sector> _sectores = [];
  String?  _rolSeleccionado;
  String?  _sectorSeleccionado;
  bool     _isLoading  = false;
  bool     _isEditing  = false;
  String?  _error;
  String?  _usuarioId;

  @override
  void initState() {
    super.initState();
    _cargarSectores();
    _inicializarForm();
  }

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombresCtrl.dispose();
    _apellCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _inicializarForm() {
    final extra = widget.usuarioEditar;
    if (extra == null) {
      // Nuevo usuario: tomar rol del extra si viene
      _rolSeleccionado = extra?['rol'] as String?;
      return;
    }

    // Editar usuario existente
    final usuario = extra['usuario'] as Map<String, dynamic>?;
    if (usuario != null) {
      _isEditing         = true;
      _usuarioId         = usuario['id'] as String?;
      _cedulaCtrl.text   = usuario['cedula'] ?? '';
      _nombresCtrl.text  = usuario['nombres'] ?? '';
      _apellCtrl.text    = usuario['apellidos'] ?? '';
      _telCtrl.text      = usuario['telefono'] ?? '';
      _emailCtrl.text    = usuario['email'] ?? '';
      _rolSeleccionado   = usuario['rol'] as String?;
      _sectorSeleccionado = usuario['sector_id'] as String?;
    }

    // Solo rol pre-seleccionado
    if (extra.containsKey('rol') && !_isEditing) {
      _rolSeleccionado = extra['rol'] as String?;
    }
  }

  Future<void> _cargarSectores() async {
    try {
      final data = await _sectorService.getSectores();
      setState(() => _sectores = data);
    } catch (_) {}
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rolSeleccionado == null) {
      setState(() => _error = 'Selecciona un rol');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    String? error;

    if (_isEditing && _usuarioId != null) {
      error = await _userService.actualizarUsuario(
        id:        _usuarioId!,
        cedula:    _cedulaCtrl.text.trim(),
        nombres:   _nombresCtrl.text.trim(),
        apellidos: _apellCtrl.text.trim(),
        telefono:  _telCtrl.text.trim(),
        sectorId:  _sectorSeleccionado,
      );
    } else {
      error = await _userService.crearUsuario(
        cedula:    _cedulaCtrl.text.trim(),
        nombres:   _nombresCtrl.text.trim(),
        apellidos: _apellCtrl.text.trim(),
        telefono:  _telCtrl.text.trim(),
        email:     _emailCtrl.text.trim(),
        rol:       _rolSeleccionado!,
        sectorId:  _sectorSeleccionado,
      );
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
            ? '✅ Usuario actualizado'
            : '✅ Usuario creado. Contraseña inicial: ${AppConstants.passwordInicial}'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
      ),
    );
    context.pop();
  }

  List<String> _rolesDisponibles(String rolActual) {
    if (rolActual == AppRoles.coordinadorCampania) {
      return [AppRoles.coordinadorBrigada, AppRoles.vacunador];
    }
    return [AppRoles.vacunador];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final roles = _rolesDisponibles(auth.rol ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar usuario' : 'Nuevo usuario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar decorativo
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryLight, width: 2),
                  ),
                  child: const Icon(Icons.person_add_rounded,
                      color: AppColors.primary, size: 36),
                ),
              ),
              const SizedBox(height: 24),

              // Contraseña inicial (solo en crear)
              if (!_isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'La contraseña inicial será: ${AppConstants.passwordInicial}\n'
                          'El usuario deberá cambiarla en su primer ingreso.',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Rol ─────────────────────────────────────
              _buildLabel('Rol *'),
              DropdownButtonFormField<String>(
                value: _rolSeleccionado,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText: 'Selecciona un rol',
                ),
                items: roles.map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(AppRoles.nombreLegible(r)),
                )).toList(),
                onChanged: _isEditing
                    ? null
                    : (v) => setState(() => _rolSeleccionado = v),
                validator: (v) =>
                    v == null ? 'Selecciona un rol' : null,
              ),

              const SizedBox(height: 20),

              // ── Cédula ───────────────────────────────────
              _buildLabel('Cédula *'),
              TextFormField(
                controller: _cedulaCtrl,
                keyboardType: TextInputType.number,
                maxLength: 10,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText: '10 dígitos',
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa la cédula';
                  if (v.trim().length != 10) return 'La cédula debe tener 10 dígitos';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Nombres ───────────────────────────────────
              _buildLabel('Nombres *'),
              TextFormField(
                controller: _nombresCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Nombres completos',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingresa los nombres' : null,
              ),

              const SizedBox(height: 20),

              // ── Apellidos ─────────────────────────────────
              _buildLabel('Apellidos *'),
              TextFormField(
                controller: _apellCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Apellidos completos',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingresa los apellidos' : null,
              ),

              const SizedBox(height: 20),

              // ── Teléfono ──────────────────────────────────
              _buildLabel('Teléfono *'),
              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '09XXXXXXXX',
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el teléfono';
                  if (v.trim().length < 9) return 'Teléfono inválido';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Email (solo al crear) ─────────────────────
              if (!_isEditing) ...[
                _buildLabel('Correo electrónico *'),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'correo@ejemplo.com',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa el correo';
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // ── Sector ────────────────────────────────────
              _buildLabel('Sector (opcional)'),
              DropdownButtonFormField<String>(
                value: _sectorSeleccionado,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.map_outlined),
                  hintText: 'Asignar sector',
                ),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Sin sector')),
                  ..._sectores.map((s) =>
                      DropdownMenuItem(value: s.id, child: Text(s.nombre))),
                ],
                onChanged: (v) => setState(() => _sectorSeleccionado = v),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardar,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.white),
                        )
                      : Text(_isEditing ? 'Actualizar usuario' : 'Crear usuario'),
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

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.label),
    );
  }
}