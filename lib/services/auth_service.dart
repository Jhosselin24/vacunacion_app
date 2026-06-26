import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase.dart';
import '../models/usuario.dart';

class AuthService {
  /// Login
  Future<AuthResponse> login(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Logout
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  /// Usuario autenticado
  User? get currentUser => supabase.auth.currentUser;

  /// Recuperar contraseña
  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  /// Cambiar contraseña
  Future<void> changePassword(String password) async {
    await supabase.auth.updateUser(
      UserAttributes(
        password: password,
      ),
    );
  }

  /// Obtener datos del usuario desde la tabla usuarios
  Future<Usuario?> getUsuario() async {
    final user = currentUser;

    if (user == null) return null;

    final response = await supabase
        .from('usuarios')
        .select()
        .eq('id', user.id)
        .single();

    return Usuario.fromMap(response);
  }
}