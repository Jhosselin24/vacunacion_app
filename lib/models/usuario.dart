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
  final DateTime? createdAt;

  const Usuario({
    required this.id,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
    required this.email,
    required this.rol,
    this.sectorId,
    this.primerLogin = true,
    this.createdAt,
  });

  // ── Nombre completo ────────────────────────────────────────
  String get nombreCompleto => '$nombres $apellidos';

  // ── Desde JSON (Supabase) ──────────────────────────────────
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id:          json['id'] as String,
      cedula:      json['cedula'] as String,
      nombres:     json['nombres'] as String,
      apellidos:   json['apellidos'] as String,
      telefono:    json['telefono'] as String,
      email:       json['email'] as String,
      rol:         json['rol'] as String,
      sectorId:    json['sector_id'] as String?,
      primerLogin: json['primer_login'] as bool? ?? true,
      createdAt:   json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  // ── A JSON (para Supabase insert/update) ──────────────────
  Map<String, dynamic> toJson() {
    return {
      'id':           id,
      'cedula':       cedula,
      'nombres':      nombres,
      'apellidos':    apellidos,
      'telefono':     telefono,
      'email':        email,
      'rol':          rol,
      'sector_id':    sectorId,
      'primer_login': primerLogin,
    };
  }

  // ── Copia con campos modificados ──────────────────────────
  Usuario copyWith({
    String? id,
    String? cedula,
    String? nombres,
    String? apellidos,
    String? telefono,
    String? email,
    String? rol,
    String? sectorId,
    bool? primerLogin,
    DateTime? createdAt,
  }) {
    return Usuario(
      id:          id          ?? this.id,
      cedula:      cedula      ?? this.cedula,
      nombres:     nombres     ?? this.nombres,
      apellidos:   apellidos   ?? this.apellidos,
      telefono:    telefono    ?? this.telefono,
      email:       email       ?? this.email,
      rol:         rol         ?? this.rol,
      sectorId:    sectorId    ?? this.sectorId,
      primerLogin: primerLogin ?? this.primerLogin,
      createdAt:   createdAt   ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Usuario($nombreCompleto, $rol)';

  @override
  bool operator ==(Object other) =>
      other is Usuario && other.id == id;

  @override
  int get hashCode => id.hashCode;
}