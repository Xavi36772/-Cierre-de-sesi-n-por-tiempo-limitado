# Configuración de Firebase para la App

## Requisitos
- Cuenta de Google
- Browser para acceder a [Firebase Console](https://console.firebase.google.com)

## Pasos

### 1. Crear proyecto en Firebase Console
1. Ve a https://console.firebase.google.com
2. Haz clic en "Crear proyecto"
3. Ingresa el nombre: `AlonsoAct2-FCM`
4. Desactiva Google Analytics (opcional)
5. Haz clic en "Crear proyecto"

### 2. Registrar la app Android
1. En la vista del proyecto, haz clic en el ícono de Android
2. Package name: `com.alonso.alonso_act2`
3. Apodo (opcional): `AlonsoAct2 Android`
4. SHA-1: déjalo vacío por ahora
5. Haz clic en "Registrar app"

### 3. Descargar y agregar google-services.json
1. Haz clic en "Descargar google-services.json"
2. Copia el archivo a: `android/app/google-services.json`

### 4. (Opcional) Registrar la app iOS
1. En la vista del proyecto, haz clic en el ícono de iOS+
2. Bundle ID: `com.alonso.alonso_act2`
3. Descarga el archivo `GoogleService-Info.plist`
4. Colócalo en `ios/Runner/` usando Xcode o Finder

### 5. Probar la app
```bash
cd "C:\Users\javie\AndroidStudioProjects\AlonsoAct2"
flutter run
```

## Enviar notificación de borrado remoto

Una vez que la app esté corriendo y hayas iniciado sesión:

### Obtener token FCM
El token FCM aparece en la pantalla de inicio de la app. Cópialo.

### Enviar comando de borrado remoto
Usa curl (reemplaza `TU_TOKEN_FCM` y `SERVER_KEY`):

```bash
# Obtén Server Key desde Firebase Console:
# Project Settings > Cloud Messaging > Server key

curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=TU_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "TU_TOKEN_FCM",
    "data": {
      "action": "remote_wipe",
      "user_id": "TU_USUARIO"
    }
  }'
```

O desde la Firebase Console:
1. Cloud Messaging > Enviar primera notificación
2. Ingresa título y texto (ej: "Borrado remoto")
3. En "Opciones avanzadas" > "Datos personalizados":
   - Clave: `action`, Valor: `remote_wipe`
   - Clave: `user_id`, Valor: `TU_USUARIO` (el username que usaste al iniciar sesión)
4. Envía la notificación

### Verificar
La app borrará los 5 datos sensibles y mostrará "No hay datos sensibles almacenados".
