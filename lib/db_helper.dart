import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static Database? _database;
  static const _dbName = 'app.db';
  static const _dbVersion = 3; // incrementa si cambias esquema en el futuro

  static Future<Database> get database async {
    if (_database != null) return _database!;
    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        // tabla productores
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
            gnn TEXT,
            id_remoto TEXT,
            sync_status TEXT,
            updated_at TEXT,
            deleted_at TEXT
          )
        ''');

        // tabla actividades
        await db.execute('''
          CREATE TABLE actividades(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productorId INTEGER,
            fecha TEXT,
            actividad TEXT,
            responsable TEXT,
            cantidad TEXT,
            jornales TEXT,
            observaciones TEXT,
            id_remoto TEXT,
            sync_status TEXT,
            updated_at TEXT,
            deleted_at TEXT
          )
        ''');

        // riegos
        await db.execute('''
          CREATE TABLE riegos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            actividadId INTEGER,
            cantidad_agua TEXT,
            metodo TEXT,
            hora TEXT,
            observaciones TEXT,
            id_remoto TEXT,
            sync_status TEXT,
            updated_at TEXT,
            deleted_at TEXT,
            FOREIGN KEY (actividadId) REFERENCES actividades(id)
          )
        ''');

        // fertilizaciones
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
            id_remoto TEXT,
            sync_status TEXT,
            updated_at TEXT,
            deleted_at TEXT,
            FOREIGN KEY (actividadId) REFERENCES actividades(id)
          )
        ''');

        // cosechas
        await db.execute('''
          CREATE TABLE cosechas(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            actividadId INTEGER,
            fecha TEXT,
            tipo TEXT,
            cantidad TEXT,
            cliente TEXT,
            numero_liquidacion TEXT,
            id_remoto TEXT,
            sync_status TEXT,
            updated_at TEXT,
            deleted_at TEXT,
            FOREIGN KEY (actividadId) REFERENCES actividades(id)
          )
        ''');

        // usuarios (opcional, si existe manejo de usuarios)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS usuarios(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario TEXT,
            password TEXT,
            dni TEXT,
            correo TEXT,
            telefono TEXT,
            cargo TEXT,
            id_remoto TEXT,
            sync_status TEXT,
            updated_at TEXT,
            deleted_at TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // migración segura: añade columnas que no existan
        if (oldVersion < 3) {
          // productors
          try {
            await db.execute(
              "ALTER TABLE productores ADD COLUMN id_remoto TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE productores ADD COLUMN sync_status TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE productores ADD COLUMN updated_at TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE productores ADD COLUMN deleted_at TEXT;",
            );
          } catch (_) {}

          // actividades
          try {
            await db.execute(
              "ALTER TABLE actividades ADD COLUMN id_remoto TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE actividades ADD COLUMN sync_status TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE actividades ADD COLUMN updated_at TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE actividades ADD COLUMN deleted_at TEXT;",
            );
          } catch (_) {}

          // riegos
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS riegos(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                actividadId INTEGER,
                cantidad_agua TEXT,
                metodo TEXT,
                hora TEXT,
                observaciones TEXT,
                id_remoto TEXT,
                sync_status TEXT,
                updated_at TEXT,
                deleted_at TEXT,
                FOREIGN KEY (actividadId) REFERENCES actividades(id)
              )
            ''');
          } catch (_) {}

          // fertilizaciones
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
                id_remoto TEXT,
                sync_status TEXT,
                updated_at TEXT,
                deleted_at TEXT,
                FOREIGN KEY (actividadId) REFERENCES actividades(id)
              )
            ''');
          } catch (_) {}

          // cosechas
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
                id_remoto TEXT,
                sync_status TEXT,
                updated_at TEXT,
                deleted_at TEXT,
                FOREIGN KEY (actividadId) REFERENCES actividades(id)
              )
            ''');
          } catch (_) {}
        }
      },
    );

    // seguridad: crear tablas si faltan en DB previa
    try {
      await _database!.execute(
        '''CREATE TABLE IF NOT EXISTS productores(id INTEGER PRIMARY KEY AUTOINCREMENT)''',
      );
    } catch (_) {}
    try {
      await _database!.execute(
        '''CREATE TABLE IF NOT EXISTS actividades(id INTEGER PRIMARY KEY AUTOINCREMENT)''',
      );
    } catch (_) {}
    try {
      await _database!.execute(
        '''CREATE TABLE IF NOT EXISTS riegos(id INTEGER PRIMARY KEY AUTOINCREMENT)''',
      );
    } catch (_) {}
    try {
      await _database!.execute(
        '''CREATE TABLE IF NOT EXISTS fertilizaciones(id INTEGER PRIMARY KEY AUTOINCREMENT)''',
      );
    } catch (_) {}
    try {
      await _database!.execute(
        '''CREATE TABLE IF NOT EXISTS cosechas(id INTEGER PRIMARY KEY AUTOINCREMENT)''',
      );
    } catch (_) {}

    return _database!;
  }
}
