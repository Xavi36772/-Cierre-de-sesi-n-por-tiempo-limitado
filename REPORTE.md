# Reporte: App Flutter con Timer de Inactividad y Almacenamiento Encriptado

**Materia:** [Nombre de la materia]
**Alumno:** [Tu nombre]
**Fecha:** 18/07/2026

---

## 1. Descripción General

Aplicación móvil desarrollada en Flutter que implementa:

- Sistema de autenticación simulado (login/logout)
- Timer de inactividad que cierra la sesión automáticamente
- Almacenamiento encriptado del token y tiempo de última interacción mediante `flutter_secure_storage`
- Vista previa multi-dispositivo con `device_preview`

---

## 2. Estructura del Proyecto

```
lib/
├── main.dart                         # Punto de entrada, Provider y DevicePreview
├── providers/
│   └── session_provider.dart         # Estado de sesión y lógica de inactividad
├── screens/
│   ├── login_screen.dart             # Pantalla de inicio de sesión
│   └── home_screen.dart              # Pantalla principal con configuración
└── services/
    ├── encrypted_storage.dart        # CRUD encriptado con FlutterSecureStorage
    └── inactivity_service.dart       # Timer de inactividad configurable
```

---

## 3. Capturas de Pantalla

### 3.1 Pantalla de Login

> *[Captura: login_screen.dart mostrando los campos de usuario y contraseña vacíos]*

Pantalla inicial al abrir la app sin sesión activa. Contiene dos campos de texto y un botón "Iniciar Sesión". No hay validación contra backend — cualquier usuario/contraseña inicia sesión.

**Código relevante:** `lib/screens/login_screen.dart:30-34`

```dart
TextFormField(
  decoration: const InputDecoration(labelText: 'Usuario'),
)
```

---

### 3.2 Inicio de Sesión

> *[Captura: login con datos ingresados]*

El usuario ingresa credenciales y presiona "Iniciar Sesión". El `SessionProvider.login()` genera un token simulado y lo almacena de forma encriptada.

**Flujo:**
1. Se crea un token con formato `token_{usuario}_{timestamp}`
2. Se guarda en `FlutterSecureStorage` con `saveToken()`
3. Se guarda el timeout configurado con `saveInactivityTimeout()`
4. Se inicia el monitoreo de inactividad

---

### 3.3 Pantalla de Inicio — Sesión Activa

> *[Captura: home_screen.dart mostrando el token y el selector de timeout]*

Muestra el token generado y un `DropdownButton` para configurar los minutos de inactividad antes del cierre automático.

**Selector de timeout:** 1, 2, 5 o 10 minutos.

---

### 3.4 Cambio de Timeout

> *[Captura: dropdown abierto mostrando las opciones de timeout]*

Cuando el usuario cambia el timeout, se actualiza en `FlutterSecureStorage` mediante `saveInactivityTimeout()` y se reinicia el timer interno.

**Código relevante:** `lib/providers/session_provider.dart:86-99`

```dart
void updateInactivityTimeout(int minutes) {
  _inactivityTimeoutMinutes = minutes;
  _storage.saveInactivityTimeout(minutes);
  _inactivityService.configure(
    timeout: Duration(minutes: minutes),
    onTimeout: () async => await _logout(),
  );
}
```

---

### 3.5 DevicePreview — Simulación Multi-Dispositivo

> *[Captura: DevicePreview mostrando la app en diferentes dispositivos como iPhone 15, Pixel 8, etc.]*

Gracias al paquete `device_preview`, la app se puede previsualizar en múltiples dispositivos sin necesidad de emuladores separados. Esto permite verificar que la UI se adapta correctamente.

**Configuración en** `lib/main.dart:11-15`:

```dart
DevicePreview(
  enabled: true,
  builder: (context) => ChangeNotifierProvider(
    create: (_) => SessionProvider(),
    child: const MyApp(),
  ),
)
```

---

### 3.6 Cierre de Sesión por Inactividad

> *[Captura: después de la inactividad, la app vuelve a la pantalla de login automáticamente]*

Cuando el usuario no interactúa con la app durante el tiempo configurado, el `InactivityService` ejecuta el callback `onTimeout`, que llama a `_logout()`. Este método:

1. Detiene el timer con `_inactivityService.stop()`
2. Elimina todos los datos encriptados con `_storage.clearAll()`
3. Limpia el token en memoria
4. Cambia el estado a `unauthenticated`
5. La UI se reconstruye mostrando la pantalla de login

**Código relevante:** `lib/services/inactivity_service.dart:31-36`

```dart
void _resetTimer() {
  _timer?.cancel();
  _timer = Timer(_timeout, () {
    _onTimeout?.call();
  });
}
```

---

## 4. Detección de Interacción del Usuario

La interacción se detecta de dos formas simultáneas:

1. **Global:** Widget `Listener` en `AuthGate` que captura `onPointerDown` y `onPointerMove`
2. **Ciclo de vida:** `WidgetsBindingObserver.didChangeAppLifecycleState` para detectar cuando la app vuelve a primer plano

Cada interacción registra la hora actual en `FlutterSecureStorage` y reinicia el timer.

```dart
// lib/main.dart:64-69
Listener(
  onPointerDown: (_) => session.registerInteraction(),
  onPointerMove: (_) => session.registerInteraction(),
)
```

---

## 5. Almacenamiento Encriptado

`flutter_secure_storage` utiliza:

- **Android:** EncryptedSharedPreferences (cifrado AES con clave en Android Keystore)
- **iOS:** Keychain Services de Apple

**Datos almacenados:**

| Key | Valor |
|-----|-------|
| `auth_token` | Token de autenticación |
| `last_interaction_time` | Timestamp de la última interacción |
| `inactivity_timeout_minutes` | Minutos de timeout configurados |

**Código:** `lib/services/encrypted_storage.dart`

```dart
final FlutterSecureStorage _storage = const FlutterSecureStorage();

Future<void> saveToken(String token) async {
  await _storage.write(key: _tokenKey, value: token);
}
```

---

## 6. Dependencias utilizadas

```yaml
flutter_secure_storage: ^9.2.4   # Almacenamiento encriptado
provider: ^6.1.2                 # Manejo de estado
device_preview: ^1.3.1           # Vista previa multi-dispositivo
```

---

## 7. Conclusión

La aplicación demuestra la implementación de un sistema de seguridad basado en inactividad del usuario, combinando:

- Detección de interacción a nivel de Widgets y ciclo de vida de la app
- Timer configurable para cierre automático de sesión
- Almacenamiento seguro de credenciales y metadatos de sesión mediante cifrado nativo de plataforma
- Arquitectura limpia con separación de servicios, estado y UI usando Provider
