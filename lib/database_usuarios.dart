import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'usuarios.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario TEXT UNIQUE,
            password TEXT,
            dni TEXT,
            correo TEXT,
            telefono TEXT,
            cargo TEXT,
            tipo TEXT,
            role TEXT,
            id_remoto TEXT,
            sync_status TEXT DEFAULT "pending",
            updated_at TEXT,
            deleted_at TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE usuarios ADD COLUMN dni TEXT');
          await db.execute('ALTER TABLE usuarios ADD COLUMN correo TEXT');
          await db.execute('ALTER TABLE usuarios ADD COLUMN telefono TEXT');
          await db.execute('ALTER TABLE usuarios ADD COLUMN cargo TEXT');
          try {
            await db.execute('ALTER TABLE usuarios ADD COLUMN role TEXT');
          } catch (e) {
            debugPrint('Columna role ya existe: $e');
          }
        }
        if (oldVersion < 3) {
          try {
            await db.execute('ALTER TABLE usuarios ADD COLUMN id_remoto TEXT');
          } catch (e) {
            debugPrint('Columna id_remoto ya existe: $e');
          }
          try {
            await db.execute(
              'ALTER TABLE usuarios ADD COLUMN sync_status TEXT DEFAULT "pending"',
            );
          } catch (e) {
            debugPrint('Columna sync_status ya existe: $e');
          }
          try {
            await db.execute('ALTER TABLE usuarios ADD COLUMN updated_at TEXT');
          } catch (e) {
            debugPrint('Columna updated_at ya existe: $e');
          }
          try {
            await db.execute('ALTER TABLE usuarios ADD COLUMN deleted_at TEXT');
          } catch (e) {
            debugPrint('Columna deleted_at ya existe: $e');
          }
        }
      },
    );
  }

  static Future<void> _exportarUsuariosAJson() async {
    final dbClient = await db;
    final usuarios = await dbClient.query('usuarios');
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/usuarios.json';
    final file = File(path);
    await file.writeAsString(json.encode(usuarios));
  }

  static Future<int> registrarUsuario(
    String usuario,
    String password, {
    String? dni,
    String? correo,
    String? telefono,
    String? cargo,
    String role = 'user',
  }) async {
    final dbClient = await db;
    try {
      debugPrint('📝 Intentando registrar usuario: "$usuario"');

      // Validar contraseña mínima
      if (!validarPassword(password)) {
        debugPrint('❌ Contraseña inválida para: $usuario');
        return -2; // contraseña inválida
      }

      // Verificar si usuario ya existe
      final existe = await dbClient.query(
        'usuarios',
        where: 'usuario = ?',
        whereArgs: [usuario],
        limit: 1,
      );

      if (existe.isNotEmpty) {
        debugPrint('❌ Usuario "$usuario" YA EXISTE en BD');
        return -1;
      }

      final now = DateTime.now().toIso8601String();
      final data = <String, dynamic>{
        'usuario': usuario,
        'password': password,
        'role': role,
        'sync_status': 'pending',
        'updated_at': now,
      };
      if (dni != null) data['dni'] = dni;
      if (correo != null) data['correo'] = correo;
      if (telefono != null) data['telefono'] = telefono;
      if (cargo != null) data['cargo'] = cargo;

      final id = await dbClient.insert('usuarios', data);
      debugPrint('✅ Usuario "$usuario" creado con ID: $id');
      await _exportarUsuariosAJson();
      return id;
    } catch (e) {
      debugPrint('❌ ERROR al registrar usuario "$usuario": $e');
      return -1; // Usuario ya existe u otro error
    }
  }

  // Valida requisitos mínimos de contraseña:
  // - al menos 8 caracteres
  // - al menos una mayúscula
  // - al menos una minúscula
  // - al menos un dígito
  // - al menos un carácter especial
  static bool validarPassword(String pwd) {
    if (pwd.length < 8) return false;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(pwd);
    final hasLower = RegExp(r'[a-z]').hasMatch(pwd);
    final hasDigit = RegExp(r'\d').hasMatch(pwd);
    final hasSpecial = RegExp(
      r'[!@#\$%\^&\*()_+\-=[\]{};:\"\\|,.<>\/?]',
    ).hasMatch(pwd);
    return hasUpper && hasLower && hasDigit && hasSpecial;
  }

  static Future<List<Map<String, dynamic>>> obtenerTodosUsuarios() async {
    final dbClient = await db;
    return await dbClient.query('usuarios', orderBy: 'usuario COLLATE NOCASE');
  }

  static Future<void> seedAdmin() async {
    final dbClient = await db;
    // comprobar si existe admin
    final res = await dbClient.query(
      'usuarios',
      where: 'usuario = ?',
      whereArgs: ['admin'],
      limit: 1,
    );
    if (res.isEmpty) {
      // insertar admin con contraseña administrado1234
      try {
        await dbClient.insert('usuarios', {
          'usuario': 'admin',
          'password': 'administrado1234',
          'role': 'admin',
        });
      } catch (e) {
        // ignore
      }
    }
  }

  static Future<int> eliminarUsuario(String usuario) async {
    final dbClient = await db;
    final res = await dbClient.delete(
      'usuarios',
      where: 'usuario = ?',
      whereArgs: [usuario],
    );
    await _exportarUsuariosAJson();
    return res;
  }

  // Elimina todos los usuarios EXCEPTO admin
  static Future<int> eliminarTodosUsuariosExceptoAdmin() async {
    final dbClient = await db;
    final res = await dbClient.delete(
      'usuarios',
      where: 'usuario != ?',
      whereArgs: ['admin'],
    );
    await _exportarUsuariosAJson();
    return res;
  }

  static Future<Map<String, dynamic>?> validarUsuario(
    String usuario,
    String password,
  ) async {
    final dbClient = await db;
    final res = await dbClient.query(
      'usuarios',
      where: 'usuario = ? AND password = ?',
      whereArgs: [usuario, password],
    );
    if (res.isNotEmpty) return res.first;

    // Fallback: si no existe la cuenta admin (por migraciones), permitir login
    // con las credenciales por defecto y crear el admin en la DB.
    if (usuario == 'admin' && password == 'administrado1234') {
      try {
        final adminData = {
          'usuario': 'admin',
          'password': 'administrado1234',
          'role': 'admin',
        };
        await dbClient.insert('usuarios', adminData);
        return adminData;
      } catch (_) {
        // Si falla la inserción, intentar obtener el admin existente
        final adminData = await obtenerUsuario('admin');
        if (adminData != null && adminData['password'] == password) {
          return adminData;
        }
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>?> obtenerUsuario(String usuario) async {
    final dbClient = await db;
    final res = await dbClient.query(
      'usuarios',
      where: 'usuario = ?',
      whereArgs: [usuario],
    );
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  // Métodos de sincronización
  static Future<List<Map<String, dynamic>>> obtenerUsuariosPendientes() async {
    final dbClient = await db;
    return await dbClient.query(
      'usuarios',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );
  }

  static Future<int> marcarUsuarioComoSynced(int id, String idRemoto) async {
    final dbClient = await db;
    return await dbClient.update(
      'usuarios',
      {
        'sync_status': 'synced',
        'id_remoto': idRemoto,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> insertarUsuarioDesdeFirestore(
    Map<String, dynamic> datos,
  ) async {
    final dbClient = await db;
    final now = DateTime.now().toIso8601String();
    final data = {...datos, 'sync_status': 'synced', 'updated_at': now};
    try {
      return await dbClient.insert('usuarios', data);
    } catch (e) {
      // Si ya existe, actualizar
      final usuario = datos['usuario'] as String?;
      if (usuario != null) {
        return await dbClient.update(
          'usuarios',
          data,
          where: 'usuario = ?',
          whereArgs: [usuario],
        );
      }
      rethrow;
    }
  }

  // Resetea completamente la base de datos (elimina todo y recrear con solo admin)
  // Limpia TODOS los usuarios excepto admin (opción rápida sin cerrar DB)
  static Future<int> limpiarTodosUsuariosExceptoAdmin() async {
    final dbClient = await db;
    return await dbClient.delete(
      'usuarios',
      where: 'usuario != ?',
      whereArgs: ['admin'],
    );
  }

  static Future<void> resetearBaseDatos() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'usuarios.db');

    // 1. Cerrar conexión actual
    if (_db != null) {
      await _db!.close();
      _db = null;
    }

    // 2. Eliminar archivo de BD y todos sus auxiliares
    final file = File(path);
    final fileWal = File('$path-wal');
    final fileShm = File('$path-shm');

    if (await file.exists()) {
      debugPrint('Eliminando: $path');
      await file.delete();
    }
    if (await fileWal.exists()) {
      debugPrint('Eliminando: $path-wal');
      await fileWal.delete();
    }
    if (await fileShm.exists()) {
      debugPrint('Eliminando: $path-shm');
      await fileShm.delete();
    }

    // 3. Reinicializar BD (se recreará vacía)
    debugPrint('Reinicializando BD...');
    final newDb = await _initDB();
    _db = newDb;
    debugPrint('BD reinicializada');

    // 4. Insertar admin de nuevo
    debugPrint('Insertando admin...');
    await seedAdmin();
    debugPrint('Admin insertado');
  }

  // Método para limpiar COMPLETAMENTE - borra tabla usuarios y la recrea
  static Future<void> limpiarTablaUsuarios() async {
    final dbClient = await db;
    try {
      debugPrint('Borrando tabla usuarios...');
      await dbClient.execute('DROP TABLE IF EXISTS usuarios');

      debugPrint('Recreando tabla usuarios...');
      await dbClient.execute('''
        CREATE TABLE usuarios(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          usuario TEXT UNIQUE,
          password TEXT,
          dni TEXT,
          correo TEXT,
          telefono TEXT,
          cargo TEXT,
          tipo TEXT,
          role TEXT,
          id_remoto TEXT,
          sync_status TEXT DEFAULT "pending",
          updated_at TEXT,
          deleted_at TEXT
        )
      ''');

      debugPrint('Insertando admin...');
      await seedAdmin();
      debugPrint('Tabla usuarios limpiada y recreada');
    } catch (e) {
      debugPrint('Error limpiando tabla: $e');
      rethrow;
    }
  }
}
