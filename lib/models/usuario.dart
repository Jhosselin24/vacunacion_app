class Usuario {
  final String id;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String telefono;
  final String email;
  final String rol;
  final String? sectorId;
  final bool primerLogin;

  Usuario({
    required this.id,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
    required this.email,
    required this.rol,
    this.sectorId,
    required this.primerLogin,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      cedula: map['cedula'],
      nombres: map['nombres'],
      apellidos: map['apellidos'],
      telefono: map['telefono'],
      email: map['email'],
      rol: map['rol'],
      sectorId: map['sector_id'],
      primerLogin: map['primer_login'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cedula': cedula,
      'nombres': nombres,
      'apellidos': apellidos,
      'telefono': telefono,
      'email': email,
      'rol': rol,
      'sector_id': sectorId,
      'primer_login': primerLogin,
    };
  }
}