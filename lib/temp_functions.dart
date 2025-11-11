import 'db_helper.dart';

class TempFunctions {
  // Actualizar detalles de riego
  static Future<int> actualizarRiego(
    int actividadId,
    Map<String, dynamic> data,
  ) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    final payload = {...data, 'sync_status': 'pending', 'updated_at': now};
    return await dbClient.update(
      'riegos',
      payload,
      where: 'actividadId = ?',
      whereArgs: [actividadId],
    );
  }

  // Actualizar detalles de fertilización
  static Future<int> actualizarFertilizacion(
    int actividadId,
    Map<String, dynamic> data,
  ) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    final payload = {...data, 'sync_status': 'pending', 'updated_at': now};
    return await dbClient.update(
      'fertilizaciones',
      payload,
      where: 'actividadId = ?',
      whereArgs: [actividadId],
    );
  }

  // Actualizar detalles de cosecha
  static Future<int> actualizarCosecha(
    int actividadId,
    Map<String, dynamic> data,
  ) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    final payload = {...data, 'sync_status': 'pending', 'updated_at': now};
    return await dbClient.update(
      'cosechas',
      payload,
      where: 'actividadId = ?',
      whereArgs: [actividadId],
    );
  }
}
