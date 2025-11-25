import 'package:flutter/material.dart';
import 'database_productores.dart';
import 'reportes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'export_service.dart';
import 'connectivity_service.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  List<Map<String, dynamic>> productores = [];
  int? productorId;
  String? productorNombre;
  bool cargando = true;
  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _connectivityService.addListener(_onConnectivityChanged);
    _load();
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    _connectivityService.dispose();
    super.dispose();
  }

  void _onConnectivityChanged() {
    setState(() {});
  }

  Future<void> _load() async {
    final list = await DBProductores.obtenerProductores();
    setState(() {
      productores = list;
      cargando = false;
    });
  }

  Future<void> _exportPdf() async {
    if (productorId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione un productor')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('📄 Generando PDF...')));

    try {
      final path = await Reportes.generarPdfReporte(
        productorId!,
        productorNombre ?? '',
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ PDF descargado en Descargas'),
          action: SnackBarAction(
            label: 'Abrir',
            onPressed: () async {
              if (await File(path).exists()) {
                await launchUrl(Uri.file(path));
              }
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  Future<void> _exportExcel() async {
    if (productorId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione un productor')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('📊 Generando Excel...')));

    try {
      final path = await Reportes.generarExcelReporte(
        productorId!,
        productorNombre ?? '',
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Excel descargado en Descargas'),
          action: SnackBarAction(
            label: 'Abrir',
            onPressed: () async {
              if (await File(path).exists()) {
                await launchUrl(Uri.file(path));
              }
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      debugPrint('Error en _exportExcel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString().substring(0, 80)}'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _exportServidor() async {
    if (!_connectivityService.hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ No hay conexión a internet. Esta función requiere conexión.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('☁️ Generando reporte en servidor...')),
    );
    try {
      final url = await ExportService.generarReporteCompleto();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '✅ Reporte guardado en Descargas y Firebase Storage.',
          ),
          action: SnackBarAction(
            label: 'Descargar',
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generar reportes')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Seleccione productor',
                    ),
                    items: productores.map((p) {
                      return DropdownMenuItem<int>(
                        value: p['id'] as int,
                        child: Text(p['nombre'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (v) {
                      final sel = productores.firstWhere((e) => e['id'] == v);
                      setState(() {
                        productorId = v;
                        productorNombre = sel['nombre'] ?? '';
                      });
                    },
                    initialValue: productorId,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Exportar PDF'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _exportExcel,
                    icon: const Icon(Icons.grid_on),
                    label: const Text('Exportar Excel'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _connectivityService.hasInternet
                        ? _exportServidor
                        : null,
                    icon: Icon(
                      _connectivityService.hasInternet
                          ? Icons.cloud_upload
                          : Icons.cloud_off,
                    ),
                    label: Text(
                      _connectivityService.hasInternet
                          ? 'Generar reporte en servidor'
                          : 'Sin conexión (reporte en servidor)',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
