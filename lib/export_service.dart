import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'database_actividades.dart';
import 'database_productores.dart';

/// Servicio para generar Excel con datos del dispositivo y subirlo a Firebase Storage.
class ExportService {
  static Future<String> generarReporteCompleto() async {
    print('========== INICIANDO GENERACIÓN DE REPORTE ==========');

    try {
      // Leer datos
      print('Leyendo productores...');
      final productores = await DBProductores.obtenerProductores();
      print('Productores: ${productores.length}');

      print('Leyendo actividades...');
      final actividades = await DBActividades.obtenerTodasActividades();
      print('Actividades: ${actividades.length}');

      final riegos = await DBActividades.obtenerTodosRiegos();
      final fertilizaciones = await DBActividades.obtenerTodasFertilizaciones();
      final cosechas = await DBActividades.obtenerTodasCosechas();

      // Crear Excel
      print('Creando Excel...');
      final excel = Excel.createExcel();
      excel.delete(excel.getDefaultSheet()!);

      // Productores
      final sheetProd = excel['Productores'];
      sheetProd.appendRow([
        'ID',
        'Código',
        'Nombre',
        'Cultivo',
        'Área',
        'Ubicación',
      ]);
      for (final p in productores) {
        sheetProd.appendRow([
          p['id']?.toString() ?? '',
          p['codigo']?.toString() ?? '',
          p['nombre']?.toString() ?? '',
          p['cultivo']?.toString() ?? '',
          p['area']?.toString() ?? '',
          p['ubicacion']?.toString() ?? '',
        ]);
      }

      // Actividades
      final sheetAct = excel['Actividades'];
      sheetAct.appendRow([
        'ID',
        'Productor',
        'Fecha',
        'Actividad',
        'Responsable',
      ]);
      for (final a in actividades) {
        sheetAct.appendRow([
          a['id']?.toString() ?? '',
          a['productorId']?.toString() ?? '',
          a['fecha']?.toString() ?? '',
          a['actividad']?.toString() ?? '',
          a['responsable']?.toString() ?? '',
        ]);
      }

      // Riegos
      final sheetRiego = excel['Riegos'];
      sheetRiego.appendRow(['ID', 'Actividad', 'Cantidad Agua', 'Método']);
      for (final r in riegos) {
        sheetRiego.appendRow([
          r['id']?.toString() ?? '',
          r['actividadId']?.toString() ?? '',
          r['cantidad_agua']?.toString() ?? '',
          r['metodo']?.toString() ?? '',
        ]);
      }

      // Fertilizaciones
      final sheetFert = excel['Fertilizaciones'];
      sheetFert.appendRow(['ID', 'Actividad', 'Sector', 'Método']);
      for (final f in fertilizaciones) {
        sheetFert.appendRow([
          f['id']?.toString() ?? '',
          f['actividadId']?.toString() ?? '',
          f['sector']?.toString() ?? '',
          f['metodo_aplicacion']?.toString() ?? '',
        ]);
      }

      // Cosechas
      final sheetCos = excel['Cosechas'];
      sheetCos.appendRow(['ID', 'Actividad', 'Fecha', 'Tipo', 'Cantidad']);
      for (final c in cosechas) {
        sheetCos.appendRow([
          c['id']?.toString() ?? '',
          c['actividadId']?.toString() ?? '',
          c['fecha']?.toString() ?? '',
          c['tipo']?.toString() ?? '',
          c['cantidad']?.toString() ?? '',
        ]);
      }

      print('Excel creado con 5 hojas');

      // Guardar y subir
      print('Codificando Excel...');
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Excel encode retornó null');

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'reporte_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${dir.path}/$fileName');

      print('Guardando archivo: $fileName');
      await file.writeAsBytes(bytes, flush: true);

      print('Subiendo a Firebase Storage...');
      final ref = FirebaseStorage.instance.ref('reportes/$fileName');

      // Subir con metadatos explícitos para evitar NullPointerException
      await ref.putFile(
        file,
        SettableMetadata(
          contentType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          customMetadata: {'uploaded_at': DateTime.now().toIso8601String()},
        ),
      );
      print('Archivo subido exitosamente');
      final url = await ref.getDownloadURL();

      print('Limpiando archivos...');
      await file.delete();

      print('========== REPORTE COMPLETADO ==========');
      return url;
    } catch (e) {
      print('========== ERROR ==========');
      print('$e');
      rethrow;
    }
  }
}
