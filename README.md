# 🐾 Campaña de Vacunación Canina y Felina

Aplicación móvil para la gestión de campañas municipales de vacunación de perros y gatos, desarrollada con **Flutter** y **Supabase**. Permite administrar coordinadores, brigadas, vacunadores y registros de vacunación con captura de fotografía y geolocalización GPS, incluyendo soporte para funcionamiento **offline** con sincronización automática.

---

## 📋 Tabla de contenidos

- [Descripción general](#-descripción-general)
- [Roles del sistema](#-roles-del-sistema)
- [Credenciales de prueba](#-credenciales-de-prueba)
- [Funcionalidades](#-funcionalidades)
- [Tecnologías utilizadas](#-tecnologías-utilizadas)
- [Arquitectura del proyecto](#-arquitectura-del-proyecto)
- [Requisitos previos](#-requisitos-previos)
- [Instalación y configuración](#-instalación-y-configuración)
- [Estructura de la base de datos](#-estructura-de-la-base-de-datos)
- [Funcionamiento offline](#-funcionamiento-offline)
- [APK de prueba](#-apk-de-prueba)
- [Autor](#-autor)

---

## 📖 Descripción general

Esta aplicación fue desarrollada como proyecto académico para la materia de **Desarrollo de Aplicaciones Móviles**, dentro de la carrera de Tecnología Superior en Desarrollo de Software. Su objetivo es digitalizar la gestión de campañas municipales de vacunación antirrábica para perros y gatos, permitiendo el registro en campo de cada vacunación aplicada, con evidencia fotográfica y ubicación GPS, organizada por sectores o barrios de la ciudad.

El sistema cuenta con tres niveles de usuario jerárquicos, cada uno con permisos y vistas distintas según su responsabilidad dentro de la campaña.

---

## 👥 Roles del sistema

| Rol | Responsabilidad principal |
|---|---|
| **Coordinador de campaña** | Crea sectores, crea coordinadores de brigada y los asigna a sectores. Visualiza el dashboard general de toda la campaña. |
| **Coordinador de brigada** | Ve los sectores que tiene asignados, crea vacunadores, los asigna/reasigna a sectores y puede corregir cualquier registro de vacunación dentro de su sector. |
| **Vacunador** | Ve únicamente los sectores asignados, registra vacunaciones en campo (con foto y GPS) y puede editar únicamente sus propios registros. |

> Los usuarios **no se autoregistran**. Todas las cuentas son creadas por un rol superior dentro de la jerarquía. La contraseña inicial asignada a todo usuario nuevo es `Ecuador2026`, y el sistema obliga a cambiarla en el primer inicio de sesión.

---

## 🔑 Credenciales de prueba

| Rol | Correo | Contraseña |
|---|---|---|
| Coordinador de campaña | `admin@vacunas.com` | `Ecuador2026` |
| Coordinador de brigada | `jeffo@vacunas.com` | `Jeferson2026` |
| Vacunador | `kevin@vacunas.com` | `Kevin2025` |

> **Nota:** estas credenciales corresponden a usuarios precargados únicamente para fines de evaluación y pruebas. En un entorno de producción real, cada usuario debería cambiar su contraseña en el primer acceso, tal como exige el flujo de la aplicación.

---

## ⚙️ Funcionalidades

### Autenticación y gestión de usuarios
- Inicio de sesión con roles diferenciados (Supabase Auth).
- Creación de usuarios en cascada: coordinador de campaña → coordinador de brigada → vacunador.
- Datos obligatorios por usuario: cédula, nombres, apellidos, teléfono, correo electrónico.
- Cambio de contraseña obligatorio en el primer inicio de sesión.
- Recuperación de contraseña vía correo electrónico.

### Coordinador de campaña
- Creación de sectores/barrios de la ciudad.
- Creación de coordinadores de brigada.
- Asignación de coordinadores a sectores.
- Dashboard general de toda la campaña.

### Coordinador de brigada
- Visualización de sectores asignados.
- Creación de vacunadores.
- Asignación y reasignación de vacunadores a sectores.
- Corrección de cualquier registro de vacunación dentro de su sector.
- Dashboard filtrado a su sector.

### Vacunador
- Visualización exclusiva de sectores asignados.
- Registro de vacunaciones con los siguientes datos:
  - Nombre y cédula del propietario
  - Teléfono del propietario
  - Tipo de mascota (perro o gato)
  - Nombre, edad aproximada y sexo de la mascota
  - Vacuna aplicada
  - Observaciones
  - Fotografía de evidencia
  - Latitud y longitud (GPS automático)
  - Fecha y hora del registro
- Edición de registros propios.
- Captura de fotografía desde la cámara del dispositivo.
- Captura automática de ubicación GPS.

### Dashboard
Disponible según el rol, muestra como mínimo:
- Total de vacunaciones realizadas.
- Total de perros vacunados.
- Total de gatos vacunados.
- Vacunaciones agrupadas por sector.
- Vacunaciones agrupadas por vacunador.
- Registros pendientes de sincronización (offline).

---

## 🛠 Tecnologías utilizadas

| Categoría | Tecnología / Paquete |
|---|---|
| Framework móvil | Flutter |
| Backend / Auth / Base de datos / Storage | Supabase (`supabase_flutter`) |
| Navegación | `go_router` |
| Manejo de estado | `provider` |
| Captura de imágenes | `image_picker` |
| Geolocalización | `geolocator` |
| Persistencia local / offline | `hive_flutter` |
| Detección de conectividad | `connectivity_plus` |
| Identificadores únicos | `uuid` |
| Formato de fechas | `intl` |

---

## 🏗 Arquitectura del proyecto

El proyecto sigue una arquitectura por capas, separando claramente la interfaz, la lógica de negocio y el acceso a datos. Esta es la estructura real del proyecto:

```
lib/
├── core/
│   ├── constants.dart        # Colores, tema, roles, rutas, nombres de boxes de Hive
│   └── supabase.dart         # Configuración e inicialización del cliente Supabase
├── models/
│   ├── usuario.dart          # Modelo Usuario (cedula, nombres, apellidos, rol, sector_id...)
│   ├── sector.dart           # Modelo Sector (nombre, descripcion)
│   └── vacunacion.dart       # Modelo Vacunacion, con soporte fromJson/toJson y fromHiveMap/toHiveMap
├── providers/
│   └── auth_provider.dart    # Estado de sesión, rol actual y bandera de primer login
├── screens/
│   ├── login/                # login_page, change_password, forgot_password
│   ├── dashboard/             # admin_dashboard, brigada_dashboard, vacunador_dashboard
│   ├── sectores/              # sector_page, add_sector_page, mi_sector_page
│   ├── usuarios/              # user_list_page, user_form_page
│   └── vacunacion/            # registro_vacunacion_page, vacunacion_list_page
├── services/
│   ├── user_service.dart           # CRUD de usuarios (vía Edge Function 'crear-usuario')
│   ├── sector_service.dart         # CRUD de sectores y asignaciones
│   ├── vacunacion_service.dart     # CRUD de vacunaciones + lógica de sincronización offline
│   ├── storage_service.dart        # Subida/eliminación de fotos en Supabase Storage
│   ├── location_service.dart       # Captura de coordenadas GPS (geolocator)
│   ├── local_storage_service.dart  # Persistencia local con Hive
│   ├── connectivity_service.dart   # Detección de conectividad y disparo de sincronización
│   └── dashboard_service.dart      # Cálculo de estadísticas para los dashboards
├── widgets/
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── loading_overlay.dart
│   └── photo_picker_widget.dart    # Widget reutilizable para captura/selección de fotos
└── main.dart                  # Punto de entrada: inicializa Hive, Supabase y el GoRouter
```

- **`models/`**: representan las entidades del dominio y se encargan de mapear datos entre Supabase (`fromJson`/`toJson`) y el almacenamiento local en Hive (`fromHiveMap`/`toHiveMap`).
- **`services/`**: contienen toda la lógica de acceso a datos — consultas, inserciones y actualizaciones a Supabase, subida de imágenes a Storage, lectura/escritura en Hive para el modo offline y verificación de conectividad.
- **`providers/`**: gestionan el estado de la sesión (`AuthProvider`) y exponen el rol y el estado de "primer login" al resto de la app mediante `provider`.
- **`screens/`**: contienen únicamente lógica de presentación, organizadas en subcarpetas por funcionalidad y rol.
- **`core/`**: configuración transversal (tema visual, constantes, roles, rutas y conexión a Supabase).

Esta separación permite que el backend pueda sustituirse en el futuro modificando únicamente la capa de `services`, sin afectar la interfaz.

### Creación segura de usuarios (Edge Function)

La creación de coordinadores de brigada y vacunadores **no se hace directamente desde el cliente Flutter**. Crear un usuario en Supabase Auth requiere la `service_role key`, una clave privada que nunca debe exponerse en una app móvil. Por eso, `UserService.crearUsuario()` invoca una **Edge Function de Supabase** llamada `crear-usuario`, que corre del lado del servidor con esa clave y crea de forma atómica tanto el usuario en Auth como su fila correspondiente en la tabla `usuarios`, asignándole la contraseña inicial `Ecuador2026`.

---

## ✅ Requisitos previos

Antes de ejecutar el proyecto, asegúrate de tener instalado:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión estable más reciente)
- Un editor de código (VS Code o Android Studio)
- Una cuenta en [Supabase](https://supabase.com)
- Un emulador Android/iOS o un dispositivo físico para pruebas

---

## 🚀 Instalación y configuración

### 1. Clonar el repositorio

```bash
git clone https://github.com/<tu-usuario>/<tu-repositorio>.git
cd <tu-repositorio>
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar Supabase

1. Crea un proyecto en [supabase.com](https://supabase.com).
2. Ve a **Project Settings → API** y copia tu `Project URL` y tu `anon public key`.
3. Edita el archivo `lib/core/supabase.dart` con tus credenciales:

```dart
class SupabaseConfig {
  static const String url = 'TU_PROJECT_URL';
  static const String anonKey = 'TU_ANON_KEY';
  // ...
}
```

> ⚠️ **Importante:** este archivo es la única fuente de la URL y la `anon key` en todo el proyecto (no se duplican en otros archivos). Aun así, la `anon key` queda visible dentro del código fuente del repositorio.
> 
### 4. Crear las tablas en Supabase

Desde el **SQL Editor** de tu proyecto Supabase, crea las siguientes tablas (ver estructura detallada en la sección [Estructura de la base de datos](#-estructura-de-la-base-de-datos)):

- `usuarios`
- `sectores`
- `vacunaciones`

Configura las políticas de **Row Level Security (RLS)** según el rol de cada usuario para restringir lecturas/escrituras conforme a los permisos descritos en este documento.

### 5. Desplegar la Edge Function de creación de usuarios

La app crea usuarios (coordinadores de brigada y vacunadores) mediante una Edge Function llamada `crear-usuario`, que usa la `service_role key` de Supabase del lado del servidor para crear el usuario en Auth y su registro en la tabla `usuarios` de forma atómica.

```bash
supabase functions deploy crear-usuario
```

> Asegúrate de tener configurada la variable de entorno `SUPABASE_SERVICE_ROLE_KEY` en el entorno de la función (nunca en el cliente Flutter).

### 6. Configurar Storage

Crea un bucket público en Supabase Storage llamado **`fotos-vacunacion`** (nombre usado en `AppConstants.bucketFotos`) para almacenar las fotografías de los registros de vacunación.

### 7. Ejecutar la aplicación

```bash
flutter run
```

### 8. Generar el APK

```bash
flutter build apk --release
```

El archivo generado se ubicará en `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🗄 Estructura de la base de datos

Tablas usadas en Supabase, basadas en los modelos del proyecto (`lib/models/`):

### `usuarios`
| Columna | Tipo | Descripción |
|---|---|---|
| `id` | uuid | Igual al `id` del usuario en Supabase Auth |
| `cedula` | text | Cédula del usuario |
| `nombres` | text | Nombres |
| `apellidos` | text | Apellidos |
| `telefono` | text | Teléfono |
| `email` | text | Correo electrónico |
| `rol` | text | `coordinador_campania` \| `coordinador_brigada` \| `vacunador` |
| `sector_id` | uuid (FK → sectores.id) | Sector asignado (nulo para coordinador de campaña) |
| `primer_login` | boolean | `true` hasta que el usuario cambia su contraseña inicial |
| `created_at` | timestamp | Fecha de creación |

### `sectores`
| Columna | Tipo | Descripción |
|---|---|---|
| `id` | uuid | Identificador del sector |
| `nombre` | text | Nombre del sector/barrio |
| `descripcion` | text | Descripción opcional |
| `created_at` | timestamp | Fecha de creación |

### `vacunaciones`
| Columna | Tipo | Descripción |
|---|---|---|
| `id` | uuid | Identificador del registro |
| `propietario_nombre` | text | Nombre del propietario |
| `propietario_cedula` | text | Cédula del propietario |
| `telefono` | text | Teléfono del propietario |
| `tipo_mascota` | text | `perro` \| `gato` |
| `mascota_nombre` | text | Nombre de la mascota |
| `edad_aprox` | text | Edad aproximada |
| `sexo` | text | `macho` \| `hembra` |
| `vacuna` | text | Vacuna aplicada |
| `observaciones` | text | Observaciones opcionales |
| `foto_url` | text | URL pública de la foto en Supabase Storage |
| `latitud` / `longitud` | double | Coordenadas GPS capturadas automáticamente |
| `vacunador_id` | uuid (FK → usuarios.id) | Vacunador que realizó/edita el registro |
| `sector_id` | uuid (FK → sectores.id) | Sector donde se aplicó la vacuna |
| `fecha` | timestamp | Fecha y hora del registro |
| `sincronizado` | boolean | Indica si el registro ya fue confirmado en el servidor |

> Recomendado: habilitar **Row Level Security (RLS)** en las tres tablas, restringiendo lecturas/escrituras según `rol` y `sector_id` del usuario autenticado, conforme a los permisos descritos en la sección de Roles.

---

## 📡 Funcionamiento offline

La aplicación permite registrar vacunaciones sin conexión a internet, con sincronización automática real:

1. `ConnectivityService` (basado en `connectivity_plus`) escucha en segundo plano los cambios de conectividad del dispositivo.
2. Si no hay conexión disponible al momento de registrar una vacunación, el registro se guarda localmente con `LocalStorageService` usando **Hive** (`hiveBoxVacunaciones`), incluyendo la foto en una ruta local (`foto_local`) y el campo `sincronizado: false`.
3. El registro queda marcado como **pendiente de sincronización** y es visible en el dashboard correspondiente.
4. Cuando `connectivity_plus` detecta que el dispositivo recupera la conexión, `ConnectivityService` dispara automáticamente `VacunacionService.sincronizarOffline()`, que sube cada registro pendiente: primero la foto a Supabase Storage (bucket `fotos-vacunacion`) y luego la fila completa a la tabla `vacunaciones`.
5. También existe la opción de **sincronización manual** (`sincronizarManual()`) para forzar el proceso sin esperar el cambio automático de conectividad.
6. Una vez sincronizado, el registro se elimina de la cola local y deja de figurar como pendiente en el dashboard.

---

## 📱 APK de prueba

El archivo APK funcional para pruebas se encuentra disponible en:

📦 `/releases/app-release.apk`


---

## 👤 Autor

**Jhosselin Naula - Emilio Erazo**
Tecnología Superior en Desarrollo de Software
Proyecto académico — Desarrollo de Aplicaciones Móviles

---

## 📄 Licencia

Este proyecto fue desarrollado con fines académicos.

## 📹 Video 

Emilio Erazo
 
https://vt.tiktok.com/ZSCHMXLb7/ 