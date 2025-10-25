import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class DBActividades {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'app.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        // crea tabla actividades
        await db.execute('''
          CREATE TABLE actividades(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productorId INTEGER,
            fecha TEXT,
            actividad TEXT,
            responsable TEXT,
            cantidad TEXT,
            jornales TEXT,
            observaciones TEXT
          )
        ''');

        // crea tabla riegos (asegúrate de que exista)
        await db.execute('''
          CREATE TABLE riegos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            actividadId INTEGER,
            cantidad_agua TEXT,
            metodo TEXT,
            hora TEXT,
            observaciones TEXT,
            FOREIGN KEY (actividadId) REFERENCES actividades(id)
          )
        ''');

        // crea tabla fertilizaciones
        await db.execute('''
          CREATE TABLE fertilizaciones(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            actividadId INTEGER,
            sector TEXT,
            cultivo_variedad TEXT,
            contenido_nutricional TEXT,
            fecha_aplicacion TEXT,
            metodo_aplicacion TEXT,
            operador TEXT,
            area TEXT,
            cantidad TEXT,
            codigo TEXT,
            productor TEXT,
            FOREIGN KEY (actividadId) REFERENCES actividades(id)
          )
        ''');

        // crea tabla cosechas
        await db.execute('''
          CREATE TABLE cosechas(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            actividadId INTEGER,
            fecha TEXT,
            tipo TEXT,
            cantidad TEXT,
            cliente TEXT,
            numero_liquidacion TEXT,
            FOREIGN KEY (actividadId) REFERENCES actividades(id)
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute(
              "ALTER TABLE actividades ADD COLUMN cantidad TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE actividades ADD COLUMN jornales TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE actividades ADD COLUMN observaciones TEXT;",
            );
          } catch (_) {}
          // Asegurarse de que las tablas nuevas existan tras upgrade
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS riegos(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                actividadId INTEGER,
                cantidad_agua TEXT,
                metodo TEXT,
                hora TEXT,
                observaciones TEXT,
                FOREIGN KEY (actividadId) REFERENCES actividades(id)
              )
            ''');
          } catch (_) {}
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS fertilizaciones(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                actividadId INTEGER,
                sector TEXT,
                cultivo_variedad TEXT,
                contenido_nutricional TEXT,
                fecha_aplicacion TEXT,
                metodo_aplicacion TEXT,
                operador TEXT,
                area TEXT,
                cantidad TEXT,
                codigo TEXT,
                productor TEXT,
                FOREIGN KEY (actividadId) REFERENCES actividades(id)
              )
            ''');
          } catch (_) {}
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS cosechas(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                actividadId INTEGER,
                fecha TEXT,
                tipo TEXT,
                cantidad TEXT,
                cliente TEXT,
                numero_liquidacion TEXT,
                FOREIGN KEY (actividadId) REFERENCES actividades(id)
              )
            ''');
          } catch (_) {}
        }
      },
    );

    // seguridad extra si la BD ya existía pero faltan tablas
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS actividades(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productorId INTEGER,
        fecha TEXT,
        actividad TEXT,
        responsable TEXT,
        cantidad TEXT,
        jornales TEXT,
        observaciones TEXT
      )
    ''');
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS riegos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actividadId INTEGER,
        cantidad_agua TEXT,
        metodo TEXT,
        hora TEXT,
        observaciones TEXT,
        FOREIGN KEY (actividadId) REFERENCES actividades(id)
      )
    ''');
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS fertilizaciones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actividadId INTEGER,
        sector TEXT,
        cultivo_variedad TEXT,
        contenido_nutricional TEXT,
        fecha_aplicacion TEXT,
        metodo_aplicacion TEXT,
        operador TEXT,
        area TEXT,
        cantidad TEXT,
        codigo TEXT,
        productor TEXT,
        FOREIGN KEY (actividadId) REFERENCES actividades(id)
      )
    ''');
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS cosechas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actividadId INTEGER,
        fecha TEXT,
        tipo TEXT,
        cantidad TEXT,
        cliente TEXT,
        numero_liquidacion TEXT,
        FOREIGN KEY (actividadId) REFERENCES actividades(id)
      )
    ''');

    return _db!;
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
    try {
      return await dbClient.query(
        'actividades',
        where: 'productorId = ?',
        whereArgs: [productorId],
        orderBy: 'fecha DESC, id DESC',
      );
    } on DatabaseException catch (e) {
      final msg = e.toString();
      if (msg.contains('no such table') || msg.contains('no such column')) {
        // Crear tabla si falta (schema mínimo esperado)
        await dbClient.execute('''
          CREATE TABLE IF NOT EXISTS actividades(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productorId INTEGER,
            fecha TEXT,
            actividad TEXT,
            responsable TEXT,
            cantidad TEXT,
            jornales TEXT,
            observaciones TEXT
          )
        ''');
        // reintentar la consulta
        return await dbClient.query(
          'actividades',
          where: 'productorId = ?',
          whereArgs: [productorId],
          orderBy: 'fecha DESC, id DESC',
        );
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> obtenerRiegoPorActividad(
    int actividadId,
  ) async {
    final dbClient = await db;
    final res = await dbClient.query(
      'riegos',
      where: 'actividadId = ?',
      whereArgs: [actividadId],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  static Future<Map<String, dynamic>?> obtenerFertilizacionPorActividad(
    int actividadId,
  ) async {
    final dbClient = await db;
    final res = await dbClient.query(
      'fertilizaciones',
      where: 'actividadId = ?',
      whereArgs: [actividadId],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  static Future<Map<String, dynamic>?> obtenerCosechaPorActividad(
    int actividadId,
  ) async {
    final dbClient = await db;
    final res = await dbClient.query(
      'cosechas',
      where: 'actividadId = ?',
      whereArgs: [actividadId],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
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
    return await dbClient.query('actividades', orderBy: 'fecha DESC, id DESC');
  }

  static Future<void> agregarRiego(Map<String, Object?> nuevoRiego) async {
    final dbClient = await db;
    await dbClient.insert('riegos', nuevoRiego);
  }

  static Future<void> agregarCosecha(Map<String, Object?> nuevaCosecha) async {
    final dbClient = await db;
    await dbClient.insert('cosechas', nuevaCosecha);
  }

  static Future<void> agregarFertilizacion(
    Map<String, Object?> nuevaFertilizacion,
  ) async {
    final dbClient = await db;
    await dbClient.insert('fertilizaciones', nuevaFertilizacion);
  }

  static Future<void> realizarActividadDeRiego({
    required int productorId,
    required String responsable,
    required String observaciones,
    required String cantidadAgua,
    required String metodoRiego,
    required String horaRiego,
    required String observacionesRiego,
  }) async {
    final actividadId = await agregarActividad({
      'productorId': productorId,
      'fecha': DateTime.now().toIso8601String(),
      'actividad': 'Riego',
      'responsable': responsable,
      'observaciones': observaciones,
    });

    await agregarRiego({
      'actividadId': actividadId,
      'cantidad_agua': cantidadAgua,
      'metodo': metodoRiego,
      'hora': horaRiego,
      'observaciones': observacionesRiego,
    });
  }

  static Future<void> realizarActividadDeFertilizacion({
    required int productorId,
    required String responsable,
    required String observaciones,
    required String sector,
    required String cultivoVariedad,
    required String contenidoNutricional,
    required String fechaAplicacion,
    required String metodoAplicacion,
    required String operador,
    required String area,
    required String cantidad,
    required String codigo,
    required String productor,
  }) async {
    final actividadId = await agregarActividad({
      'productorId': productorId,
      'fecha': DateTime.now().toIso8601String(),
      'actividad': 'Fertilización',
      'responsable': responsable,
      'observaciones': observaciones,
    });

    await agregarFertilizacion({
      'actividadId': actividadId,
      'sector': sector,
      'cultivo_variedad': cultivoVariedad,
      'contenido_nutricional': contenidoNutricional,
      'fecha_aplicacion': fechaAplicacion,
      'metodo_aplicacion': metodoAplicacion,
      'operador': operador,
      'area': area,
      'cantidad': cantidad,
      'codigo': codigo,
      'productor': productor,
    });
  }

  static Future<void> realizarActividadDeCosecha({
    required int productorId,
    required String responsable,
    required String observaciones,
    required String fecha,
    required String tipo,
    required String cantidad,
    required String cliente,
    required String numeroLiquidacion,
  }) async {
    final actividadId = await agregarActividad({
      'productorId': productorId,
      'fecha': fecha,
      'actividad': 'Cosecha',
      'responsable': responsable,
      'observaciones': observaciones,
      'cantidad': cantidad,
    });

    await agregarCosecha({
      'actividadId': actividadId,
      'fecha': fecha,
      'tipo': tipo,
      'cantidad': cantidad,
      'cliente': cliente,
      'numero_liquidacion': numeroLiquidacion,
    });
  }
}
