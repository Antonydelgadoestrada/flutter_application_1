import 'package:flutter/material.dart';
import 'database_productores.dart';
import 'reportes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    _load();
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
    final path = await Reportes.generarPdfReporte(
      productorId!,
      productorNombre ?? '',
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF guardado en: $path')));
    // intentar abrir el archivo (opcional)
    if (await File(path).exists()) {
      await launchUrl(Uri.file(path));
    }
  }

  Future<void> _exportExcel() async {
    if (productorId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione un productor')));
      return;
    }
    final path = await Reportes.generarExcelReporte(
      productorId!,
      productorNombre ?? '',
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Excel guardado en: $path')));
    if (await File(path).exists()) {
      await launchUrl(Uri.file(path));
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
                ],
              ),
            ),
    );
  }
}
