import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'database_productores.dart';
import 'database_actividades.dart';

class Reportes {
  // Genera PDF con todas las actividades y detalles por productor
  static Future<String> generarPdfReporte(
    int productorId,
    String nombreProductor,
  ) async {
    final actividades = await DBActividades.obtenerActividadesPorProductor(
      productorId,
    );

    // Preleer detalles de cada actividad
    final List<Map<String, dynamic>> actividadesConDetalles = [];
    for (final act in actividades) {
      final Map<String, dynamic> item = Map<String, dynamic>.from(act);
      final tipo = (act['actividad'] ?? '').toString();
      if (tipo == 'Riego') {
        item['detalle'] = await DBActividades.obtenerRiegoPorActividad(
          act['id'] as int,
        );
      } else if (tipo == 'Fertilización') {
        item['detalle'] = await DBActividades.obtenerFertilizacionPorActividad(
          act['id'] as int,
        );
      } else if (tipo == 'Cosecha') {
        item['detalle'] = await DBActividades.obtenerCosechaPorActividad(
          act['id'] as int,
        );
      } else {
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
            pw.Text('Fecha de generación: ${DateTime.now().toIso8601String()}'),
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
              widgets.add(pw.Text('Responsable: ${act['responsable'] ?? ''}'));
              widgets.add(pw.Text('Cantidad: ${act['cantidad'] ?? ''}'));
              widgets.add(pw.SizedBox(height: 6));
              widgets.add(
                pw.Text(
                  'Detalles:',
                  style: pw.TextStyle(decoration: pw.TextDecoration.underline),
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
                widgets.add(pw.Text('Operador: ${detalle['operador'] ?? ''}'));
              } else if (tipo == 'Cosecha' && detalle != null) {
                widgets.add(pw.Text('--- Detalle Cosecha ---'));
                widgets.add(
                  pw.Text('Fecha cosecha: ${detalle['fecha'] ?? ''}'),
                );
                widgets.add(pw.Text('Tipo: ${detalle['tipo'] ?? ''}'));
                widgets.add(pw.Text('Cantidad: ${detalle['cantidad'] ?? ''}'));
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
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/reporte_productor_$productorId.pdf');
    await file.writeAsBytes(bytes);
    return file.path; // devuelve ruta del archivo
  }

  // Genera Excel (XLSX) con actividades y detalles por productor
  static Future<String> generarExcelReporte(
    int productorId,
    String nombreProductor,
  ) async {
    final actividades = await DBActividades.obtenerActividadesPorProductor(
      productorId,
    );
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];

    // Encabezados
    sheet.appendRow([
      'Actividad',
      'Fecha',
      'Responsable',
      'Cantidad',
      'DetalleTipo',
      'Detalle1',
      'Detalle2',
      'Detalle3',
      'Detalle4',
    ]);

    for (final act in actividades) {
      final tipo = (act['actividad'] ?? '').toString();
      String d1 = '', d2 = '', d3 = '', d4 = '', detalleTipo = '';
      if (tipo == 'Riego') {
        final riego = await DBActividades.obtenerRiegoPorActividad(
          act['id'] as int,
        );
        detalleTipo = 'Riego';
        d1 = riego?['cantidad_agua']?.toString() ?? '';
        d2 = riego?['metodo']?.toString() ?? '';
        d3 = riego?['hora']?.toString() ?? '';
        d4 = riego?['observaciones']?.toString() ?? '';
      } else if (tipo == 'Fertilización') {
        final fert = await DBActividades.obtenerFertilizacionPorActividad(
          act['id'] as int,
        );
        detalleTipo = 'Fertilización';
        d1 = fert?['sector']?.toString() ?? '';
        d2 = fert?['cultivo_variedad']?.toString() ?? '';
        d3 = fert?['contenido_nutricional']?.toString() ?? '';
        d4 = fert?['metodo_aplicacion']?.toString() ?? '';
      } else if (tipo == 'Cosecha') {
        final cose = await DBActividades.obtenerCosechaPorActividad(
          act['id'] as int,
        );
        detalleTipo = 'Cosecha';
        d1 = cose?['tipo']?.toString() ?? '';
        d2 = cose?['cantidad']?.toString() ?? '';
        d3 = cose?['cliente']?.toString() ?? '';
        d4 = cose?['numero_liquidacion']?.toString() ?? '';
      }

      sheet.appendRow([
        tipo,
        act['fecha']?.toString() ?? '',
        act['responsable']?.toString() ?? '',
        act['cantidad']?.toString() ?? '',
        detalleTipo,
        d1,
        d2,
        d3,
        d4,
      ]);
    }

    final bytes = excel.encode();
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/reporte_productor_$productorId.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes!, flush: true);
    return file.path;
  }
}
