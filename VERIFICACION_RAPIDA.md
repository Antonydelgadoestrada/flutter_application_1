# Script de Verificación Firebase Storage

Ejecuta los siguientes comandos en PowerShell desde la carpeta del proyecto:

## 1. Verificar que google-services.json existe
```powershell
Test-Path "android/app/google-services.json"
```
Resultado esperado: `True`

## 2. Verificar dependencias en pubspec.yaml
```powershell
(Select-String -Path pubspec.yaml -Pattern "firebase_storage|firebase_core|excel|path_provider").Line
```
Resultado esperado: Ver 4 líneas con las dependencias

## 3. Limpiar caché y descargar dependencias
```powershell
flutter clean
flutter pub get
```

## 4. Actualizar archivos de Android (si es necesario)
```powershell
flutter pub get
cd android
./gradlew clean
cd ..
```

## 5. Ejecutar la app
```powershell
flutter run
```

---

## Verificación Manual en Firebase Console

1. Abre https://console.firebase.google.com/
2. Proyecto: `antony-flutterapp-dev`
3. Storage → Verifica que existe un bucket llamado:
   - `antony-flutterapp-dev.firebasestorage.app`
4. Si no existe → Crea uno con Modo de Prueba

---

## Verificación después de generar un reporte

1. Presiona "Generar reporte en servidor" en la app
2. Espera a que aparezca el SnackBar
3. Verifica en Firebase Console:
   - Storage → carpeta `reportes/` → debe tener archivos `reporte_completo_*.xlsx`
4. Verifica en el dispositivo:
   - Gestor de Archivos → Descargas → `reporte_completo_*.xlsx`

