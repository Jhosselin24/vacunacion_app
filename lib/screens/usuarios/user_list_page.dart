import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/usuario.dart';
import '../../models/sector.dart';
import '../../services/user_service.dart';
import '../../services/sector_service.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage>
    with SingleTickerProviderStateMixin {
  final _userService   = UserService();
  final _sectorService = SectorService();

  List<Usuario> _usuarios  = [];
  List<Usuario> _filtrados = [];
  List<Sector>  _sectores  = [];

  late TabController _tabController;
  bool   _isLoading = true;
  String? _error;
  String _rolFiltro = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchCtrl.addListener(_filtrar);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final auth = context.read<AuthProvider>();

    if (auth.rol == AppRoles.coordinadorCampania) {
      _rolFiltro = _tabController.index == 0
          ? AppRoles.coordinadorBrigada
          : AppRoles.vacunador;
    } else {
      _rolFiltro = AppRoles.vacunador;
    }
    _filtrar();
  }

  Future<void> _cargarDatos() async {
    final auth = context.read<AuthProvider>();
    setState(() { _isLoading = true; _error = null; });

    try {
      final sectores = await _sectorService.getSectores();
      List<Usuario> usuarios;

      if (auth.rol == AppRoles.coordinadorCampania) {
        usuarios   = await _userService.getUsuarios();
        _rolFiltro = AppRoles.coordinadorBrigada;
      } else {
        // ✅ Fix: el coordinador de brigada necesita ver, además de los
        // vacunadores ya asignados a su sector, los que aún no tienen
        // sector asignado — de lo contrario nunca puede "reclutarlos"
        // (el botón de asignar sector nunca aparecía porque esos
        // vacunadores ni siquiera entraban en la lista).
        final delSector  = await _userService.getVacunadoresPorSector(auth.sectorId!);
        final todosVac   = await _userService.getUsuariosPorRol(AppRoles.vacunador);
        final sinSector  = todosVac.where((u) => u.sectorId == null);

        final ids = <String>{};
        usuarios = [
          for (final u in [...delSector, ...sinSector])
            if (ids.add(u.id)) u,
        ];
        _rolFiltro = AppRoles.vacunador;
      }

      setState(() {
        _sectores  = sectores;
        _usuarios  = usuarios.where((u) => u.id != auth.userId).toList();
        _isLoading = false;
      });
      _filtrar();
    } catch (e) {
      setState(() { _error = 'Error al cargar usuarios'; _isLoading = false; });
    }
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtrados = _usuarios.where((u) {
        final matchRol = _rolFiltro.isEmpty || u.rol == _rolFiltro;
        final matchQ   = q.isEmpty ||
            u.nombreCompleto.toLowerCase().contains(q) ||
            u.cedula.contains(q) ||
            u.email.toLowerCase().contains(q);
        return matchRol && matchQ;
      }).toList();
    });
  }

  Future<void> _asignarSector(Usuario usuario) async {
    String? sectorSeleccionado = usuario.sectorId;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('Asignar sector a\n${usuario.nombreCompleto}'),
          content: DropdownButtonFormField<String>(
            value: sectorSeleccionado,
            decoration: const InputDecoration(labelText: 'Sector'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Sin sector')),
              ..._sectores.map((s) =>
                  DropdownMenuItem(value: s.id, child: Text(s.nombre))),
            ],
            onChanged: (v) => setDlg(() => sectorSeleccionado = v),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Asignar')),
          ],
        ),
      ),
    );

    if (confirmar != true) return;

    // ✅ Fix: se usa reasignarSector (acepta sectorId nulo) en lugar de
    // asignarSector, para poder quitar el sector correctamente cuando
    // el coordinador selecciona "Sin sector".
    final error = await _userService.reasignarSector(
      usuarioId: usuario.id,
      nuevoSectorId: sectorSeleccionado,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '✅ Sector asignado correctamente'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
      ),
    );
    if (error == null) _cargarDatos();
  }

  Future<void> _eliminarUsuario(Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
            '¿Eliminar a ${usuario.nombreCompleto}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final error = await _userService.eliminarUsuario(usuario.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '✅ Usuario eliminado'),
        backgroundColor: error != null ? AppColors.error : AppColors.success,
      ),
    );
    if (error == null) _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final isAdmin = auth.rol == AppRoles.coordinadorCampania;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Usuarios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => isAdmin
              ? context.go(AppConstants.routeAdminDashboard)
              : context.go(AppConstants.routeBrigadaDashboard),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarDatos,
          ),
        ],
        bottom: isAdmin
            ? TabBar(
                controller: _tabController,
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.white.withOpacity(0.6),
                indicatorColor: AppColors.white,
                tabs: const [
                  Tab(text: 'Coordinadores'),
                  Tab(text: 'Vacunadores'),
                ],
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppConstants.routeAddUsuario,
              extra: {'rol': _rolFiltro});
          _cargarDatos();
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nuevo usuario'),
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, cédula o correo...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () { _searchCtrl.clear(); _filtrar(); },
                      )
                    : null,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Text('${_filtrados.length} usuario(s)',
                  style: AppTextStyles.caption),
            ]),
          ),

          // Lista
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
                            onRefresh: _cargarDatos,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 90),
                              itemCount: _filtrados.length,
                              itemBuilder: (_, i) =>
                                  _buildUsuarioCard(_filtrados[i], auth),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsuarioCard(Usuario usuario, AuthProvider auth) {
    final sector = _sectores
        .where((s) => s.id == usuario.sectorId)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primarySurface,
              child: Icon(
                AppRoles.iconoPorRol(usuario.rol),
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usuario.nombreCompleto, style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(usuario.email,
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis),
                  Text('CI: ${usuario.cedula}',
                      style: AppTextStyles.caption),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildChip(AppRoles.nombreLegible(usuario.rol),
                          AppColors.primary),
                      const SizedBox(width: 6),
                      if (sector != null)
                        _buildChip(sector.nombre, AppColors.cardPerros),
                    ],
                  ),
                ],
              ),
            ),

            // Acciones
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.map_outlined,
                      color: AppColors.primary, size: 20),
                  onPressed: () => _asignarSector(usuario),
                  tooltip: 'Asignar sector',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.primary, size: 20),
                  onPressed: () async {
                    await context.push(AppConstants.routeAddUsuario,
                        extra: {'usuario': usuario.toJson()});
                    _cargarDatos();
                  },
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                  onPressed: () => _eliminarUsuario(usuario),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(
              color: color, fontWeight: FontWeight.w600)),
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
          ElevatedButton(onPressed: _cargarDatos, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, color: AppColors.primaryLight, size: 64),
          const SizedBox(height: 16),
          Text('No hay usuarios',
              style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          Text('Toca + para agregar un usuario',
              style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }
}