import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_usuarios.dart';

/// Sincronización bidireccional de usuarios con Firestore
class SyncUsuarios {
  static const String _collection = 'usuarios';

  /// Descarga todos los usuarios desde Firestore y los guarda localmente
  /// Típicamente se llama la primera vez que se abre la app
  static Future<void> descargarUsuariosDelServidor() async {
    print('=== Descargando usuarios del servidor ===');
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .get();

      print('Usuarios encontrados en Firestore: ${snapshot.docs.length}');

      for (final doc in snapshot.docs) {
        final datos = doc.data();
        datos['id_remoto'] = doc.id;

        // Si no tiene password en Firestore, asignar una por defecto
        // (admin debe cambiarla después)
        if (datos['password'] == null ||
            (datos['password'] as String).isEmpty) {
          datos['password'] = 'TempPassword123!'; // Contraseña temporal segura
          print('Asignando password temporal a: ${datos['usuario']}');
        }

        await DBHelper.insertarUsuarioDesdeFirestore(datos);
        print('Usuario descargado: ${datos['usuario']}');
      }

      print('=== Descarga completada ===');
    } catch (e) {
      print('Error descargando usuarios: $e');
      rethrow;
    }
  }

  /// Sube usuarios locales con sync_status='pending' a Firestore
  static Future<void> subirUsuariosAlServidor() async {
    print('=== Subiendo usuarios al servidor ===');
    try {
      final pendientes = await DBHelper.obtenerUsuariosPendientes();
      print('Usuarios pendientes de sincronizar: ${pendientes.length}');

      for (final usuario in pendientes) {
        final id = usuario['id'] as int;
        final idRemoto = usuario['id_remoto'] as String?;

        // Preparar datos para Firestore (incluir password y todos los campos)
        final datos = {
          'usuario': usuario['usuario'],
          'password':
              usuario['password'], // Incluir password para poder acceder
          'dni': usuario['dni'],
          'correo': usuario['correo'],
          'telefono': usuario['telefono'],
          'cargo': usuario['cargo'],
          'role': usuario['role'] ?? 'user',
          'updated_at': DateTime.now().toIso8601String(),
        };

        try {
          if (idRemoto != null) {
            // Actualizar en Firestore
            await FirebaseFirestore.instance
                .collection(_collection)
                .doc(idRemoto)
                .update(datos);
            print('Usuario actualizado en Firestore: ${usuario['usuario']}');
          } else {
            // Crear nuevo en Firestore
            final docRef = await FirebaseFirestore.instance
                .collection(_collection)
                .add(datos);

            // Marcar como synced localmente
            await DBHelper.marcarUsuarioComoSynced(id, docRef.id);
            print('Usuario creado en Firestore: ${usuario['usuario']}');
          }
        } catch (e) {
          print('Error sincronizando usuario ${usuario['usuario']}: $e');
        }
      }

      print('=== Subida completada ===');
    } catch (e) {
      print('Error subiendo usuarios: $e');
      rethrow;
    }
  }

  /// Verifica si es la PRIMERA VEZ que se abre la app
  /// Detecta leyendo SharedPreferences
  static Future<bool> esLaPrimeraVez() async {
    // Implementar con SharedPreferences si se desea
    // Por ahora, devolvemos false (no es primera vez)
    // Esta lógica se puede mejorar
    return false;
  }
}
