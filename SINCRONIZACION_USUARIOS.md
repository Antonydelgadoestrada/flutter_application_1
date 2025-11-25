# Sincronización de Usuarios - Flujo Completo

## 📱 Escenario: Admin crea usuarios y los inspectores nuevos pueden acceder

### **PASO 1: Admin crea un usuario**
1. Admin abre la app → va a "Panel de Admin" → "Gestionar Usuarios"
2. Crea usuario: `juan`, password: `Juan123456!`
3. **Automáticamente se sube a Firestore** ✅
   - Con `usuario`, `password`, `dni`, `correo`, `telefono`, `cargo`, `role`
4. Se muestra SnackBar: "Usuario creado y sincronizado"

### **PASO 2: Inspector nuevo descarga la app**
1. Inspector instala la app por primera vez
2. La app detecta que es la PRIMERA VEZ (SharedPreferences: `primera_vez_app = true`)
3. **Automáticamente descarga todos los usuarios de Firestore** ✅
   - Incluye: `juan` con su contraseña
4. Se marcan como `sync_status='synced'`
5. Se actualiza SharedPreferences: `primera_vez_app = false`

### **PASO 3: Inspector nuevo puede iniciar sesión**
1. Inspector abre la app
2. Intenta iniciar con `juan` / `Juan123456!`
3. ✅ **Inicia sesión exitosamente** (usuario existe en SQLite local con contraseña correcta)

### **PASO 4: Inspector sincroniza manualmente (opcional)**
1. Inspector abre drawer → "Sincronizar" → "Sincronizar con servidor"
2. La app:
   - 📤 Sube sus usuarios locales pendientes a Firestore
   - 📥 Descarga usuarios nuevos del servidor

---

## 🔑 Cambios Implementados

### 1. **`admin_users_page.dart`** - Sincronización automática al crear
```dart
if (id > 0) {
  // Usuario creado exitosamente
  // Automáticamente subirlo a Firestore
  try {
    await SyncUsuarios.subirUsuariosAlServidor();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario creado y sincronizado')),
    );
  }
}
```

### 2. **`sync_usuarios.dart`** - Incluir password en sincronización
```dart
// Sube usuarios CON PASSWORD a Firestore
final datos = {
  'usuario': usuario['usuario'],
  'password': usuario['password'],  // ✅ IMPORTANTE
  'dni': usuario['dni'],
  // ...
};

// Descarga usuarios Y asigna password temporal si falta
if (datos['password'] == null || (datos['password'] as String).isEmpty) {
  datos['password'] = 'TempPassword123!';
}
```

### 3. **`main.dart`** - Descarga automática en primer inicio
```dart
if (esLaPrimeraVez) {
  debugPrint('Primera vez abriendo la app, descargando usuarios...');
  await SyncUsuarios.descargarUsuariosDelServidor();
  await prefs.setBool('primera_vez_app', false);
}
```

---

## ⚠️ Notas Importantes

### Seguridad
- ⚠️ **Las contraseñas se guardan en Firestore** - En producción considera:
  - Usar hashing (bcrypt, argon2)
  - No almacenar passwords en texto plano
  - Usar Firebase Authentication

### Flujo de actualización de contraseña
1. Si admin CAMBIA un password localmente, debe SINCRONIZAR
2. El nuevo password se subirá a Firestore
3. Otros inspectores descargarán el nuevo password

### Si no sincroniza el admin
- Los usuarios **NO aparecen en Firestore**
- Otros inspectores **NO pueden acceder**
- La app muestra: "Usuario o contraseña incorrectos"

---

## 🧪 Prueba Paso a Paso

### Prueba 1: Crear usuario y que otro dispositivo acceda
1. **Dispositivo A (Admin)**:
   - Abre app → Panel Admin → Crear usuario `prueba` / `Prueba123!`
   - ✅ Espera "Usuario creado y sincronizado"

2. **Dispositivo B (Inspector nuevo)**:
   - Desinstala app (para limpiar SQLite)
   - Reinstala app
   - ✅ Debería descargar `prueba` automáticamente
   - Intenta iniciar sesión con `prueba` / `Prueba123!`
   - ✅ **Debería funcionar**

### Prueba 2: Sincronización manual
1. **Dispositivo A**: Crea otro usuario `test` / `Test123456!`
2. **Dispositivo B**: Drawer → Sincronizar con servidor
3. ✅ Debería descargar `test` y poder usarlo

---

## 📊 Estados de Sincronización

| sync_status | Significado | Acción |
|-------------|------------|--------|
| `pending` | Usuario creado localmente pero no en Firestore | Esperando sincronizar |
| `synced` | Usuario en Firestore y sincronizado | Listo para usar |
| `deleted` | Usuario marcado para eliminar | Para futuras mejoras |

---

## 🚀 Próximas Mejoras (Opcionales)

- [ ] Implementar cambio de contraseña
- [ ] Eliminar usuarios y sincronizar borrado
- [ ] Mostrar estado de sincronización en UI
- [ ] Usar Firebase Authentication en lugar de password en texto plano
- [ ] Sincronización en background automática
