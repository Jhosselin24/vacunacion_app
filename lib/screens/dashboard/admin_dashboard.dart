import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../login/login_page.dart';
import '../sectores/sector_page.dart';
import '../dashboard/dashboard_general.dart';

class AdminDashboard extends StatelessWidget {
  AdminDashboard({super.key});

  final AuthService authService = AuthService();

  Future<void> cerrarSesion(BuildContext context) async {
    await authService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(),
      ),
      (route) => false,
    );
  }

  void mostrarMensaje(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Coordinador de Campaña"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () => cerrarSesion(context),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          const Icon(
            Icons.admin_panel_settings,
            size: 100,
            color: Colors.blue,
          ),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              "Panel Principal",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 30),

          Card(
            child: ListTile(
              leading: const Icon(Icons.location_city),
              title: const Text("Gestionar Sectores"),
              subtitle: const Text("Crear, editar y eliminar sectores"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SectorPage(),
    ),
  );
},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.supervisor_account),
              title: const Text("Coordinadores de Brigada"),
              subtitle: const Text("Crear y asignar coordinadores"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                mostrarMensaje(context, "Pantalla Coordinadores");
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text("Dashboard General"),
              subtitle: const Text("Ver estadísticas"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DashboardGeneral(),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.pets),
              title: const Text("Vacunaciones"),
              subtitle: const Text("Consultar registros"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                mostrarMensaje(context, "Listado de Vacunaciones");
              },
            ),
          ),

          const SizedBox(height: 40),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () => cerrarSesion(context),
            icon: const Icon(Icons.logout),
            label: const Text("Cerrar Sesión"),
          ),
        ],
      ),
    );
  }
}