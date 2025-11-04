import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';
import 'database_actividades.dart';

class FirestoreSyncManager {
  static final FirebaseFirestore _fire = FirebaseFirestore.instance;
  static const _lastSyncKey = 'last_sync_at';

  static const List<String> _collections = [
    'productores',
    'actividades',
    'riegos',
    'fertilizaciones',
    'cosechas',
  ];

  static Future<String?> _getLastSyncAt() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_lastSyncKey);
  }

  static Future<void> _setLastSyncAt(String ts) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_lastSyncKey, ts);
  }

  // Convierte Timestamp de Firestore a ISO string si es necesario (recursivo lo justo)
  static dynamic _normalizeValue(dynamic v) {
    if (v is Timestamp) return v.toDate().toUtc().toIso8601String();
    if (v is Map) {
      final out = <String, dynamic>{};
      v.forEach((k, val) => out[k] = _normalizeValue(val));
      return out;
    }
    if (v is List) return v.map(_normalizeValue).toList();
    return v;
  }

  // Subir cambios pendientes a Firestore
  static Future<Map<String, dynamic>> _uploadPending() async {
    final cambios = await DBActividades.obtenerCambiosPendientes(limit: 500);
    final List<Map<String, dynamic>> results = [];

    for (final c in cambios) {
      final tabla = c['tabla'] as String;
      final fila = Map<String, dynamic>.from(c['fila'] as Map);
      final idLocal = fila['id'] as int;
      final idRemoto = fila['id_remoto'] as String?;
      final status = (fila['sync_status'] ?? '').toString();
      final updatedAt =
          fila['updated_at'] as String? ??
          DateTime.now().toUtc().toIso8601String();

      try {
        final coll = _fire.collection(tabla);

        if (status == 'deleted') {
          if (idRemoto != null) {
            await coll.doc(idRemoto).delete();
            results.add({
              'table': tabla,
              'id_local': idLocal,
              'id_remoto': idRemoto,
              'status': 'ok',
            });
          } else {
            results.add({
              'table': tabla,
              'id_local': idLocal,
              'id_remoto': null,
              'status': 'ok',
            });
          }
        } else {
          // preparar datos para enviar (eliminar metadatos locales)
          final dataToSend = Map<String, dynamic>.from(fila)
            ..remove('id')
            ..remove('sync_status')
            ..remove('updated_at')
            ..remove('deleted_at');

          // normalizar tipos (por si hay Timestamp u otros)
          final normalized = <String, dynamic>{};
          dataToSend.forEach((k, v) {
            normalized[k] = _normalizeValue(v);
          });
          normalized['updated_at'] = updatedAt;

          if (idRemoto == null) {
            final docRef = await coll.add(normalized);
            final newId = docRef.id;
            results.add({
              'table': tabla,
              'id_local': idLocal,
              'id_remoto': newId,
              'status': 'ok',
            });
          } else {
            await coll.doc(idRemoto).set(normalized, SetOptions(merge: true));
            results.add({
              'table': tabla,
              'id_local': idLocal,
              'id_remoto': idRemoto,
              'status': 'ok',
            });
          }
        }
      } catch (e, st) {
        // registrar error para debug
        print('Firestore upload error table=$tabla idLocal=$idLocal err=$e');
        print(st);
        results.add({
          'table': tabla,
          'id_local': idLocal,
          'id_remoto': idRemoto,
          'status': 'error',
          'message': e.toString(),
        });
      }
    }

    return {
      'results': results,
      'serverTimestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // Descargar cambios desde Firestore (por colección)
  static Future<Map<String, dynamic>> _downloadChanges(String? since) async {
    final List<Map<String, dynamic>> changes = [];
    for (final collName in _collections) {
      try {
        Query query = _fire.collection(collName).orderBy('updated_at');
        if (since != null) {
          query = query.where('updated_at', isGreaterThan: since);
        }
        final snap = await query.get();
        for (final doc in snap.docs) {
          final rawObj = doc.data();
          // asegurar que tenemos un Map<String, dynamic>
          final Map<String, dynamic> raw = (rawObj is Map)
              ? Map<String, dynamic>.from(rawObj)
              : <String, dynamic>{};
          // normalizar updated_at y otros valores
          final data = <String, dynamic>{};
          raw.forEach((k, v) => data[k] = _normalizeValue(v));
          final deleted = data['deleted'] == true;
          changes.add({
            'table': collName,
            'id_remoto': doc.id,
            'data': data,
            'updated_at': data['updated_at'],
            'deleted': deleted,
          });
        }
      } catch (e) {
        // imprimir para depuración y continuar (colección puede no existir)
        print('Firestore download error collection=$collName err=$e');
      }
    }
    return {
      'changes': changes,
      'serverTimestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // Aplica cambios descargados directamente en SQLite (last-write-wins)
  static Future<void> _applyDownloadedChanges(List<dynamic> changes) async {
    final db = await DBHelper.database;
    for (final ch in changes) {
      final table = ch['table'] as String;
      final idRemoto = ch['id_remoto'] as String?;
      final data = Map<String, dynamic>.from(ch['data'] as Map? ?? {});
      final deleted = ch['deleted'] == true;
      final serverUpdatedAt = ch['updated_at'] as String?;

      if (idRemoto == null) continue;
      try {
        final rows = await db.query(
          table,
          where: 'id_remoto = ?',
          whereArgs: [idRemoto],
          limit: 1,
        );
        if (rows.isEmpty) {
          if (!deleted) {
            final insertData = {
              ...data,
              'id_remoto': idRemoto,
              'sync_status': 'synced',
              'updated_at':
                  serverUpdatedAt ?? DateTime.now().toUtc().toIso8601String(),
            };
            try {
              await db.insert(table, insertData);
            } catch (e) {
              print(
                'Insert local failed table=$table idRemoto=$idRemoto err=$e',
              );
            }
          }
        } else {
          final local = rows.first;
          final localUpdated = local['updated_at'] as String?;
          if (serverUpdatedAt != null &&
              (localUpdated == null ||
                  serverUpdatedAt.compareTo(localUpdated) >= 0)) {
            if (deleted) {
              try {
                await db.delete(
                  table,
                  where: 'id_remoto = ?',
                  whereArgs: [idRemoto],
                );
              } catch (e) {
                print(
                  'Delete local failed table=$table idRemoto=$idRemoto err=$e',
                );
              }
            } else {
              final payload = {
                ...data,
                'id_remoto': idRemoto,
                'sync_status': 'synced',
                'updated_at': serverUpdatedAt,
              };
              try {
                await db.update(
                  table,
                  payload,
                  where: 'id_remoto = ?',
                  whereArgs: [idRemoto],
                );
              } catch (e) {
                print(
                  'Update local failed table=$table idRemoto=$idRemoto err=$e',
                );
              }
            }
          }
        }
      } catch (e) {
        print(
          'Apply downloaded change failed table=$table idRemoto=$idRemoto err=$e',
        );
      }
    }
  }

  // Ejecutar sincronización completa (upload + download)
  static Future<void> runSync({bool uploadOnly = false}) async {
    try {
      // 1) upload
      final uploadResp = await _uploadPending();
      final results = uploadResp['results'] as List<dynamic>? ?? [];
      final Map<String, List<Map<String, dynamic>>> byTable = {};
      for (final r in results) {
        final t = r['table'] as String;
        byTable.putIfAbsent(t, () => []).add({
          'id_local': r['id_local'],
          'id_remoto': r['id_remoto'],
          'status': r['status'],
        });
      }
      for (final entry in byTable.entries) {
        await DBActividades.aplicarResultadoServidor(entry.key, entry.value);
      }
      final serverTsUpload = uploadResp['serverTimestamp'] as String?;
      if (serverTsUpload != null) await _setLastSyncAt(serverTsUpload);

      if (uploadOnly) return;

      // 2) download
      final last = await _getLastSyncAt();
      final dl = await _downloadChanges(last);
      final changes = dl['changes'] as List? ?? [];
      if (changes.isNotEmpty) {
        await _applyDownloadedChanges(changes);
      }
      final serverTsDownload = dl['serverTimestamp'] as String?;
      if (serverTsDownload != null) await _setLastSyncAt(serverTsDownload);
    } catch (e, st) {
      print('runSync failed: $e');
      print(st);
      rethrow;
    }
  }
}
