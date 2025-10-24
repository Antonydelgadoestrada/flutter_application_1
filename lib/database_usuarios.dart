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
            tipo TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE usuarios ADD COLUMN dni TEXT');
          await db.execute('ALTER TABLE usuarios ADD COLUMN correo TEXT');
          await db.execute('ALTER TABLE usuarios ADD COLUMN telefono TEXT');
          await db.execute('ALTER TABLE usuarios ADD COLUMN cargo TEXT');
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

  static Future<int> registrarUsuario(String usuario, String password) async {
    final dbClient = await db;
    try {
      final id = await dbClient.insert('usuarios', {
        'usuario': usuario,
        'password': password,
      });
      await _exportarUsuariosAJson();
      return id;
    } catch (e) {
      return -1; // Usuario ya existe
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

  static Future<bool> validarUsuario(String usuario, String password) async {
    final dbClient = await db;
    final res = await dbClient.query(
      'usuarios',
      where: 'usuario = ? AND password = ?',
      whereArgs: [usuario, password],
    );
    return res.isNotEmpty;
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
