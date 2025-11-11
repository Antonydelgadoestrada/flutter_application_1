import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';

class DBActividades {
  /// Genera un ID aleatorio único (número grande entre 1 y 2^31-1)
  /// Esto evita colisiones incluso si se crean actividades en múltiples dispositivos.
  static int _generarIdAleatorio() {
    final random = Random();
    return random.nextInt(0x7FFFFFFF) + 1; // Rango: 1 a 2,147,483,647
  }

  // Exportar actividades a JSON (mantener compatibilidad)
  static Future<void> _exportarActividadesAJson() async {
    final list = await obtenerTodasActividades();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/actividades_diarias.json');
    await file.writeAsString(json.encode(list));
  }

  // --- Actividades ---
  static Future<int> agregarActividad(Map<String, dynamic> actividad) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    final idAleatorio = _generarIdAleatorio();
    final data = {
      'id': idAleatorio, // Asignar ID aleatorio en lugar de AUTOINCREMENT
      ...actividad,
      'id_remoto': actividad['id_remoto'],
      'sync_status': actividad['sync_status'] ?? 'pending',
      'updated_at': actividad['updated_at'] ?? now,
      'deleted_at': actividad['deleted_at'],
    };
    final id = await dbClient.insert(
      'actividades',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _exportarActividadesAJson();
    return id;
  }

  static Future<int> actualizarActividad(
    int id,
    Map<String, dynamic> data,
  ) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    final payload = {
      ...data,
      'sync_status': data['sync_status'] ?? 'pending',
      'updated_at': data['updated_at'] ?? now,
    };
    final res = await dbClient.update(
      'actividades',
      payload,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _exportarActividadesAJson();
    return res;
  }

  static Future<int> eliminarActividad(int id) async {
    final dbClient = await DBHelper.database;
    final existing = await dbClient.query(
      'actividades',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isEmpty) return 0;
    final row = existing.first;
    final now = DateTime.now().toIso8601String();
    if (row['id_remoto'] != null) {
      // soft delete para sincronización
      final res = await dbClient.update(
        'actividades',
        {'sync_status': 'deleted', 'deleted_at': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
      await _exportarActividadesAJson();
      return res;
    } else {
      final res = await dbClient.delete(
        'actividades',
        where: 'id = ?',
        whereArgs: [id],
      );
      await _exportarActividadesAJson();
      return res;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerActividadesPorProductor(
    int productorId,
  ) async {
    final dbClient = await DBHelper.database;
    try {
      return await dbClient.query(
        'actividades',
        where: 'productorId = ?',
        whereArgs: [productorId],
        orderBy: 'fecha DESC, id DESC',
      );
    } on DatabaseException catch (e) {
      final msg = e.toString();
      if (msg.contains('no such table')) {
        // crear tabla si falta y reintentar
        await dbClient.execute('''
          CREATE TABLE IF NOT EXISTS actividades(
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

  static Future<List<Map<String, dynamic>>> obtenerTodasActividades() async {
    final dbClient = await DBHelper.database;
    return await dbClient.query('actividades', orderBy: 'fecha DESC, id DESC');
  }

  // --- Riegos ---
  static Future<int> agregarRiego(Map<String, dynamic> riego) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    final idAleatorio = _generarIdAleatorio();
    final data = {
      'id': idAleatorio,
      ...riego,
      'id_remoto': riego['id_remoto'],
      'sync_status': riego['sync_status'] ?? 'pending',
      'updated_at': riego['updated_at'] ?? now,
      'deleted_at': riego['deleted_at'],
    };
    return await dbClient.insert(
      'riegos',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> obtenerRiegoPorActividad(
    int actividadId,
  ) async {
    final dbClient = await DBHelper.database;
    final res = await dbClient.query(
      'riegos',
      where: 'actividadId = ?',
      whereArgs: [actividadId],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  static Future<int> actualizarRiego(int id, Map<String, dynamic> data) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    final payload = {
      ...data,
      'sync_status': data['sync_status'] ?? 'pending',
      'updated_at': data['updated_at'] ?? now,
    };
    // Actualizar por actividadId (relación con tabla actividades)
    try {
      final res = await dbClient.update(
        'riegos',
        payload,
        where: 'actividadId = ?',
        whereArgs: [id],
      );
      print('DBActividades.actualizarRiego -> payload: $payload, rows: $res');
      return res;
    } catch (e) {
      print('DBActividades.actualizarRiego ERROR: $e -- payload: $payload');
      rethrow;
    }
  }

  static Future<int> eliminarRiego(int id) async {
    final dbClient = await DBHelper.database;
    final existing = await dbClient.query(
      'riegos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isEmpty) return 0;
    final row = existing.first;
    final now = DateTime.now().toIso8601String();
    if (row['id_remoto'] != null) {
      return await dbClient.update(
        'riegos',
        {'sync_status': 'deleted', 'deleted_at': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      return await dbClient.delete('riegos', where: 'id = ?', whereArgs: [id]);
    }
  }

  // --- Fertilizaciones ---
  static Future<int> agregarFertilizacion(Map<String, dynamic> fert) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    final idAleatorio = _generarIdAleatorio();
    final data = {
      'id': idAleatorio,
      ...fert,
      'id_remoto': fert['id_remoto'],
      'sync_status': fert['sync_status'] ?? 'pending',
      'updated_at': fert['updated_at'] ?? now,
      'deleted_at': fert['deleted_at'],
    };
    return await dbClient.insert(
      'fertilizaciones',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> obtenerFertilizacionPorActividad(
    int actividadId,
  ) async {
    final dbClient = await DBHelper.database;
    final res = await dbClient.query(
      'fertilizaciones',
      where: 'actividadId = ?',
      whereArgs: [actividadId],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  static Future<int> actualizarFertilizacion(
    int id,
    Map<String, dynamic> data,
  ) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    final payload = {
      ...data,
      'sync_status': data['sync_status'] ?? 'pending',
      'updated_at': data['updated_at'] ?? now,
    };
    // Actualizar por actividadId
    try {
      final res = await dbClient.update(
        'fertilizaciones',
        payload,
        where: 'actividadId = ?',
        whereArgs: [id],
      );
      print(
        'DBActividades.actualizarFertilizacion -> payload: $payload, rows: $res',
      );
      return res;
    } catch (e) {
      print(
        'DBActividades.actualizarFertilizacion ERROR: $e -- payload: $payload',
      );
      rethrow;
    }
  }

  static Future<int> eliminarFertilizacion(int id) async {
    final dbClient = await DBHelper.database;
    final existing = await dbClient.query(
      'fertilizaciones',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isEmpty) return 0;
    final row = existing.first;
    final now = DateTime.now().toIso8601String();
    if (row['id_remoto'] != null) {
      return await dbClient.update(
        'fertilizaciones',
        {'sync_status': 'deleted', 'deleted_at': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      return await dbClient.delete(
        'fertilizaciones',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // --- Cosechas ---
  static Future<int> agregarCosecha(Map<String, dynamic> cosecha) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    final idAleatorio = _generarIdAleatorio();
    final data = {
      'id': idAleatorio,
      ...cosecha,
      'id_remoto': cosecha['id_remoto'],
      'sync_status': cosecha['sync_status'] ?? 'pending',
      'updated_at': cosecha['updated_at'] ?? now,
      'deleted_at': cosecha['deleted_at'],
    };
    return await dbClient.insert(
      'cosechas',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> obtenerCosechaPorActividad(
    int actividadId,
  ) async {
    final dbClient = await DBHelper.database;
    final res = await dbClient.query(
      'cosechas',
      where: 'actividadId = ?',
      whereArgs: [actividadId],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  static Future<int> actualizarCosecha(
    int id,
    Map<String, dynamic> data,
  ) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    final payload = {
      ...data,
      'sync_status': data['sync_status'] ?? 'pending',
      'updated_at': data['updated_at'] ?? now,
    };
    // Actualizar por actividadId
    try {
      final res = await dbClient.update(
        'cosechas',
        payload,
        where: 'actividadId = ?',
        whereArgs: [id],
      );
      print('DBActividades.actualizarCosecha -> payload: $payload, rows: $res');
      return res;
    } catch (e) {
      print('DBActividades.actualizarCosecha ERROR: $e -- payload: $payload');
      rethrow;
    }
  }

  static Future<int> eliminarCosecha(int id) async {
    final dbClient = await DBHelper.database;
    final existing = await dbClient.query(
      'cosechas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isEmpty) return 0;
    final row = existing.first;
    final now = DateTime.now().toIso8601String();
    if (row['id_remoto'] != null) {
      return await dbClient.update(
        'cosechas',
        {'sync_status': 'deleted', 'deleted_at': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      return await dbClient.delete(
        'cosechas',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // --- Utilidades para sync: obtener cambios pendientes ---
  static Future<List<Map<String, dynamic>>> obtenerCambiosPendientes({
    int limit = 500,
  }) async {
    final dbClient = await DBHelper.database;
    final List<Map<String, dynamic>> resultados = [];
    // tablas a revisar
    final tablas = [
      'productores',
      'actividades',
      'riegos',
      'fertilizaciones',
      'cosechas',
    ];
    for (final t in tablas) {
      try {
        final rows = await dbClient.query(
          t,
          where: 'sync_status IS NOT NULL AND sync_status != ?',
          whereArgs: ['synced'],
          limit: limit,
        );
        for (final r in rows) {
          resultados.add({'tabla': t, 'fila': r});
        }
      } catch (e) {
        // tabla puede no existir aún, ignorar
      }
    }
    return resultados;
  }

  // Marcar filas como 'syncing' antes de enviar
  static Future<void> marcarComoSyncing(String tabla, List<int> ids) async {
    if (ids.isEmpty) return;
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toUtc().toIso8601String();
    for (final id in ids) {
      try {
        await dbClient.update(
          tabla,
          {'sync_status': 'syncing', 'updated_at': now},
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (_) {}
    }
  }

  // Aplicar mapping id_local -> id_remoto y marcar como synced
  static Future<void> aplicarResultadoServidor(
    String tabla,
    List<Map<String, dynamic>> resultados,
  ) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toUtc().toIso8601String();
    for (final r in resultados) {
      final idLocal = r['id_local'];
      final idRemoto = r['id_remoto'];
      final status = (r['status'] ?? 'ok').toString();
      try {
        if (status == 'ok') {
          final payload = <String, Object?>{
            'id_remoto': idRemoto,
            'sync_status': 'synced',
            'updated_at': now,
          };
          await dbClient.update(
            tabla,
            payload,
            where: 'id = ?',
            whereArgs: [idLocal],
          );
        } else {
          // marcar error para reintento posterior
          await dbClient.update(
            tabla,
            {'sync_status': 'error', 'updated_at': now},
            where: 'id = ?',
            whereArgs: [idLocal],
          );
        }
      } catch (e) {
        // ignorar errores puntuales
      }
    }
  }

  // { changed code } Helpers transaccionales para crear actividad + detalle
  static Future<int> realizarActividadDeRiego({
    required int productorId,
    required String responsable,
    String? fecha,
    String? observaciones,
    required String cantidadAgua,
    required String metodoRiego,
    required String horaRiego,
    String? observacionesRiego,
  }) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    final fechaFinal = fecha ?? now;
    return await dbClient.transaction<int>((txn) async {
      final actividadId = _generarIdAleatorio();
      final actividad = {
        'id': actividadId,
        'productorId': productorId,
        'fecha': fechaFinal,
        'actividad': 'Riego',
        'responsable': responsable,
        'observaciones': observaciones ?? '',
        'cantidad': '', // campo general si aplica
        'jornales': null,
        'id_remoto': null,
        'sync_status': 'pending',
        'updated_at': now,
      };
      await txn.insert(
        'actividades',
        actividad,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final riegoId = _generarIdAleatorio();
      final riego = {
        'id': riegoId,
        'actividadId': actividadId,
        'cantidad_agua': cantidadAgua,
        'metodo': metodoRiego,
        'hora': horaRiego,
        'observaciones': observacionesRiego ?? '',
        'id_remoto': null,
        'sync_status': 'pending',
        'updated_at': now,
      };
      await txn.insert(
        'riegos',
        riego,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return actividadId;
    });
  }

  static Future<int> realizarActividadDeFertilizacion({
    required int productorId,
    required String responsable,
    String? fecha,
    String? observaciones,
    required String sector,
    required String cultivoVariedad,
    required String contenidoNutricional,
    required String fechaAplicacion,
    required String metodoAplicacion,
    required String operador,
    required String area,
    required String cantidad,
    required String codigo,
    required String productor, // campo adicional en fertilizaciones
  }) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    final fechaFinal = fecha ?? now;
    return await dbClient.transaction<int>((txn) async {
      final actividadId = _generarIdAleatorio();
      final actividad = {
        'id': actividadId,
        'productorId': productorId,
        'fecha': fechaFinal,
        'actividad': 'Fertilización',
        'responsable': responsable,
        'observaciones': observaciones ?? '',
        'cantidad': cantidad,
        'jornales': null,
        'id_remoto': null,
        'sync_status': 'pending',
        'updated_at': now,
      };
      await txn.insert(
        'actividades',
        actividad,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final fertId = _generarIdAleatorio();
      final fert = {
        'id': fertId,
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
        'id_remoto': null,
        'sync_status': 'pending',
        'updated_at': now,
      };
      await txn.insert(
        'fertilizaciones',
        fert,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return actividadId;
    });
  }

  static Future<int> realizarActividadDeCosecha({
    required int productorId,
    required String responsable,
    String? fecha,
    String? observaciones,
    required String fechaCosecha,
    required String tipo,
    required String cantidad,
    required String cliente,
    required String numeroLiquidacion,
  }) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    // fechaCosecha es obligatoria (non-nullable), por lo tanto basta con:
    final fechaFinal = fecha ?? fechaCosecha;
    return await dbClient.transaction<int>((txn) async {
      final actividadId = _generarIdAleatorio();
      final actividad = {
        'id': actividadId,
        'productorId': productorId,
        'fecha': fechaFinal,
        'actividad': 'Cosecha',
        'responsable': responsable,
        'observaciones': observaciones ?? '',
        'cantidad': cantidad,
        'jornales': null,
        'id_remoto': null,
        'sync_status': 'pending',
        'updated_at': now,
      };
      await txn.insert(
        'actividades',
        actividad,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final cosechaId = _generarIdAleatorio();
      final cosecha = {
        'id': cosechaId,
        'actividadId': actividadId,
        'fecha': fechaCosecha,
        'tipo': tipo,
        'cantidad': cantidad,
        'cliente': cliente,
        'numero_liquidacion': numeroLiquidacion,
        'id_remoto': null,
        'sync_status': 'pending',
        'updated_at': now,
      };
      await txn.insert(
        'cosechas',
        cosecha,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return actividadId;
    });
  }
}
