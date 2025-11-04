import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';
import 'database_actividades.dart';

class SyncManager {
  // Cambia esta URL por la de tu servidor
  static const String _serverBase = 'https://tu-servidor.com/api';
  static const String _lastSyncKey = 'last_sync_at';
  static const int _batchSize = 200;
  static String? authToken; // opcional: asigna token si usas auth

  // Obtiene lastSync almacenado
  static Future<String?> _getLastSyncAt() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_lastSyncKey);
  }

  static Future<void> _setLastSyncAt(String ts) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_lastSyncKey, ts);
  }

  // Recolecta cambios pendientes (usa tu helper ya implementado)
  static Future<List<Map<String, dynamic>>> _collectPending({
    int limit = _batchSize,
  }) async {
    return await DBActividades.obtenerCambiosPendientes(limit: limit);
  }

  // Construye payload simple desde cambios
  static Map<String, dynamic> _buildPayload(
    List<Map<String, dynamic>> cambios, {
    String? clientId,
  }) {
    final List<Map<String, dynamic>> ops = [];
    for (final c in cambios) {
      final tabla = c['tabla'] as String;
      final fila = Map<String, dynamic>.from(c['fila'] as Map);
      final idLocal = fila['id'];
      final idRemoto = fila['id_remoto'];
      final syncStatus = (fila['sync_status'] ?? '').toString();

      String op = 'update';
      if (syncStatus == 'deleted') {
        op = 'delete';
      } else if (idRemoto == null)
        op = 'create';

      // limpiamos campos internos si quieres; aquí enviamos todo excepto campos locales temporales
      final data = Map<String, dynamic>.from(fila)
        ..remove('sync_status')
        ..remove('updated_at')
        ..remove('deleted_at');

      ops.add({
        'op': op,
        'table': tabla,
        'id_local': idLocal,
        'id_remoto': idRemoto,
        'data': data,
        'updated_at': fila['updated_at'],
      });
    }

    return {
      'clientId': clientId ?? 'mobile_app',
      'operations': ops,
      'clientTimestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // POST upload batch
  static Future<Map<String, dynamic>> _uploadBatch(
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$_serverBase/sync/upload');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
    final resp = await http
        .post(uri, headers: headers, body: json.encode(payload))
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Sync upload failed: ${resp.statusCode} ${resp.body}');
    }
  }

  // GET download changes since lastSync
  static Future<Map<String, dynamic>> _downloadChanges(String? since) async {
    final qs = since != null ? '?since=${Uri.encodeComponent(since)}' : '';
    final uri = Uri.parse('$_serverBase/sync/download$qs');
    final headers = <String, String>{
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
    final resp = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Sync download failed: ${resp.statusCode} ${resp.body}');
    }
  }

  // Procesar resultados devueltos por el servidor y actualizar DB local
  // Formato esperado (sencillo): { results: [{table, id_local, id_remoto, status}], serverTimestamp: '...'}
  static Future<void> _processUploadResults(Map<String, dynamic> resp) async {
    final results = resp['results'] as List? ?? [];
    // agrupar por tabla
    final Map<String, List<Map<String, dynamic>>> byTable = {};
    for (final r in results) {
      final t = r['table'] as String? ?? 'unknown';
      byTable.putIfAbsent(t, () => []).add({
        'id_local': r['id_local'],
        'id_remoto': r['id_remoto'],
        'status': r['status'],
      });
    }
    // aplicar resultados: utiliza el helper que creaste en DBActividades
    for (final entry in byTable.entries) {
      final tabla = entry.key;
      final resultados = entry.value
          .map(
            (e) => {
              'id_local': e['id_local'],
              'id_remoto': e['id_remoto'],
              'status': e['status'],
            },
          )
          .toList();
      await DBActividades.aplicarResultadoServidor(tabla, resultados);
    }
  }

  // Aplicar cambios descargados desde servidor: formato esperado {changes: [{table, id_remoto, data, updated_at, deleted}]}
  static Future<void> _applyDownloadedChanges(List<dynamic> changes) async {
    final db = await DBHelper.database;
    for (final ch in changes) {
      final table = ch['table'] as String;
      final idRemoto = ch['id_remoto'];
      final data = Map<String, dynamic>.from(ch['data'] as Map? ?? {});
      final deleted = ch['deleted'] == true;
      final serverUpdatedAt = ch['updated_at'] as String?;

      try {
        // Buscar fila local por id_remoto
        final rows = await db.query(
          table,
          where: 'id_remoto = ?',
          whereArgs: [idRemoto],
          limit: 1,
        );
        if (rows.isEmpty) {
          if (!deleted) {
            // insertar nueva fila con id_remoto y estado synced
            final insertData = {
              ...data,
              'id_remoto': idRemoto,
              'sync_status': 'synced',
              'updated_at':
                  serverUpdatedAt ?? DateTime.now().toUtc().toIso8601String(),
            };
            await db.insert(table, insertData);
          }
        } else {
          final local = rows.first;
          final localUpdated = local['updated_at'] as String?;
          // resolver por timestamp (last-write-wins)
          if (serverUpdatedAt != null &&
              (localUpdated == null ||
                  serverUpdatedAt.compareTo(localUpdated) >= 0)) {
            if (deleted) {
              // si servidor indica borrado -> borrar local (o marcar deleted)
              await db.delete(
                table,
                where: 'id_remoto = ?',
                whereArgs: [idRemoto],
              );
            } else {
              final payload = {
                ...data,
                'id_remoto': idRemoto,
                'sync_status': 'synced',
                'updated_at': serverUpdatedAt,
              };
              await db.update(
                table,
                payload,
                where: 'id_remoto = ?',
                whereArgs: [idRemoto],
              );
            }
          } // else: local mas reciente -> lo conservar (se subirá en próximo upload)
        }
      } catch (_) {
        // ignore table-not-exist or other transient errors for now
      }
    }
  }

  // Ejecuta sincronización completa (upload + download). Lanza excepciones si falla.
  static Future<void> runSync({bool uploadOnly = false}) async {
    // 1) upload de cambios pendientes
    final cambios = await _collectPending();
    if (cambios.isNotEmpty) {
      final payload = _buildPayload(cambios);
      // marcar como 'syncing' localmente (opcional)
      // map ids por tabla y marcar
      final Map<String, List<int>> idsPorTabla = {};
      for (final c in cambios) {
        final tabla = c['tabla'] as String;
        final id = (c['fila'] as Map)['id'] as int;
        idsPorTabla.putIfAbsent(tabla, () => []).add(id);
      }
      // marcar como syncing
      for (final entry in idsPorTabla.entries) {
        await DBActividades.marcarComoSyncing(entry.key, entry.value);
      }

      // enviar
      final resp = await _uploadBatch(payload);
      // procesar resultados
      await _processUploadResults(resp);
      // actualizar lastSync si servidor devuelve timestamp
      final serverTs = resp['serverTimestamp'] as String?;
      if (serverTs != null) await _setLastSyncAt(serverTs);
    }

    if (!uploadOnly) {
      // 2) download cambios desde servidor
      final last = await _getLastSyncAt();
      final dl = await _downloadChanges(last);
      final changes = dl['changes'] as List? ?? [];
      if (changes.isNotEmpty) {
        await _applyDownloadedChanges(changes);
      }
      final serverTs = dl['serverTimestamp'] as String?;
      if (serverTs != null) await _setLastSyncAt(serverTs);
    }
  }
}
