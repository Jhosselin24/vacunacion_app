import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/vacunacion.dart';
import '../../providers/auth_provider.dart';
import '../../services/vacunacion_service.dart';

/// Lista completa de vacunaciones.
/// - Vacunador: solo sus registros.
/// - Coordinador de brigada: todos los registros de su sector,
///   puede editar cualquiera.
class VacunacionListPage extends StatefulWidget {
  const VacunacionListPage({super.key});

  @override
  State<VacunacionListPage> createState() => _VacunacionListPageState();
}

class _VacunacionListPageState extends State<VacunacionListPage> {
  final _vacunacionService = VacunacionService();
  final _searchCtrl        = TextEditingController();

  List<Vacunacion> _todas     = [];
  List<Vacunacion> _filtradas = [];
  bool   _isLoading = true;
  String? _error;

  // Filtros activos
  String _filtroTipo     = 'todos';   // 'todos' | 'perro' | 'gato'
  String _filtroSync     = 'todos';   // 'todos' | 'pendiente' | 'sincronizado'
  String? _filtroVacunadorNombre;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final auth = context.read<AuthProvider>();
    setState(() { _isLoading = true; _error = null; });

    try {
      List<Vacunacion> lista;

      if (auth.rol == AppRoles.coordinadorBrigada) {
        // Brigada: todos los registros del sector
        lista = await _vacunacionService.getVacunaciones(
          sectorId: auth.sectorId,
        );
      } else {
        // Vacunador: solo los suyos
        lista = await _vacunacionService.getVacunaciones(
          vacunadorId: auth.userId,
        );
      }

      setState(() {
        _todas     = lista;
        _isLoading = false;
      });
      _aplicarFiltros();
    } catch (e) {
      setState(() {
        _error     = 'Error al cargar registros';
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    final texto = _searchCtrl.text.toLowerCase();

    setState(() {
      _filtradas = _todas.where((v) {
        // Texto libre
        final coincideTexto = texto.isEmpty ||
            v.mascotaNombre.toLowerCase().contains(texto) ||
            v.propietarioNombre.toLowerCase().contains(texto) ||
            v.propietarioCedula.contains(texto);

        // Tipo mascota
        final coincideTipo = _filtroTipo == 'todos' ||
            v.tipoMascota == _filtroTipo;

        // Sync
        final coincideSync = _filtroSync == 'todos' ||
            (_filtroSync == 'pendiente'    && !v.sincronizado) ||
            (_filtroSync == 'sincronizado' &&  v.sincronizado);

        // Vacunador (solo para brigada)
        final coincideVacunador = _filtroVacunadorNombre == null ||
            (v.vacunadorNombre ?? '').contains(_filtroVacunadorNombre!);

        return coincideTexto && coincideTipo && coincideSync && coincideVacunador;
      }).toList();
    });
  }

  // ── Nombres únicos de vacunadores para el filtro ───────────
  List<String> get _vacunadores {
    final nombres = _todas
        .map((v) => v.vacunadorNombre ?? '')
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
    nombres.sort();
    return nombres;
  }

  @override
  Widget build(BuildContext context) {
    final auth       = context.watch<AuthProvider>();
    final esBrigada  = auth.rol == AppRoles.coordinadorBrigada;
    final pendientes = _todas.where((v) => !v.sincronizado).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(esBrigada ? 'Registros del Sector' : 'Mis Registros'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Regresar',
          onPressed: () {
            if (esBrigada) {
              context.go(AppConstants.routeBrigadaDashboard);
            } else {
              context.go(AppConstants.routeVacunadorDashboard);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      floatingActionButton: !esBrigada
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push(AppConstants.routeRegistroVacunacion);
                _cargarDatos();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Registrar'),
            )
          : null,
      body: Column(
        children: [
          // ── Banner pendientes ────────────────────────────
          if (pendientes > 0) _buildBannerPendientes(pendientes),

          // ── Barra de búsqueda ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _aplicarFiltros(),
              decoration: InputDecoration(
                hintText: 'Buscar mascota, propietario o cédula…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _aplicarFiltros();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ── Chips de filtro ──────────────────────────────
          _buildFiltros(esBrigada),

          // ── Contador resultados ──────────────────────────
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    '${_filtradas.length} registro(s)',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

          // ── Lista ────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : _filtradas.isEmpty
                        ? _buildVacio()
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _cargarDatos,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                              itemCount: _filtradas.length,
                              itemBuilder: (_, i) =>
                                  _buildCard(_filtradas[i], esBrigada),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerPendientes(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warning.withOpacity(0.12),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Text(
            '$count registro(s) pendiente(s) de sincronización',
            style: AppTextStyles.caption.copyWith(color: AppColors.warning),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros(bool esBrigada) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Tipo mascota
          _chip('Todos',  _filtroTipo == 'todos',
              () => setState(() { _filtroTipo = 'todos';  _aplicarFiltros(); })),
          const SizedBox(width: 8),
          _chip('🐶 Perros', _filtroTipo == 'perro',
              () => setState(() { _filtroTipo = 'perro';  _aplicarFiltros(); })),
          const SizedBox(width: 8),
          _chip('🐱 Gatos', _filtroTipo == 'gato',
              () => setState(() { _filtroTipo = 'gato';   _aplicarFiltros(); })),
          const SizedBox(width: 16),

          // Estado sync
          _chip('⏳ Pendientes', _filtroSync == 'pendiente',
              () => setState(() {
                _filtroSync = _filtroSync == 'pendiente' ? 'todos' : 'pendiente';
                _aplicarFiltros();
              })),

          // Filtro por vacunador (solo brigada)
          if (esBrigada && _vacunadores.isNotEmpty) ...[
            const SizedBox(width: 8),
            _chipDropdown(),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, bool activo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? AppColors.primary : const Color(0xFFE0E0E0),
          ),
          boxShadow: activo
              ? [BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 6)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: activo ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _chipDropdown() {
    return PopupMenuButton<String?>(
      onSelected: (val) => setState(() {
        _filtroVacunadorNombre = val;
        _aplicarFiltros();
      }),
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('Todos los vacunadores')),
        ..._vacunadores.map((n) => PopupMenuItem(value: n, child: Text(n))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _filtroVacunadorNombre != null
              ? AppColors.primary
              : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _filtroVacunadorNombre != null
                ? AppColors.primary
                : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _filtroVacunadorNombre ?? '👤 Vacunador',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _filtroVacunadorNombre != null
                    ? AppColors.white
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: _filtroVacunadorNombre != null
                  ? AppColors.white
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Vacunacion v, bool puedeEditar) {
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(v.fecha);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: !v.sincronizado
            ? Border.all(color: AppColors.warning.withOpacity(0.5))
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: v.tipoMascota == 'perro'
                ? AppColors.cardPerros.withOpacity(0.12)
                : AppColors.cardGatos.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(v.iconoMascota,
                style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text('${v.mascotaNombre} · ${v.tipoMascota}',
            style: AppTextStyles.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prop: ${v.propietarioNombre}',
                style: AppTextStyles.caption),
            Text(fecha, style: AppTextStyles.caption),
            if (v.vacunadorNombre != null)
              Text('Vacunador: ${v.vacunadorNombre}',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary)),
            if (!v.sincronizado)
              Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined,
                      color: AppColors.warning, size: 13),
                  const SizedBox(width: 4),
                  Text('Pendiente de sync',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning)),
                ],
              ),
          ],
        ),
        trailing: puedeEditar
            ? IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.primary, size: 22),
                tooltip: 'Editar registro',
                onPressed: () async {
                  await context.push(
                    AppConstants.routeEditVacunacion,
                    extra: {'vacunacion': v},
                  );
                  _cargarDatos();
                },
              )
            : null,
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
          ElevatedButton(
              onPressed: _cargarDatos, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.vaccines_outlined,
              color: AppColors.primaryLight, size: 56),
          const SizedBox(height: 12),
          Text('No hay registros', style: AppTextStyles.heading3),
          const SizedBox(height: 6),
          Text('Ajusta los filtros o registra una vacunación',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}