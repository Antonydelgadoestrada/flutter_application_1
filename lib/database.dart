import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario TEXT UNIQUE,
            password TEXT
          )
        ''');
      },
    );
  }

  static Future<int> registrarUsuario(String usuario, String password) async {
    final dbClient = await db;
    try {
      return await dbClient.insert('usuarios', {
        'usuario': usuario,
        'password': password,
      });
    } catch (e) {
      return -1; // Usuario ya existe
    }
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
}
