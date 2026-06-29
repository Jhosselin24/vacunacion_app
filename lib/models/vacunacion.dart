// Modelo de Vacunación.
//
// ✅ Fix: se quitaron las anotaciones @HiveType / @HiveField y el
// `extends HiveObject` que tenía esta clase. Esas anotaciones
// requieren generar un adaptador (vacunacion.g.dart) con build_runner
// y registrarlo con Hive.registerAdapter() antes de poder guardar
// objetos Vacunacion directamente en una Hive box — ese adapter
// nunca se generó, y el código real de la app NUNCA guarda objetos
// Vacunacion en Hive: usa exclusivamente Maps planos a través de
// toHiveMap() / fromHiveMap() (ver VacunacionService). Mantener las
// anotaciones sin su adapter no rompía nada en tiempo de ejecución,
// pero era código muerto que sugería un mecanismo de persistencia
// que la app no usa.
//
// Si en el futuro se quiere guardar el objeto Vacunacion directamente
// en Hive (en vez de un Map), hay que:
//   1. Volver a anotar la clase con @HiveType(typeId: 0) y cada campo
//      con @HiveField(n).
//   2. Ejecutar: flutter pub run build_runner build
//      (esto genera lib/models/vacunacion.g.dart con VacunacionAdapter).
//   3. Registrar el adapter en main.dart, antes de abrir la box:
//      Hive.registerAdapter(VacunacionAdapter());

class Vacunacion {
  final String id;

  final String propietarioNombre;

  final String propietarioCedula;

  final String telefono;

  final String tipoMascota; // 'perro' | 'gato'

  final String mascotaNombre;

  final String? edadAprox;

  final String? sexo; // 'macho' | 'hembra'

  final String vacuna;

  final String? observaciones;

  final String? fotoUrl;     // URL en Supabase Storage (online)

  final String? fotoLocal;   // ruta local cuando está offline

  final double? latitud;

  final double? longitud;

  final String? vacunadorId;

  final String? sectorId;

  final DateTime fecha;

  final bool sincronizado; // false = pendiente de subir

  // Datos extra que vienen del JOIN con Supabase (no se guardan en Hive)
  final String? vacunadorNombre;
  final String? sectorNombre;

  Vacunacion({
    required this.id,
    required this.propietarioNombre,
    required this.propietarioCedula,
    required this.telefono,
    required this.tipoMascota,
    required this.mascotaNombre,
    this.edadAprox,
    this.sexo,
    required this.vacuna,
    this.observaciones,
    this.fotoUrl,
    this.fotoLocal,
    this.latitud,
    this.longitud,
    this.vacunadorId,
    this.sectorId,
    required this.fecha,
    this.sincronizado = true,
    this.vacunadorNombre,
    this.sectorNombre,
  });

  // ── Desde JSON (Supabase) ──────────────────────────────────
  factory Vacunacion.fromJson(Map<String, dynamic> json) {
    return Vacunacion(
      id:                 json['id'] as String,
      propietarioNombre:  json['propietario_nombre'] as String,
      propietarioCedula:  json['propietario_cedula'] as String,
      telefono:           json['telefono'] as String,
      tipoMascota:        json['tipo_mascota'] as String,
      mascotaNombre:      json['mascota_nombre'] as String,
      edadAprox:          json['edad_aprox'] as String?,
      sexo:               json['sexo'] as String?,
      vacuna:             json['vacuna'] as String,
      observaciones:      json['observaciones'] as String?,
      fotoUrl:            json['foto_url'] as String?,
      latitud:            (json['latitud'] as num?)?.toDouble(),
      longitud:           (json['longitud'] as num?)?.toDouble(),
      vacunadorId:        json['vacunador_id'] as String?,
      sectorId:           json['sector_id'] as String?,
      fecha:              json['fecha'] != null
          ? DateTime.parse(json['fecha'] as String)
          : DateTime.now(),
      sincronizado:       json['sincronizado'] as bool? ?? true,
      // Datos de joins (opcionales)
      vacunadorNombre:    json['usuarios'] != null
          ? '${json['usuarios']['nombres']} ${json['usuarios']['apellidos']}'
          : null,
      sectorNombre:       json['sectores']?['nombre'] as String?,
    );
  }

  // ── A JSON para INSERT en Supabase ─────────────────────────
  Map<String, dynamic> toInsertJson() {
    return {
      'propietario_nombre': propietarioNombre,
      'propietario_cedula': propietarioCedula,
      'telefono':           telefono,
      'tipo_mascota':       tipoMascota,
      'mascota_nombre':     mascotaNombre,
      'edad_aprox':         edadAprox,
      'sexo':               sexo,
      'vacuna':             vacuna,
      'observaciones':      observaciones,
      'foto_url':           fotoUrl,
      'latitud':            latitud,
      'longitud':           longitud,
      'vacunador_id':       vacunadorId,
      'sector_id':          sectorId,
      'fecha':              fecha.toIso8601String(),
      'sincronizado':       sincronizado,
    };
  }

  // ── A JSON para UPDATE en Supabase ─────────────────────────
  Map<String, dynamic> toUpdateJson() {
    return {
      'propietario_nombre': propietarioNombre,
      'propietario_cedula': propietarioCedula,
      'telefono':           telefono,
      'tipo_mascota':       tipoMascota,
      'mascota_nombre':     mascotaNombre,
      'edad_aprox':         edadAprox,
      'sexo':               sexo,
      'vacuna':             vacuna,
      'observaciones':      observaciones,
      'foto_url':           fotoUrl,
      'latitud':            latitud,
      'longitud':           longitud,
      'sincronizado':       true,
    };
  }

  // ── Para guardar en Hive (offline) ─────────────────────────
  Map<String, dynamic> toHiveMap() {
    return {
      'id':                 id,
      'propietario_nombre': propietarioNombre,
      'propietario_cedula': propietarioCedula,
      'telefono':           telefono,
      'tipo_mascota':       tipoMascota,
      'mascota_nombre':     mascotaNombre,
      'edad_aprox':         edadAprox,
      'sexo':               sexo,
      'vacuna':             vacuna,
      'observaciones':      observaciones,
      'foto_url':           fotoUrl,
      'foto_local':         fotoLocal,
      'latitud':            latitud,
      'longitud':           longitud,
      'vacunador_id':       vacunadorId,
      'sector_id':          sectorId,
      'fecha':              fecha.toIso8601String(),
      'sincronizado':       sincronizado,
    };
  }

  // ── Desde Hive (offline) ───────────────────────────────────
  factory Vacunacion.fromHiveMap(Map<dynamic, dynamic> map) {
    return Vacunacion(
      id:                 map['id'] as String,
      propietarioNombre:  map['propietario_nombre'] as String,
      propietarioCedula:  map['propietario_cedula'] as String,
      telefono:           map['telefono'] as String,
      tipoMascota:        map['tipo_mascota'] as String,
      mascotaNombre:      map['mascota_nombre'] as String,
      edadAprox:          map['edad_aprox'] as String?,
      sexo:               map['sexo'] as String?,
      vacuna:             map['vacuna'] as String,
      observaciones:      map['observaciones'] as String?,
      fotoUrl:            map['foto_url'] as String?,
      fotoLocal:          map['foto_local'] as String?,
      latitud:            (map['latitud'] as num?)?.toDouble(),
      longitud:           (map['longitud'] as num?)?.toDouble(),
      vacunadorId:        map['vacunador_id'] as String?,
      sectorId:           map['sector_id'] as String?,
      fecha:              DateTime.parse(map['fecha'] as String),
      sincronizado:       map['sincronizado'] as bool? ?? false,
    );
  }

  // ── Icono por tipo de mascota ──────────────────────────────
  String get iconoMascota => tipoMascota == 'perro' ? '🐶' : '🐱';

  // ── copyWith ───────────────────────────────────────────────
  Vacunacion copyWith({
    String? id,
    String? propietarioNombre,
    String? propietarioCedula,
    String? telefono,
    String? tipoMascota,
    String? mascotaNombre,
    String? edadAprox,
    String? sexo,
    String? vacuna,
    String? observaciones,
    String? fotoUrl,
    String? fotoLocal,
    double? latitud,
    double? longitud,
    String? vacunadorId,
    String? sectorId,
    DateTime? fecha,
    bool? sincronizado,
    String? vacunadorNombre,
    String? sectorNombre,
  }) {
    return Vacunacion(
      id:                id                ?? this.id,
      propietarioNombre: propietarioNombre  ?? this.propietarioNombre,
      propietarioCedula: propietarioCedula  ?? this.propietarioCedula,
      telefono:          telefono           ?? this.telefono,
      tipoMascota:       tipoMascota        ?? this.tipoMascota,
      mascotaNombre:     mascotaNombre      ?? this.mascotaNombre,
      edadAprox:         edadAprox          ?? this.edadAprox,
      sexo:              sexo               ?? this.sexo,
      vacuna:            vacuna             ?? this.vacuna,
      observaciones:     observaciones      ?? this.observaciones,
      fotoUrl:           fotoUrl            ?? this.fotoUrl,
      fotoLocal:         fotoLocal          ?? this.fotoLocal,
      latitud:           latitud            ?? this.latitud,
      longitud:          longitud           ?? this.longitud,
      vacunadorId:       vacunadorId        ?? this.vacunadorId,
      sectorId:          sectorId           ?? this.sectorId,
      fecha:             fecha              ?? this.fecha,
      sincronizado:      sincronizado       ?? this.sincronizado,
      vacunadorNombre:   vacunadorNombre    ?? this.vacunadorNombre,
      sectorNombre:      sectorNombre       ?? this.sectorNombre,
    );
  }

  @override
  String toString() => 'Vacunacion($mascotaNombre - $tipoMascota)';

  @override
  bool operator ==(Object other) =>
      other is Vacunacion && other.id == id;

  @override
  int get hashCode => id.hashCode;
}