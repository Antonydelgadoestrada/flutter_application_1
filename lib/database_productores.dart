import 'db_helper.dart';

class DBProductores {
  // Columnas permitidas en la tabla `productores` (usadas para sanitizar payloads)
  static const List<String> _allowedColumns = [
    'nombre',
    'codigo',
    'area_total',
    'area',
    'cultivo',
    'estimado_cosecha',
    'densidad',
    'anio_siembra',
    'ubicacion',
    'coordenadas',
    'gnn',
    // metadata
    'id_remoto',
    'sync_status',
    'updated_at',
    'deleted_at',
  ];
  // Inserta un productor y devuelve el id insertado (establece metadata de sync)
  static Future<int> agregarProductor(Map<String, dynamic> productor) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    // Sanitizar para evitar insertar claves que no sean columnas válidas
    final cleaned = <String, dynamic>{};
    for (final k in _allowedColumns) {
      if (productor.containsKey(k)) cleaned[k] = productor[k];
    }
    final data = {
      ...cleaned,
      'id_remoto': productor['id_remoto'],
      'sync_status': productor['sync_status'] ?? 'pending',
      'updated_at': productor['updated_at'] ?? now,
      'deleted_at': productor['deleted_at'],
    };
    final id = await dbClient.insert('productores', data);
    return id;
  }

  static Future<List<Map<String, dynamic>>> obtenerProductores() async {
    final dbClient = await DBHelper.database;
    return await dbClient.query(
      'productores',
      orderBy: 'nombre COLLATE NOCASE',
    );
  }

  static Future<int?> obtenerIdPorNombre(String nombre) async {
    final dbClient = await DBHelper.database;
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
    final dbClient = await DBHelper.database;
    final res = await dbClient.query(
      'productores',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  // Eliminar productor: si tiene id_remoto hacemos soft-delete para sincronizar,
  // si no, borramos físicamente.
  static Future<int> eliminarProductor(int id) async {
    final dbClient = await DBHelper.database;
    final existing = await dbClient.query(
      'productores',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isEmpty) return 0;
    final row = existing.first;
    final now = DateTime.now().toIso8601String();
    if (row['id_remoto'] != null) {
      final res = await dbClient.update(
        'productores',
        {'sync_status': 'deleted', 'deleted_at': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
      return res;
    } else {
      return await dbClient.delete(
        'productores',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Actualiza productor y marca como pending para sincronización
  static Future<int> actualizarProductor(
    int id,
    Map<String, dynamic> data,
  ) async {
    final dbClient = await DBHelper.database;
    final now = DateTime.now().toIso8601String();
    // Sanitizar y quedarnos solo con las columnas reales de la tabla
    final cleaned = <String, dynamic>{};
    for (final k in _allowedColumns) {
      if (data.containsKey(k)) cleaned[k] = data[k];
    }
    final payload = {
      ...cleaned,
      'sync_status': data['sync_status'] ?? 'pending',
      'updated_at': data['updated_at'] ?? now,
    };
    return await dbClient.update(
      'productores',
      payload,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
