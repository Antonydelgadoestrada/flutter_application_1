import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'database_actividades.dart';
import 'package:flutter/foundation.dart';

class Reportes {
  // Obtiene la ruta de la carpeta Descargas del dispositivo
  static Future<String> _obtenerRutaDescargas() async {
    try {
      if (Platform.isAndroid) {
        // Intenta primero con getExternalStorageDirectory()
        try {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            debugPrint('✅ Usando getExternalStorageDirectory: ${extDir.path}');
            return extDir.path;
          }
        } catch (e) {
          debugPrint('⚠️ getExternalStorageDirectory falló: $e');
        }

        // Intenta ruta conocida de Descargas
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          debugPrint('✅ Usando ruta directa: ${downloadDir.path}');
          return downloadDir.path;
        }

        // Fallback: usar documentos de la app
        final appDir = await getApplicationDocumentsDirectory();
        debugPrint('⚠️ Usando documentos de app: ${appDir.path}');
        return appDir.path;
      } else if (Platform.isIOS) {
        final iosDir = await getApplicationDocumentsDirectory();
        debugPrint('✅ iOS - usando documentos de app: ${iosDir.path}');
        return iosDir.path;
      }

      final fallbackDir = await getApplicationDocumentsDirectory();
      debugPrint(
        '⚠️ Plataforma desconocida, usando fallback: ${fallbackDir.path}',
      );
      return fallbackDir.path;
    } catch (e) {
      debugPrint('❌ Error obteniendo ruta: $e');
      final fallback = await getApplicationDocumentsDirectory();
      return fallback.path;
    }
  }

  // Genera PDF con todas las actividades y detalles por productor
  static Future<String> generarPdfReporte(
    int productorId,
    String nombreProductor,
  ) async {
    try {
      debugPrint('🔍 Obteniendo actividades para productor: $productorId');
      final actividades = await DBActividades.obtenerActividadesPorProductor(
        productorId,
      );
      debugPrint('📊 ${actividades.length} actividades encontradas');

      // Preleer detalles de cada actividad
      final List<Map<String, dynamic>> actividadesConDetalles = [];
      for (final act in actividades) {
        final Map<String, dynamic> item = Map<String, dynamic>.from(act);
        final tipo = (act['actividad'] ?? '').toString();
        try {
          if (tipo == 'Riego') {
            item['detalle'] = await DBActividades.obtenerRiegoPorActividad(
              act['id'] as int,
            );
          } else if (tipo == 'Fertilización') {
            item['detalle'] =
                await DBActividades.obtenerFertilizacionPorActividad(
                  act['id'] as int,
                );
          } else if (tipo == 'Cosecha') {
            item['detalle'] = await DBActividades.obtenerCosechaPorActividad(
              act['id'] as int,
            );
          } else {
            item['detalle'] = null;
          }
        } catch (e) {
          debugPrint('⚠️ Error obteniendo detalles de actividad: $e');
          item['detalle'] = null;
        }
        actividadesConDetalles.add(item);
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          build: (context) {
            final List<pw.Widget> widgets = [];
            widgets.add(
              pw.Header(
                level: 0,
                child: pw.Text('Reporte de Actividades - $nombreProductor'),
              ),
            );
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(
              pw.Text(
                'Fecha de generación: ${DateTime.now().toIso8601String()}',
              ),
            );
            widgets.add(pw.SizedBox(height: 12));

            if (actividadesConDetalles.isEmpty) {
              widgets.add(pw.Text('No hay actividades registradas.'));
            } else {
              for (final act in actividadesConDetalles) {
                final detalle = act['detalle'] as Map<String, dynamic>?;
                widgets.add(pw.Divider());
                widgets.add(
                  pw.Text(
                    'Actividad: ${act['actividad'] ?? ''}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                );
                widgets.add(pw.Text('Fecha: ${act['fecha'] ?? ''}'));
                widgets.add(
                  pw.Text('Responsable: ${act['responsable'] ?? ''}'),
                );
                widgets.add(pw.Text('Cantidad: ${act['cantidad'] ?? ''}'));
                widgets.add(pw.SizedBox(height: 6));
                widgets.add(
                  pw.Text(
                    'Detalles:',
                    style: pw.TextStyle(
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                );

                final tipo = (act['actividad'] ?? '').toString();
                if (tipo == 'Riego' && detalle != null) {
                  widgets.add(pw.Text('--- Detalle Riego ---'));
                  widgets.add(
                    pw.Text('Cantidad agua: ${detalle['cantidad_agua'] ?? ''}'),
                  );
                  widgets.add(pw.Text('Método: ${detalle['metodo'] ?? ''}'));
                  widgets.add(pw.Text('Hora: ${detalle['hora'] ?? ''}'));
                  widgets.add(
                    pw.Text('Observaciones: ${detalle['observaciones'] ?? ''}'),
                  );
                } else if (tipo == 'Fertilización' && detalle != null) {
                  widgets.add(pw.Text('--- Detalle Fertilización ---'));
                  widgets.add(pw.Text('Sector: ${detalle['sector'] ?? ''}'));
                  widgets.add(
                    pw.Text(
                      'Cultivo/Variedad: ${detalle['cultivo_variedad'] ?? ''}',
                    ),
                  );
                  widgets.add(
                    pw.Text(
                      'Contenido nutricional: ${detalle['contenido_nutricional'] ?? ''}',
                    ),
                  );
                  widgets.add(
                    pw.Text('Método: ${detalle['metodo_aplicacion'] ?? ''}'),
                  );
                  widgets.add(
                    pw.Text('Operador: ${detalle['operador'] ?? ''}'),
                  );
                } else if (tipo == 'Cosecha' && detalle != null) {
                  widgets.add(pw.Text('--- Detalle Cosecha ---'));
                  widgets.add(
                    pw.Text('Fecha cosecha: ${detalle['fecha'] ?? ''}'),
                  );
                  widgets.add(pw.Text('Tipo: ${detalle['tipo'] ?? ''}'));
                  widgets.add(
                    pw.Text('Cantidad: ${detalle['cantidad'] ?? ''}'),
                  );
                  widgets.add(pw.Text('Cliente: ${detalle['cliente'] ?? ''}'));
                  widgets.add(
                    pw.Text(
                      'Nº liquidación: ${detalle['numero_liquidacion'] ?? ''}',
                    ),
                  );
                }
                widgets.add(pw.SizedBox(height: 8));
              }
            }
            return widgets;
          },
        ),
      );

      final bytes = await pdf.save();
      final dir = await _obtenerRutaDescargas();
      final nombreArchivo =
          'reporte_${nombreProductor}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('$dir/$nombreArchivo');

      try {
        await file.writeAsBytes(bytes);
        debugPrint('✅ PDF guardado en: ${file.path}');
        return file.path;
      } catch (e) {
        debugPrint('❌ Error escribiendo PDF: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ Error generando PDF: $e');
      rethrow;
    }
  }

  // Genera Excel (XLSX) con actividades y detalles por productor
  static Future<String> generarExcelReporte(
    int productorId,
    String nombreProductor,
  ) async {
    try {
      debugPrint(
        '🔍 Obteniendo actividades para Excel - productor: $productorId',
      );
      final actividades = await DBActividades.obtenerActividadesPorProductor(
        productorId,
      );
      debugPrint('📊 ${actividades.length} actividades encontradas');
      final excel = Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet()!];

      // Encabezados principales
      sheet.appendRow([
        'Actividad',
        'Fecha',
        'Responsable',
        'Cantidad',
        'Tipo Detalle',
        'Campo 1',
        'Campo 2',
        'Campo 3',
        'Campo 4',
      ]);

      for (final act in actividades) {
        final tipo = (act['actividad'] ?? '').toString();
        String d1Label = '', d2Label = '', d3Label = '', d4Label = '';
        String d1 = '', d2 = '', d3 = '', d4 = '', detalleTipo = '';

        try {
          if (tipo == 'Riego') {
            final riego = await DBActividades.obtenerRiegoPorActividad(
              act['id'] as int,
            );
            detalleTipo = 'Riego';
            d1Label = 'Cantidad Agua';
            d2Label = 'Método';
            d3Label = 'Hora';
            d4Label = 'Observaciones';
            d1 = riego?['cantidad_agua']?.toString() ?? '';
            d2 = riego?['metodo']?.toString() ?? '';
            d3 = riego?['hora']?.toString() ?? '';
            d4 = riego?['observaciones']?.toString() ?? '';
          } else if (tipo == 'Fertilización') {
            final fert = await DBActividades.obtenerFertilizacionPorActividad(
              act['id'] as int,
            );
            detalleTipo = 'Fertilización';
            d1Label = 'Sector';
            d2Label = 'Cultivo/Variedad';
            d3Label = 'Contenido Nutricional';
            d4Label = 'Método Aplicación';
            d1 = fert?['sector']?.toString() ?? '';
            d2 = fert?['cultivo_variedad']?.toString() ?? '';
            d3 = fert?['contenido_nutricional']?.toString() ?? '';
            d4 = fert?['metodo_aplicacion']?.toString() ?? '';
          } else if (tipo == 'Cosecha') {
            final cose = await DBActividades.obtenerCosechaPorActividad(
              act['id'] as int,
            );
            detalleTipo = 'Cosecha';
            d1Label = 'Tipo';
            d2Label = 'Cantidad';
            d3Label = 'Cliente';
            d4Label = 'Nº Liquidación';
            d1 = cose?['tipo']?.toString() ?? '';
            d2 = cose?['cantidad']?.toString() ?? '';
            d3 = cose?['cliente']?.toString() ?? '';
            d4 = cose?['numero_liquidacion']?.toString() ?? '';
          }
        } catch (e) {
          debugPrint('⚠️ Error obteniendo detalles: $e');
        }

        // Crear fila con información
        final rowData = <dynamic>[
          tipo,
          act['fecha']?.toString() ?? '',
          act['responsable']?.toString() ?? '',
          act['cantidad']?.toString() ?? '',
          detalleTipo,
        ];

        // Agregar datos específicos según el tipo
        if (d1.isNotEmpty || d1Label.isNotEmpty) {
          rowData.add('$d1Label: $d1');
        } else {
          rowData.add('');
        }
        if (d2.isNotEmpty || d2Label.isNotEmpty) {
          rowData.add('$d2Label: $d2');
        } else {
          rowData.add('');
        }
        if (d3.isNotEmpty || d3Label.isNotEmpty) {
          rowData.add('$d3Label: $d3');
        } else {
          rowData.add('');
        }
        if (d4.isNotEmpty || d4Label.isNotEmpty) {
          rowData.add('$d4Label: $d4');
        } else {
          rowData.add('');
        }

        sheet.appendRow(rowData);
      }

      final bytes = excel.encode();
      final dir = await _obtenerRutaDescargas();
      final nombreArchivo =
          'reporte_${nombreProductor}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final path = '$dir/$nombreArchivo';
      final file = File(path);

      try {
        if (bytes == null) {
          throw Exception('No se pudo codificar el Excel');
        }
        await file.writeAsBytes(bytes, flush: true);
        debugPrint('✅ Excel guardado en: $path');
        return file.path;
      } catch (e) {
        debugPrint('❌ Error escribiendo Excel: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ Error generando Excel: $e');
      rethrow;
    }
  }
}
