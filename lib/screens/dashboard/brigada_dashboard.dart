import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/dashboard_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/vacunacion_service.dart';
import '../../models/vacunacion.dart';

class BrigadaDashboard extends StatefulWidget {
  const BrigadaDashboard({super.key});

  @override
  State<BrigadaDashboard> createState() => _BrigadaDashboardState();
}

class _BrigadaDashboardState extends State<BrigadaDashboard> {
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
            content: Text('✅ $count registros sincronizados'),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }

  Future<void> _cargarDatos() async {
    final auth     = context.read<AuthProvider>();
    final sectorId = auth.sectorId;

    if (sectorId == null) {
      setState(() {
        _error     = 'No tienes un sector asignado';
        _isLoading = false;
      });
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final stats = await _dashService.getStatsPorSector(sectorId);
      final vacs  = await _vacunacionService.getVacunaciones(sectorId: sectorId);

      setState(() {
        _stats        = stats;
        _vacunaciones = vacs;
        _isLoading    = false;
      });
    } catch (e) {
      setState(() {
        _error     = 'Error al cargar datos del sector';
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
        title: const Text('Mi Sector'),
        actions: [
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
              const SizedBox(height: 20),

              if (_isLoading)
                _buildLoading()
              else if (_error != null)
                _buildError()
              else ...[
                _buildStatsGrid(),
                const SizedBox(height: 24),
                _buildSeccionVacunadores(),
                const SizedBox(height: 24),
                _buildUltimosRegistros(),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildSaludo(String nombre) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bienvenido,', style: AppTextStyles.bodySecondary),
        Text(nombre,
            style: AppTextStyles.heading2.copyWith(color: AppColors.primary)),
        Text(AppRoles.nombreLegible(AppRoles.coordinadorBrigada),
            style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildBannerOffline() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
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
          Text('Sin conexión — datos locales',
              style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
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

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        _buildStatCard('Total', '$total', Icons.vaccines_rounded, AppColors.cardTotal),
        _buildStatCard('Perros', '$perros', Icons.pets_rounded, AppColors.cardPerros),
        _buildStatCard('Gatos', '$gatos', Icons.catching_pokemon_rounded, AppColors.cardGatos),
      ],
    );
  }

  Widget _buildStatCard(String titulo, String valor, IconData icono, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: AppColors.white, size: 26),
          const SizedBox(height: 6),
          Text(valor, style: AppTextStyles.dashboardNumber.copyWith(fontSize: 26)),
          Text(titulo, style: AppTextStyles.dashboardLabel.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSeccionVacunadores() {
    final porVacunador = _stats['por_vacunador'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mis vacunadores', style: AppTextStyles.heading3),
            TextButton.icon(
              onPressed: () => context.go(AppConstants.routeUsuarios),
              icon: const Icon(Icons.people_outline, size: 16),
              label: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (porVacunador.isEmpty)
          _buildVacio('No hay vacunadores con registros aún')
        else
          ...porVacunador.map((item) {
            final nombre = item['vacunador_nombre'] ?? 'Sin nombre';
            final total  = item['total'] as int? ?? 0;
            final totalGeneral = _stats['total'] as int? ?? 1;
            return _buildVacunadorItem(nombre, total, totalGeneral);
          }),
      ],
    );
  }

  Widget _buildVacunadorItem(String nombre, int total, int totalGeneral) {
    final pct = totalGeneral > 0 ? total / totalGeneral : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySurface,
                child: const Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(nombre, style: AppTextStyles.label,
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$total',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.bold,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.primarySurface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltimosRegistros() {
    final ultimos = _vacunaciones.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Últimas vacunaciones', style: AppTextStyles.heading3),
            TextButton(
              onPressed: () => context.go(AppConstants.routeVacunaciones),
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (ultimos.isEmpty)
          _buildVacio('No hay registros aún')
        else
          ...ultimos.map((v) => _buildVacunacionItem(v)),
      ],
    );
  }

  Widget _buildVacunacionItem(Vacunacion v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: v.tipoMascota == 'perro'
                  ? AppColors.cardPerros.withOpacity(0.15)
                  : AppColors.cardGatos.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(v.iconoMascota, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.mascotaNombre, style: AppTextStyles.label),
                Text('Prop: ${v.propietarioNombre}',
                    style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (!v.sincronizado)
            const Icon(Icons.cloud_upload_outlined,
                color: AppColors.warning, size: 18),
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
    );
  }

  Widget _buildVacio(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(msg,
          style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 1: context.go(AppConstants.routeUsuarios);
          case 2: context.go(AppConstants.routeVacunaciones);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline_rounded),
          label: 'Vacunadores',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_rounded),
          label: 'Registros',
        ),
      ],
    );
  }
}