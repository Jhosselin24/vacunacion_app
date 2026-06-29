import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/sector.dart';
import '../../services/sector_service.dart';

class SectorPage extends StatefulWidget {
  const SectorPage({super.key});

  @override
  State<SectorPage> createState() => _SectorPageState();
}

class _SectorPageState extends State<SectorPage> {
  final _sectorService = SectorService();
  List<Sector> _sectores  = [];
  List<Sector> _filtrados = [];
  bool   _isLoading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarSectores();
    _searchCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarSectores() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _sectorService.getSectores();
      setState(() {
        _sectores  = data;
        _filtrados = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = 'Error al cargar sectores'; _isLoading = false; });
    }
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtrados = _sectores
          .where((s) => s.nombre.toLowerCase().contains(q))
          .toList();
    });
  }

  Future<void> _eliminarSector(Sector sector) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar sector'),
        content: Text('¿Eliminar "${sector.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final error = await _sectorService.eliminarSector(sector.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '✅ Sector eliminado'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
      ),
    );

    if (error == null) _cargarSectores();
  }

  Future<void> _editarSector(Sector sector) async {
    final nombreCtrl = TextEditingController(text: sector.nombre);
    final descCtrl   = TextEditingController(text: sector.descripcion ?? '');

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar sector'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final error = await _sectorService.actualizarSector(
      id:          sector.id,
      nombre:      nombreCtrl.text,
      descripcion: descCtrl.text,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '✅ Sector actualizado'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
      ),
    );
    if (error == null) _cargarSectores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sectores'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppConstants.routeAdminDashboard),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarSectores,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppConstants.routeAddSector);
          _cargarSectores();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo sector'),
      ),
      body: Column(
        children: [
          // ── Buscador ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar sector...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filtrar();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Contador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filtrados.length} sector(es)',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          // ── Lista ──────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : _filtrados.isEmpty
                        ? _buildVacio()
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _cargarSectores,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                              itemCount: _filtrados.length,
                              itemBuilder: (_, i) =>
                                  _buildSectorCard(_filtrados[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorCard(Sector sector) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.map_outlined, color: AppColors.primary, size: 24),
        ),
        title: Text(sector.nombre, style: AppTextStyles.label),
        subtitle: sector.descripcion != null && sector.descripcion!.isNotEmpty
            ? Text(sector.descripcion!, style: AppTextStyles.caption,
                maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.primary, size: 20),
              onPressed: () => _editarSector(sector),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              onPressed: () => _eliminarSector(sector),
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: AppTextStyles.body),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _cargarSectores, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, color: AppColors.primaryLight, size: 64),
          const SizedBox(height: 16),
          Text('No hay sectores',
              style: AppTextStyles.heading3.copyWith(color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          Text('Toca + para crear el primer sector',
              style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }
}