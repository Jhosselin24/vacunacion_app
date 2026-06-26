import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/supabase.dart';
import '../../services/vacunacion_service.dart';

class RegistroVacunacionPage extends StatefulWidget {
  const RegistroVacunacionPage({super.key});

  @override
  State<RegistroVacunacionPage> createState() =>
      _RegistroVacunacionPageState();
}

class _RegistroVacunacionPageState
    extends State<RegistroVacunacionPage> {

  final service = VacunacionService();

  final picker = ImagePicker();

  File? imageFile;
  double? lat;
  double? lng;

  bool loading = false;

  // CONTROLADORES
  final nombreProp = TextEditingController();
  final cedulaProp = TextEditingController();
  final telefonoProp = TextEditingController();

  final nombreMascota = TextEditingController();
  final edad = TextEditingController();
  final vacuna = TextEditingController();
  final observaciones = TextEditingController();

  String tipoMascota = "perro";
  String sexo = "macho";

  // 📍 GPS
  Future<void> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      lat = position.latitude;
      lng = position.longitude;
    });
  }

  // 📷 CAMARA
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  // ☁️ SUBIR IMAGEN A SUPABASE
  Future<String?> uploadImage() async {
    if (imageFile == null) return null;

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    await supabase.storage
        .from('vacunas')
        .upload(fileName, imageFile!);

    final url = supabase.storage
        .from('vacunas')
        .getPublicUrl(fileName);

    return url;
  }

  // 💾 GUARDAR REGISTRO
  Future<void> save() async {

    setState(() => loading = true);

    final imageUrl = await uploadImage();

    await service.createVacunacion({
      "usuario_id": supabase.auth.currentUser!.id,
      "sector_id": null,

      "propietario_nombre": nombreProp.text,
      "propietario_cedula": cedulaProp.text,
      "propietario_telefono": telefonoProp.text,

      "tipo_mascota": tipoMascota,
      "nombre_mascota": nombreMascota.text,
      "edad_aprox": edad.text,
      "sexo": sexo,
      "vacuna": vacuna.text,
      "observaciones": observaciones.text,

      "foto_url": imageUrl,
      "latitud": lat,
      "longitud": lng,
    });

    setState(() => loading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro Vacunación")),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          TextField(controller: nombreProp, decoration: const InputDecoration(labelText: "Nombre Propietario")),
          TextField(controller: cedulaProp, decoration: const InputDecoration(labelText: "Cédula")),
          TextField(controller: telefonoProp, decoration: const InputDecoration(labelText: "Teléfono")),

          const SizedBox(height: 10),

          DropdownButtonFormField(
            value: tipoMascota,
            items: const [
              DropdownMenuItem(value: "perro", child: Text("Perro")),
              DropdownMenuItem(value: "gato", child: Text("Gato")),
            ],
            onChanged: (v) => setState(() => tipoMascota = v!),
          ),

          TextField(controller: nombreMascota, decoration: const InputDecoration(labelText: "Nombre Mascota")),
          TextField(controller: edad, decoration: const InputDecoration(labelText: "Edad Aproximada")),
          TextField(controller: vacuna, decoration: const InputDecoration(labelText: "Vacuna")),
          TextField(controller: observaciones, decoration: const InputDecoration(labelText: "Observaciones")),

          const SizedBox(height: 10),

          DropdownButtonFormField(
            value: sexo,
            items: const [
              DropdownMenuItem(value: "macho", child: Text("Macho")),
              DropdownMenuItem(value: "hembra", child: Text("Hembra")),
            ],
            onChanged: (v) => setState(() => sexo = v!),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: pickImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text("Tomar Foto"),
          ),

          if (imageFile != null)
            Image.file(imageFile!, height: 150),

          const SizedBox(height: 10),

          ElevatedButton.icon(
            onPressed: getLocation,
            icon: const Icon(Icons.location_on),
            label: Text(lat == null
                ? "Capturar GPS"
                : "GPS: $lat , $lng"),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: loading ? null : save,
            child: loading
                ? const CircularProgressIndicator()
                : const Text("Guardar Registro"),
          ),
        ],
      ),
    );
  }
}