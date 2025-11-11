# Cloud Function: generateReport

Esta función HTTP genera un archivo Excel con los datos de Firestore y lo sube a Firebase Storage.

Requisitos:
- Tener un proyecto Firebase con Firestore y Storage habilitados.
- Tener el CLI de Firebase instalado y autenticado (`npm install -g firebase-tools`).

Instalación y despliegue (desde la carpeta `functions`):

```bash
npm install
firebase deploy --only functions:generateReport
```

Uso:
- Llamar por POST con header `Authorization: Bearer <ID_TOKEN>` (token de Firebase Auth).
- La respuesta JSON incluye `{ url, path }` donde `url` es un enlace temporal para descargar el Excel.

Notas:
- Ajusta las colecciones listadas en `index.js` según tu esquema (`actividades`, `productores`, ...).
- Para producción, considera gestionar permisos y expiración del link, o almacenar metadatos en Firestore.
