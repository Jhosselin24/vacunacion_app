import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/sector.dart';
import '../../models/usuario.dart';
import '../../services/sector_service.dart';
import '../../services/user_service.dart';

/// Vista de solo lectura para el coordinador de brigada:
/// muestra el sector que tiene asignado y los vacunadores
/// que están asignados a ese mismo sector.
///
/// A diferencia de [SectorPage] (uso exclusivo del coordinador de
/// campaña, con crear/editar/eliminar sobre TODOS los sectores),
/// esta pantalla no permite ninguna acción de edición: el
/// coordinador de brigada no gestiona sectores, solo los consulta.
class MiSectorPage extends StatefulWidget {
  const MiSectorPage({super.key});

  @override
  State<MiSectorPage> createState() => _MiSectorPageState();
}

class _MiSectorPageState extends State<MiSectorPage> {
  final _sectorService = SectorService();
  final _userService    = UserService();

  Sector?        _sector;
  List<Usuario>  _vacunadores = [];
  bool   _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final auth = context.read<AuthProvider>();
    final sectorId = auth.sectorId;

    setState(() { _isLoading = true; _error = null; });

    if (sectorId == null) {
      setState(() {
        _error     = 'No tienes un sector asignado todavía';
        _isLoading = false;
      });
      return;
    }

    try {
      final sector = await _sectorService.getSectorById(sectorId);
      final vacunadores = await _userService.getVacunadoresPorSector(sectorId);

      setState(() {
        _sector       = sector;
        _vacunadores  = vacunadores;
        _isLoading    = false;
      });
    } catch (e) {
      setState(() {
        _error     = 'Error al cargar el sector';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Sector Asignado'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppConstants.routeBrigadaDashboard),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _cargarDatos,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectorCard(),
                        const SizedBox(height: 24),
                        _buildVacunadoresSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectorCard() {
    if (_sector == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('No se encontró información del sector',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.map_rounded,
                color: AppColors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sector asignado',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.white.withOpacity(0.8))),
                const SizedBox(height: 2),
                Text(_sector!.nombre,
                    style: AppTextStyles.heading2
                        .copyWith(color: AppColors.white)),
                if (_sector!.descripcion != null &&
                    _sector!.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(_sector!.descripcion!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.white.withOpacity(0.9))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVacunadoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Vacunadores asignados', style: AppTextStyles.heading3),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${_vacunadores.length}',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_vacunadores.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.person_off_outlined,
                    color: AppColors.primaryLight, size: 36),
                const SizedBox(height: 8),
                Text('Aún no tienes vacunadores asignados a este sector',
                    style: AppTextStyles.bodySecondary,
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => context.go(AppConstants.routeUsuarios),
                  icon: const Icon(Icons.person_add_alt_rounded, size: 18),
                  label: const Text('Asignar vacunadores'),
                ),
              ],
            ),
          )
        else
          ..._vacunadores.map(_buildVacunadorCard),
      ],
    );
  }

  Widget _buildVacunadorCard(Usuario v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primarySurface,
            child: const Icon(Icons.medical_services_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.nombreCompleto, style: AppTextStyles.label),
                Text(v.email,
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text('CI: ${v.cedula}', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: AppTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _cargarDatos, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}