import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';

class DashboardGeneral extends StatefulWidget {
  const DashboardGeneral({super.key});

  @override
  State<DashboardGeneral> createState() => _DashboardGeneralState();
}

class _DashboardGeneralState extends State<DashboardGeneral> {

  final service = DashboardService();

  int total = 0;
  int perros = 0;
  int gatos = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {

    setState(() => loading = true);

    total = await service.totalVacunaciones();
    perros = await service.totalPerros();
    gatos = await service.totalGatos();

    setState(() => loading = false);
  }

  Widget card(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [

            Icon(icon, size: 40, color: color),

            const SizedBox(width: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 16)),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard General"),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [

                  const Text(
                    "Resumen de Campaña",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  card("Total Vacunaciones", "$total",
                      Icons.pets, Colors.blue),

                  card("Perros Vacunados", "$perros",
                      Icons.dog, Colors.orange),

                  card("Gatos Vacunados", "$gatos",
                      Icons.pets, Colors.purple),

                  const SizedBox(height: 20),

                  const Text(
                    "Indicadores",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.map),
                      title: const Text("Vacunaciones por sector"),
                      subtitle: const Text("Ver distribución"),
                      onTap: () {},
                    ),
                  ),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text("Vacunaciones por vacunador"),
                      subtitle: const Text("Rendimiento"),
                      onTap: () {},
                    ),
                  ),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text("Pendientes offline"),
                      subtitle: const Text("Sincronización futura"),
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}