class Sector {
  final String id;
  final String nombre;

  Sector({
    required this.id,
    required this.nombre,
  });

  factory Sector.fromMap(Map<String, dynamic> map) {
    return Sector(
      id: map['id'],
      nombre: map['nombre'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
    };
  }
}