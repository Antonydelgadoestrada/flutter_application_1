import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'database_actividades.dart';
import 'database_productores.dart';

class NuevaActividadDiariaPage extends StatefulWidget {
  final String nombreProductor;
  const NuevaActividadDiariaPage({super.key, required this.nombreProductor});

  @override
  State<NuevaActividadDiariaPage> createState() =>
      _NuevaActividadDiariaPageState();
}

class _NuevaActividadDiariaPageState extends State<NuevaActividadDiariaPage> {
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController responsableController = TextEditingController();

  String? actividadSeleccionada;
  String? jornalesSeleccionados;

  final List<String> actividades = [
    'Riego',
    'Fertilización',
    'Siembra',
    'Cosecha',
    'Poda',
    // ...agrega más actividades
  ];

  final List<String> jornales = ['1', '2', '3', '4', '5'];

  Future<int?> obtenerProductorIdPorNombre(String nombre) async {
    final productores = await DBProductores.obtenerProductores();
    final productor = productores.firstWhere(
      (p) => p['nombre'] == nombre,
      orElse: () => {},
    );
    return productor.isNotEmpty ? productor['id'] as int : null;
  }

  Future<void> guardarActividad() async {
    final productorId = await obtenerProductorIdPorNombre(
      widget.nombreProductor,
    );
    if (productorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el productor en la base de datos.'),
        ),
      );
      return;
    }
    final nuevaActividad = {
      'productorId': productorId,
      'fecha': fechaController.text,
      'actividad': actividadSeleccionada ?? '',
      'responsable': widget.nombreProductor,
      'observaciones': cantidadController
          .text, // Puedes cambiar esto por un campo de observaciones si lo tienes
    };
    await DBActividades.agregarActividad(nuevaActividad);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Actividad guardada exitosamente')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Image.asset('assets/logo.png', height: 60),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'CUADERNO DE CAMPO',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'ACTIVIDADES DIARIAS',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: fechaController,
              decoration: InputDecoration(
                labelText: 'Fecha',
                hintText: 'escribe aquí...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      fechaController.text = picked.toIso8601String().substring(
                        0,
                        10,
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Actividad'),
              value: actividadSeleccionada,
              items: actividades
                  .map((act) => DropdownMenuItem(value: act, child: Text(act)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => actividadSeleccionada = value),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cantidadController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                hintText: 'escribe aquí...',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Jornales'),
              value: jornalesSeleccionados,
              items: jornales
                  .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => jornalesSeleccionados = value),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: responsableController..text = widget.nombreProductor,
              decoration: const InputDecoration(
                labelText: 'Responsable',
                hintText: 'escribe aquí...',
              ),
              readOnly: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: guardarActividad,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
