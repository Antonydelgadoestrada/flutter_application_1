# Guía de Configuración Firebase Storage

## Requisitos
- Proyecto Firebase ya creado: `antony-flutterapp-dev`
- Flutter configurado con Firebase (ya está hecho en tu proyecto)
- Acceso a [Firebase Console](https://console.firebase.google.com/)

---

## Paso 1: Habilitar Cloud Storage

### En Firebase Console:
1. Ve a https://console.firebase.google.com/
2. Selecciona proyecto: **`antony-flutterapp-dev`**
3. Menú izquierdo → **Build** → **Storage**
4. Haz clic en **"Comenzar"** (Get started)
5. En el diálogo:
   - **Modo**: Selecciona **"Modo de prueba"** (Testing mode)
   - **Ubicación**: Elige según tu región:
     - América: `us-central1`
     - Europa: `europe-west1`
     - Latinoamérica: `northamerica-northeast1`
   - Acepta términos y crea el bucket

### Resultado esperado:
Verás un bucket llamado: `antony-flutterapp-dev.firebasestorage.app`

---

## Paso 2: Configurar Reglas de Seguridad

1. En Storage, ve a la pestaña **"Reglas"**
2. Elimina el contenido actual y pega esto:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Carpeta /reportes/ : lectura pública, escritura autenticada
    match /reportes/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

3. Haz clic en **"Publicar"** (Publish)

**Explicación**:
- `allow read: if true` → Cualquiera puede descargar reportes (sin login).
- `allow write: if request.auth != null` → Solo usuarios logueados pueden subir archivos.

---

## Paso 3: Verificar Dependencias (Dart/Flutter)

En tu `pubspec.yaml`, verifica que tengas:

```yaml
dependencies:
  firebase_core: ^2.10.0
  firebase_storage: ^11.1.0
  excel: ^2.0.3
  path_provider: ^2.0.0
```

Si falta alguna, añádela y ejecuta:

```bash
flutter pub get
```

---

## Paso 4: Verificar Configuración de Android

### Verificar `google-services.json`:
```bash
# Desde PowerShell en la carpeta del proyecto
Test-Path "android/app/google-services.json"
```

Si no existe:
1. Ve a Firebase Console → Proyecto → **Configuración** (⚙️)
2. **Configuración del proyecto** → **Aplicaciones** → Android
3. Descarga `google-services.json`
4. Colócalo en: `android/app/google-services.json`

### Verificar `android/build.gradle.kts`:
Debe tener (busca en el archivo):

```gradle
plugins {
    id("com.google.gms.google-services") version "4.3.15" apply false
}
```

### Verificar `android/app/build.gradle.kts`:
Debe tener (busca en el archivo):

```gradle
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")  // <-- Esta línea debe estar
}

dependencies {
    implementation("com.google.firebase:firebase-storage:20.2.1")
}
```

---

## Paso 5: Testear la Conexión

### Desde Flutter, ejecuta:

```bash
flutter run
```

Luego en la app:
1. Ve a **"Generar reportes"**
2. Presiona **"Generar reporte en servidor"**
3. Espera a que se genere

### Verificar éxito:

**En Firebase Console:**
1. Storage → Bucket
2. Deberías ver una carpeta **`reportes/`**
3. Dentro, un archivo como: `reporte_completo_1731324600000.xlsx`

**En el dispositivo:**
1. Abre el Gestor de Archivos
2. Ve a **Descargas** (Downloads)
3. Verifica que esté el archivo `reporte_completo_TIMESTAMP.xlsx`

---

## Paso 6: Cambiar a Modo Producción (Opcional)

Cuando la app esté lista para producción, cambia las reglas a algo más restrictivo:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /reportes/{allPaths=**} {
      // Solo usuarios autenticados pueden leer y escribir
      allow read, write: if request.auth != null;
      
      // Restricción adicional: solo el usuario que subió puede editar
      allow write: if request.auth.uid == resource.metadata.uploadedBy;
    }
  }
}
```

---

## Troubleshooting

### Problema: "Permission denied" al subir archivo
**Solución:**
- Verifica que las reglas de Storage permitan escritura
- Asegúrate de que el usuario está autenticado con Firebase Auth
- Temporalmente usa `allow write: if true` para testing

### Problema: Bucket no aparece en Storage
**Solución:**
- Recarga la página de Firebase Console
- Verifica que estés en el proyecto correcto (`antony-flutterapp-dev`)
- Si aún no aparece, crea un nuevo bucket: Storage → Create bucket

### Problema: Archivo no se descarga
**Solución:**
- Verifica que la carpeta `reportes/` exista en Storage
- Comprueba que el archivo se subió correctamente (verlo en Firebase Console)
- Prueba la URL en el navegador web (cópiala desde Firebase Console)

---

## URLs de Referencia
- [Firebase Storage Docs](https://firebase.google.com/docs/storage)
- [Firebase Storage Rules](https://firebase.google.com/docs/storage/security)
- [Firebase Console](https://console.firebase.google.com/)

