import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/dashboard_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/vacunacion_service.dart';
import '../../models/vacunacion.dart';

class VacunadorDashboard extends StatefulWidget {
  const VacunadorDashboard({super.key});

  @override
  State<VacunadorDashboard> createState() => _VacunadorDashboardState();
}

class _VacunadorDashboardState extends State<VacunadorDashboard> {
  final _dashService         = DashboardService();
  final _vacunacionService   = VacunacionService();
  final _connectivityService = ConnectivityService();

  Map<String, dynamic> _stats       = {};
  List<Vacunacion>     _vacunaciones = [];
  bool   _isLoading = true;
  bool   _conectado = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _initConnectivity();
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  void _initConnectivity() {
    _connectivityService.inicializar(
      onCambio: (conectado) {
        setState(() => _conectado = conectado);
        if (conectado) _cargarDatos();
      },
      onSincronizado: (count) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $count registros enviados al servidor'),
            backgroundColor: AppColors.success,
          ),
        );
        _cargarDatos();
      },
    );
  }

  Future<void> _cargarDatos() async {
    final auth = context.read<AuthProvider>();
    final uid  = auth.userId;
    if (uid == null) return;

    setState(() { _isLoading = true; _error = null; });

    try {
      final stats = await _dashService.getStatsVacunador(uid);
      final vacs  = await _vacunacionService.getVacunaciones(vacunadorId: uid);

      setState(() {
        _stats        = stats;
        _vacunaciones = vacs;
        _isLoading    = false;
      });
    } catch (e) {
      setState(() {
        _error     = 'Error al cargar tus registros';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Vacunaciones'),
        actions: [
          // Sincronizar manualmente
          if (_vacunacionService.pendientesOffline > 0)
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined),
              tooltip: 'Sincronizar pendientes',
              onPressed: () async {
                final count = await _connectivityService.sincronizarManual();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(count > 0
                        ? '✅ $count registros sincronizados'
                        : 'Sin conexión para sincronizar'),
                    backgroundColor:
                        count > 0 ? AppColors.success : AppColors.warning,
                  ),
                );
                if (count > 0) _cargarDatos();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarDatos,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await auth.logout();
              if (mounted) context.go(AppConstants.routeLogin);
            },
          ),
        ],
      ),

      // FAB para registrar vacunación
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppConstants.routeRegistroVacunacion);
          _cargarDatos();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar'),
      ),

      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _cargarDatos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSaludo(auth.nombreCompleto),
              const SizedBox(height: 4),

              if (!_conectado) _buildBannerOffline(),
              if (_vacunacionService.pendientesOffline > 0)
                _buildBannerPendientes(),

              const SizedBox(height: 20),

              if (_isLoading)
                _buildLoading()
              else if (_error != null)
                _buildError()
              else ...[
                _buildStatsGrid(),
                const SizedBox(height: 24),
                _buildListaVacunaciones(),
                const SizedBox(height: 80),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaludo(String nombre) {
    final hoy = DateFormat('EEEE d \'de\' MMMM', 'es').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hola,', style: AppTextStyles.bodySecondary),
        Text(nombre,
            style: AppTextStyles.heading2.copyWith(color: AppColors.primary)),
        Text(hoy, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildBannerOffline() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin conexión — los registros se guardarán localmente',
              style: AppTextStyles.caption.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerPendientes() {
    final pendientes = _vacunacionService.pendientesOffline;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined,
              color: AppColors.info, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$pendientes registro(s) pendiente(s) de sincronización',
              style: AppTextStyles.caption.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: AppTextStyles.body, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _cargarDatos, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final total  = _stats['total']  ?? 0;
    final perros = _stats['perros'] ?? 0;
    final gatos  = _stats['gatos']  ?? 0;
    final hoy    = _stats['hoy']    ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard('Total mis registros', '$total',
            Icons.vaccines_rounded, AppColors.cardTotal),
        _buildStatCard('Hoy', '$hoy',
            Icons.today_rounded, AppColors.primary),
        _buildStatCard('Perros', '$perros',
            Icons.pets_rounded, AppColors.cardPerros),
        _buildStatCard('Gatos', '$gatos',
            Icons.catching_pokemon_rounded, AppColors.cardGatos),
      ],
    );
  }

  Widget _buildStatCard(
      String titulo, String valor, IconData icono, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icono, color: AppColors.white.withOpacity(0.9), size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valor, style: AppTextStyles.dashboardNumber),
              Text(titulo, style: AppTextStyles.dashboardLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListaVacunaciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mis registros', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        if (_vacunaciones.isEmpty)
          _buildVacio()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _vacunaciones.length,
            itemBuilder: (_, i) => _buildVacunacionCard(_vacunaciones[i]),
          ),
      ],
    );
  }

  Widget _buildVacunacionCard(Vacunacion v) {
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(v.fecha);

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
        title: Text(
          '${v.mascotaNombre} · ${v.tipoMascota}',
          style: AppTextStyles.label,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prop: ${v.propietarioNombre}',
                style: AppTextStyles.caption),
            Text(fecha, style: AppTextStyles.caption),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador offline
            if (!v.sincronizado)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.cloud_upload_outlined,
                    color: AppColors.warning, size: 18),
              ),
            // Botón editar
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.primary, size: 20),
              onPressed: () async {
                await context.push(
                  AppConstants.routeEditVacunacion,
                  extra: {'vacunacion': v},
                );
                _cargarDatos();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.vaccines_outlined,
              color: AppColors.primaryLight, size: 52),
          const SizedBox(height: 12),
          Text('Aún no tienes registros',
              style: AppTextStyles.heading3
                  .copyWith(color: AppColors.primaryDark)),
          const SizedBox(height: 6),
          Text('Toca el botón + para registrar\ntu primera vacunación',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}