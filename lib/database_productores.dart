import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DBProductores {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'app.db');

    // Version 2 incluye nuevas columnas en productores
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE productores(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT,
            codigo TEXT,
            area_total TEXT,
            area TEXT,
            cultivo TEXT,
            estimado_cosecha TEXT,
            densidad TEXT,
            anio_siembra TEXT,
            ubicacion TEXT,
            coordenadas TEXT,
            gnn TEXT
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // Si venías de v1, añadimos columnas que faltaban (seguro con try/catch)
        if (oldVersion < 2) {
          try {
            await db.execute("ALTER TABLE productores ADD COLUMN codigo TEXT;");
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE productores ADD COLUMN area_total TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE productores ADD COLUMN area TEXT;");
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE productores ADD COLUMN cultivo TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE productores ADD COLUMN estimado_cosecha TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE productores ADD COLUMN densidad TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE productores ADD COLUMN anio_siembra TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE productores ADD COLUMN ubicacion TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE productores ADD COLUMN coordenadas TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE productores ADD COLUMN gnn TEXT;");
          } catch (_) {}
        }
      },
    );

    return _db!;
  }

  // Inserta un productor y devuelve el id insertado
  static Future<int> agregarProductor(Map<String, dynamic> productor) async {
    final dbClient = await db;
    final id = await dbClient.insert('productores', productor);
    return id;
  }

  static Future<List<Map<String, dynamic>>> obtenerProductores() async {
    final dbClient = await db;
    return await dbClient.query(
      'productores',
      orderBy: 'nombre COLLATE NOCASE',
    );
  }

  static Future<int?> obtenerIdPorNombre(String nombre) async {
    final dbClient = await db;
    final res = await dbClient.query(
      'productores',
      where: 'nombre = ?',
      whereArgs: [nombre],
      limit: 1,
    );
    if (res.isNotEmpty) return res.first['id'] as int;
    return null;
  }

  static Future<Map<String, dynamic>?> obtenerProductorPorId(int id) async {
    final dbClient = await db;
    final res = await dbClient.query(
      'productores',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  static Future<int> eliminarProductor(int id) async {
    final dbClient = await db;
    return await dbClient.delete(
      'productores',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> actualizarProductor(
    int id,
    Map<String, dynamic> data,
  ) async {
    final dbClient = await db;
    return await dbClient.update(
      'productores',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
