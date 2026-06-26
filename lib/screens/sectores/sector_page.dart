import 'package:flutter/material.dart';
import '../../models/sector.dart';
import '../../services/sector_service.dart';
import 'add_sector_page.dart';

class SectorPage extends StatefulWidget {
  const SectorPage({super.key});

  @override
  State<SectorPage> createState() => _SectorPageState();
}

class _SectorPageState extends State<SectorPage> {

  final service = SectorService();

  List<Sector> sectores = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    sectores = await service.getSectores();

    setState(() => loading = false);
  }

  Future<void> delete(String id) async {
    await service.deleteSector(id);
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sectores"),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddSectorPage(),
            ),
          );
          loadData();
        },
        child: const Icon(Icons.add),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: sectores.length,
              itemBuilder: (context, index) {
                final s = sectores[index];

                return Card(
                  child: ListTile(
                    title: Text(s.nombre),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => delete(s.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}