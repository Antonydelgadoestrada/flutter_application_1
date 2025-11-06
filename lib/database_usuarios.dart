import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

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
      version: 2,
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
            role TEXT
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
            // ignore if already exists
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
      // Validar contraseña mínima
      if (!validarPassword(password)) {
        return -2; // contraseña inválida
      }
      final data = <String, dynamic>{
        'usuario': usuario,
        'password': password,
        'role': role,
      };
      if (dni != null) data['dni'] = dni;
      if (correo != null) data['correo'] = correo;
      if (telefono != null) data['telefono'] = telefono;
      if (cargo != null) data['cargo'] = cargo;

      final id = await dbClient.insert('usuarios', data);
      await _exportarUsuariosAJson();
      return id;
    } catch (e) {
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
}
