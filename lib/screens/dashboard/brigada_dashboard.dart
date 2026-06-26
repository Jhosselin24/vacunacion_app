import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../login/login_page.dart';

class BrigadaDashboard extends StatelessWidget {
  BrigadaDashboard({super.key});

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
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Coordinador de Brigada"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => cerrarSesion(context),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.groups,
            size: 100,
            color: Colors.orange,
          ),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              "Panel de Brigada",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 30),

          Card(
            child: ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Mis Sectores"),
              subtitle: const Text("Ver sectores asignados"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                mostrarMensaje(context, "Pantalla Mis Sectores");
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text("Crear Vacunadores"),
              subtitle: const Text("Registrar nuevos vacunadores"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                mostrarMensaje(context, "Pantalla Crear Vacunador");
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text("Asignar/Reasignar Vacunadores"),
              subtitle: const Text("Administrar sectores"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                mostrarMensaje(
                  context,
                  "Pantalla Asignar Vacunadores",
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.edit_document),
              title: const Text("Corregir Vacunaciones"),
              subtitle: const Text("Editar registros del sector"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                mostrarMensaje(
                  context,
                  "Pantalla Corregir Vacunaciones",
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text("Dashboard del Sector"),
              subtitle: const Text("Estadísticas del sector"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                mostrarMensaje(
                  context,
                  "Dashboard del Sector",
                );
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