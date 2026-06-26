import 'package:flutter/material.dart';
import '../../services/sector_service.dart';

class AddSectorPage extends StatefulWidget {
  const AddSectorPage({super.key});

  @override
  State<AddSectorPage> createState() => _AddSectorPageState();
}

class _AddSectorPageState extends State<AddSectorPage> {

  final controller = TextEditingController();
  final service = SectorService();

  bool loading = false;

  Future<void> save() async {
    if (controller.text.isEmpty) return;

    setState(() => loading = true);

    await service.createSector(controller.text);

    setState(() => loading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Sector"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Nombre del sector",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : save,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Guardar"),
              ),
            )
          ],
        ),
      ),
    );
  }
}