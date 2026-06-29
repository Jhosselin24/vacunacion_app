class Sector {
  final String id;
  final String nombre;
  final String? descripcion;
  final DateTime? createdAt;

  const Sector({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.createdAt,
  });

  // ── Desde JSON (Supabase) ──────────────────────────────────
  factory Sector.fromJson(Map<String, dynamic> json) {
    return Sector(
      id:          json['id'] as String,
      nombre:      json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      createdAt:   json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  // ── A JSON ─────────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id':          id,
      'nombre':      nombre,
      'descripcion': descripcion,
    };
  }

  // ── Para insert (sin id, Supabase lo genera) ───────────────
  Map<String, dynamic> toInsertJson() {
    return {
      'nombre':      nombre,
      'descripcion': descripcion,
    };
  }

  Sector copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    DateTime? createdAt,
  }) {
    return Sector(
      id:          id          ?? this.id,
      nombre:      nombre      ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      createdAt:   createdAt   ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Sector($nombre)';

  @override
  bool operator ==(Object other) =>
      other is Sector && other.id == id;

  @override
  int get hashCode => id.hashCode;
}