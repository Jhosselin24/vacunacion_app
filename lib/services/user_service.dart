import '../core/supabase.dart';
import '../models/usuario.dart';

class UserService {

  // LISTAR USUARIOS
  Future<List<Usuario>> getUsuarios() async {
    final data = await supabase
        .from('usuarios')
        .select();

    return (data as List)
        .map((e) => Usuario.fromMap(e))
        .toList();
  }

  // CREAR USUARIO (AUTH + DB)
  Future<void> createUser({
    required String email,
    required String password,
    required String cedula,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String rol,
    String? sectorId,
  }) async {

    // 1. Crear usuario en AUTH
    final auth = await supabase.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: password,
        emailConfirm: true,
      ),
    );

    final userId = auth.user!.id;

    // 2. Guardar en tabla usuarios
    await supabase.from('usuarios').insert({
      'id': userId,
      'cedula': cedula,
      'nombres': nombres,
      'apellidos': apellidos,
      'telefono': telefono,
      'email': email,
      'rol': rol,
      'sector_id': sectorId,
      'primer_login': true,
    });
  }

  // ACTUALIZAR USUARIO
  Future<void> updateUser({
    required String id,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String rol,
    String? sectorId,
  }) async {
    await supabase.from('usuarios').update({
      'nombres': nombres,
      'apellidos': apellidos,
      'telefono': telefono,
      'rol': rol,
      'sector_id': sectorId,
    }).eq('id', id);
  }

  // ELIMINAR USUARIO
  Future<void> deleteUser(String id) async {
    await supabase.from('usuarios').delete().eq('id', id);
  }

  // OBTENER USUARIO LOGUEADO
  Future<Usuario?> getCurrentUser() async {
    final authUser = supabase.auth.currentUser;

    if (authUser == null) return null;

    final data = await supabase
        .from('usuarios')
        .select()
        .eq('id', authUser.id)
        .single();

    return Usuario.fromMap(data);
  }
}