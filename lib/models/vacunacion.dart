import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ── Adaptador Hive para persistencia offline ───────────────
// Ejecuta: flutter packages pub run build_runner build
// para generar vacunacion.g.dart automáticamente.
// O usa el toMap()/fromMap() manual que está al final.

@HiveType(typeId: 0)
class Vacunacion extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String propietarioNombre;

  @HiveField(2)
  final String propietarioCedula;

  @HiveField(3)
  final String telefono;

  @HiveField(4)
  final String tipoMascota; // 'perro' | 'gato'

  @HiveField(5)
  final String mascotaNombre;

  @HiveField(6)
  final String? edadAprox;

  @HiveField(7)
  final String? sexo; // 'macho' | 'hembra'

  @HiveField(8)
  final String vacuna;

  @HiveField(9)
  final String? observaciones;

  @HiveField(10)
  final String? fotoUrl;     // URL en Supabase Storage (online)

  @HiveField(11)
  final String? fotoLocal;   // ruta local cuando está offline

  @HiveField(12)
  final double? latitud;

  @HiveField(13)
  final double? longitud;

  @HiveField(14)
  final String? vacunadorId;

  @HiveField(15)
  final String? sectorId;

  @HiveField(16)
  final DateTime fecha;

  @HiveField(17)
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