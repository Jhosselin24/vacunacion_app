import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/dashboard_service.dart';
import '../../services/connectivity_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _dashService       = DashboardService();
  final _connectivityService = ConnectivityService();

  Map<String, dynamic> _stats = {};
  bool _isLoading  = true;
  bool _conectado  = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarStats();
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
        if (conectado) _cargarStats();
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

  Future<void> _cargarStats() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final stats = await _dashService.getStatsGenerales();
      setState(() { _stats = stats; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Error al cargar estadísticas'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard General'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarStats,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await auth.logout();
              if (mounted) context.go(AppConstants.routeLogin);
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _cargarStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Saludo ─────────────────────────────────
              _buildSaludo(auth.nombreCompleto),
              const SizedBox(height: 4),

              // ── Banner offline ──────────────────────────
              if (!_conectado) _buildBannerOffline(),

              const SizedBox(height: 20),

              // ── Cards de estadísticas ───────────────────
              if (_isLoading)
                _buildLoadingCards()
              else if (_error != null)
                _buildError()
              else ...[
                _buildStatsGrid(),
                const SizedBox(height: 24),
                _buildSeccionPorSector(),
                const SizedBox(height: 24),
                _buildSeccionPorVacunador(),
              ],
            ],
          ),
        ),
      ),

      // ── Menú de navegación ──────────────────────────────
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────

  Widget _buildSaludo(String nombre) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bienvenido,', style: AppTextStyles.bodySecondary),
        Text(
          nombre,
          style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
        ),
        Text(
          AppRoles.nombreLegible(AppRoles.coordinadorCampania),
          style: AppTextStyles.caption,
        ),
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
          Text(
            'Sin conexión — mostrando datos locales',
            style: AppTextStyles.caption.copyWith(color: AppColors.warning),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: List.generate(4, (_) => _buildSkeletonCard()),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: AppTextStyles.body),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _cargarStats,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final total   = _stats['total']   ?? 0;
    final perros  = _stats['perros']  ?? 0;
    final gatos   = _stats['gatos']   ?? 0;
    final offline = _stats['offline'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          titulo: 'Total vacunaciones',
          valor: '$total',
          icono: Icons.vaccines_rounded,
          color: AppColors.cardTotal,
        ),
        _buildStatCard(
          titulo: 'Perros',
          valor: '$perros',
          icono: Icons.pets_rounded,
          color: AppColors.cardPerros,
        ),
        _buildStatCard(
          titulo: 'Gatos',
          valor: '$gatos',
          icono: Icons.catching_pokemon_rounded,
          color: AppColors.cardGatos,
        ),
        _buildStatCard(
          titulo: 'Pendientes sync',
          valor: '$offline',
          icono: Icons.cloud_upload_outlined,
          color: AppColors.cardPendientes,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
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
            offset: const Offset(0, 4),
          ),
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

  Widget _buildSeccionPorSector() {
    final porSector = _stats['por_sector'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vacunaciones por sector', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        if (porSector.isEmpty)
          _buildVacio('No hay datos por sector')
        else
          ...porSector.map((item) => _buildBarraItem(
                label: item['sector_nombre'] ?? 'Sin nombre',
                valor: item['total'] as int? ?? 0,
                total: _stats['total'] as int? ?? 1,
                color: AppColors.primary,
              )),
      ],
    );
  }

  Widget _buildSeccionPorVacunador() {
    final porVacunador = _stats['por_vacunador'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vacunaciones por vacunador', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        if (porVacunador.isEmpty)
          _buildVacio('No hay datos por vacunador')
        else
          ...porVacunador.map((item) => _buildBarraItem(
                label: item['vacunador_nombre'] ?? 'Sin nombre',
                valor: item['total'] as int? ?? 0,
                total: _stats['total'] as int? ?? 1,
                color: AppColors.cardPerros,
              )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBarraItem({
    required String label,
    required int valor,
    required int total,
    required Color color,
  }) {
    final pct = total > 0 ? valor / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label, style: AppTextStyles.label,
                    overflow: TextOverflow.ellipsis),
              ),
              Text('$valor', style: AppTextStyles.label.copyWith(
                color: color, fontWeight: FontWeight.bold,
              )),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
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
      child: Text(msg, style: AppTextStyles.bodySecondary,
          textAlign: TextAlign.center),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 1: context.go(AppConstants.routeSectores);
          case 2: context.go(AppConstants.routeUsuarios);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          label: 'Sectores',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline_rounded),
          label: 'Usuarios',
        ),
      ],
    );
  }
}