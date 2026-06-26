import 'package:flutter/material.dart';
import '../../services/user_service.dart';

class UserFormPage extends StatefulWidget {
  const UserFormPage({super.key});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {

  final service = UserService();

  final cedula = TextEditingController();
  final nombres = TextEditingController();
  final apellidos = TextEditingController();
  final telefono = TextEditingController();
  final email = TextEditingController();

  String rol = "coordinador_brigada";
  String? sectorId;

  bool loading = false;

  Future<void> save() async {

    setState(() => loading = true);

    await service.createUser(
      email: email.text,
      password: "Ecuador2026",
      cedula: cedula.text,
      nombres: nombres.text,
      apellidos: apellidos.text,
      telefono: telefono.text,
      rol: rol,
      sectorId: sectorId,
    );

    setState(() => loading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Usuario")),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          TextField(controller: cedula, decoration: const InputDecoration(labelText: "Cédula")),
          TextField(controller: nombres, decoration: const InputDecoration(labelText: "Nombres")),
          TextField(controller: apellidos, decoration: const InputDecoration(labelText: "Apellidos")),
          TextField(controller: telefono, decoration: const InputDecoration(labelText: "Teléfono")),
          TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),

          const SizedBox(height: 20),

          DropdownButtonFormField(
            value: rol,
            items: const [
              DropdownMenuItem(value: "coordinador_brigada", child: Text("Brigada")),
              DropdownMenuItem(value: "vacunador", child: Text("Vacunador")),
            ],
            onChanged: (v) => rol = v!,
            decoration: const InputDecoration(labelText: "Rol"),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: loading ? null : save,
            child: loading
                ? const CircularProgressIndicator()
                : const Text("Crear Usuario"),
          ),
        ],
      ),
    );
  }
}