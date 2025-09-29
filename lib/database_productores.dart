import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class DBProductores {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'productores.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE productores(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT,
            cultivo TEXT,
            ubicacion TEXT,
            telefono TEXT,
            correo TEXT
          )
        ''');
      },
    );
  }

  static Future<void> _exportarProductoresAJson() async {
    final productores = await obtenerProductores();
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/productores.json';
    final file = File(path);
    await file.writeAsString(json.encode(productores));
  }

  static Future<int> agregarProductor(Map<String, dynamic> productor) async {
    final dbClient = await db;
    final id = await dbClient.insert('productores', productor);
    await _exportarProductoresAJson();
    return id;
  }

  static Future<List<Map<String, dynamic>>> obtenerProductores() async {
    final dbClient = await db;
    return await dbClient.query('productores');
  }

  static Future<Map<String, dynamic>?> obtenerProductorPorId(int id) async {
    final dbClient = await db;
    final res = await dbClient.query(
      'productores',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  static Future<int> actualizarProductor(
    int id,
    Map<String, dynamic> productor,
  ) async {
    final dbClient = await db;
    final res = await dbClient.update(
      'productores',
      productor,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _exportarProductoresAJson();
    return res;
  }

  static Future<int> eliminarProductor(int id) async {
    final dbClient = await db;
    final res = await dbClient.delete(
      'productores',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _exportarProductoresAJson();
    return res;
  }
}
