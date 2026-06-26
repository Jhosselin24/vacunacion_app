import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../services/user_service.dart';
import 'user_form_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {

  final service = UserService();
  List<Usuario> usuarios = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    usuarios = await service.getUsuarios();
    setState(() {});
  }

  Future<void> delete(String id) async {
    await service.deleteUser(id);
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Usuarios")),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UserFormPage(),
            ),
          );
          load();
        },
        child: const Icon(Icons.add),
      ),

      body: ListView.builder(
        itemCount: usuarios.length,
        itemBuilder: (context, index) {

          final u = usuarios[index];

          return Card(
            child: ListTile(
              title: Text("${u.nombres} ${u.apellidos}"),
              subtitle: Text("${u.rol} - ${u.email}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => delete(u.id),
              ),
            ),
          );
        },
      ),
    );
  }
}