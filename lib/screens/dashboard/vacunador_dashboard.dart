import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../login/login_page.dart';

class VacunadorDashboard extends StatelessWidget {
  VacunadorDashboard({super.key});

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
        title: const Text("Vacunador"),
        backgroundColor: Colors.green,
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
            Icons.pets,
            size: 100,
            color: Colors.green,
          ),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              "Panel del Vacunador",
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
                mostrarMensaje(context, "Mis Sectores");
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.vaccines),
              title: const Text("Registrar Vacunación"),
              subtitle: const Text("Nueva vacunación"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                mostrarMensaje(context, "Registrar Vacunación");
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Mis Registros"),
              subtitle: const Text("Editar vacunaciones realizadas"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                mostrarMensaje(context, "Mis Registros");
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Capturar Fotografía"),
              subtitle: const Text("Tomar foto de la mascota"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                mostrarMensaje(context, "Abrir Cámara");
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text("Capturar GPS"),
              subtitle: const Text("Obtener ubicación"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                mostrarMensaje(context, "Capturar GPS");
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