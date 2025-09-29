import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class DBActividades {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'actividades.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE actividades(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productorId INTEGER,
            fecha TEXT,
            actividad TEXT,
            responsable TEXT,
            observaciones TEXT
          )
        ''');
      },
    );
  }

  static Future<void> _exportarActividadesAJson() async {
    final actividades = await obtenerTodasActividades();
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/actividades_diarias.json';
    final file = File(path);
    await file.writeAsString(json.encode(actividades));
  }

  static Future<int> agregarActividad(Map<String, dynamic> actividad) async {
    final dbClient = await db;
    final id = await dbClient.insert('actividades', actividad);
    await _exportarActividadesAJson();
    return id;
  }

  static Future<List<Map<String, dynamic>>> obtenerActividadesPorProductor(
    int productorId,
  ) async {
    final dbClient = await db;
    return await dbClient.query(
      'actividades',
      where: 'productorId = ?',
      whereArgs: [productorId],
    );
  }

  static Future<int> eliminarActividad(int id) async {
    final dbClient = await db;
    final res = await dbClient.delete(
      'actividades',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _exportarActividadesAJson();
    return res;
  }

  static Future<List<Map<String, dynamic>>> obtenerTodasActividades() async {
    final dbClient = await db;
    return await dbClient.query('actividades');
  }
}
