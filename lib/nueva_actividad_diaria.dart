import 'package:flutter/material.dart';
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
  final TextEditingController cantidadAguaController = TextEditingController();
  final TextEditingController metodoRiegoController = TextEditingController();
  final TextEditingController horaRiegoController = TextEditingController();
  final TextEditingController observacionesRiegoController =
      TextEditingController();
  final TextEditingController sectorController = TextEditingController();
  final TextEditingController cultivoVariedadController =
      TextEditingController();
  final TextEditingController contenidoNutricionalController =
      TextEditingController();
  final TextEditingController fechaAplicacionController =
      TextEditingController();
  final TextEditingController metodoAplicacionController =
      TextEditingController();
  final TextEditingController operadorController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController productorController = TextEditingController();
  final TextEditingController fechaCosechaController = TextEditingController();
  final TextEditingController tipoController = TextEditingController();
  final TextEditingController cantidadCosechaController =
      TextEditingController();
  final TextEditingController clienteController = TextEditingController();
  final TextEditingController numeroLiquidacionController =
      TextEditingController();

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
    try {
      // 1) validaciones básicas
      if (actividadSeleccionada == null || actividadSeleccionada!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione la actividad.')),
        );
        return;
      }
      if (fechaController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Seleccione la fecha.')));
        return;
      }

      // 2) obtener id del productor
      final productorId = await DBProductores.obtenerIdPorNombre(
        widget.nombreProductor,
      );
      if (productorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Productor no encontrado en la base de datos.'),
          ),
        );
        return;
      }

      // 3) guardar según tipo (envuelto en try/catch abajo)
      if (actividadSeleccionada == 'Riego') {
        await DBActividades.realizarActividadDeRiego(
          productorId: productorId,
          responsable: widget.nombreProductor,
          observaciones: '', // o recoge de un campo si existe
          cantidadAgua: cantidadAguaController.text,
          metodoRiego: metodoRiegoController.text,
          horaRiego: horaRiegoController.text,
          observacionesRiego: observacionesRiegoController.text,
        );
      } else if (actividadSeleccionada == 'Fertilización') {
        await DBActividades.realizarActividadDeFertilizacion(
          productorId: productorId,
          responsable: widget.nombreProductor,
          observaciones: '',
          sector: sectorController.text,
          cultivoVariedad: cultivoVariedadController.text,
          contenidoNutricional: contenidoNutricionalController.text,
          fechaAplicacion: fechaAplicacionController.text,
          metodoAplicacion: metodoAplicacionController.text,
          operador: operadorController.text,
          area: areaController.text,
          cantidad: cantidadController.text,
          codigo: codigoController.text,
          productor: productorController.text,
        );
      } else if (actividadSeleccionada == 'Cosecha') {
        await DBActividades.realizarActividadDeCosecha(
          productorId: productorId,
          responsable: widget.nombreProductor,
          observaciones: '',
          fecha: fechaCosechaController.text,
          tipo: tipoController.text,
          cantidad: cantidadCosechaController.text,
          cliente: clienteController.text,
          numeroLiquidacion: numeroLiquidacionController.text,
        );
      } else {
        // actividad genérica
        await DBActividades.agregarActividad({
          'productorId': productorId,
          'fecha': fechaController.text,
          'actividad': actividadSeleccionada ?? '',
          'responsable': widget.nombreProductor,
          'observaciones': '',
          'cantidad': cantidadController.text,
          'jornales': jornalesSeleccionados,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Actividad guardada exitosamente')),
      );
      Navigator.of(context).pop();
    } catch (e, st) {
      // imprimir error real en consola y notificar en UI
      debugPrint('Error guardando actividad: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}')),
      );
    }
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
              initialValue: actividadSeleccionada,
              items: [
                DropdownMenuItem(value: 'Riego', child: Text('Riego')),
                DropdownMenuItem(
                  value: 'Fertilización',
                  child: Text('Fertilización'),
                ),
                DropdownMenuItem(value: 'Siembra', child: Text('Siembra')),
                DropdownMenuItem(value: 'Cosecha', child: Text('Cosecha')),
                // ...otras actividades...
              ],
              onChanged: (value) {
                setState(() {
                  actividadSeleccionada = value;
                });
              },
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
              initialValue: jornalesSeleccionados,
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
            if (actividadSeleccionada == 'Riego') ...[
              const SizedBox(height: 10),
              TextField(
                controller: cantidadAguaController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de agua (L)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: metodoRiegoController,
                decoration: const InputDecoration(labelText: 'Método de riego'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: horaRiegoController,
                decoration: const InputDecoration(labelText: 'Hora de riego'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: observacionesRiegoController,
                decoration: const InputDecoration(labelText: 'Observaciones'),
              ),
            ],
            if (actividadSeleccionada == 'Fertilización') ...[
              TextField(
                controller: sectorController,
                decoration: const InputDecoration(labelText: 'Sector'),
              ),
              TextField(
                controller: cultivoVariedadController,
                decoration: const InputDecoration(
                  labelText: 'Cultivo y variedad',
                ),
              ),
              TextField(
                controller: contenidoNutricionalController,
                decoration: const InputDecoration(
                  labelText: 'Contenido nutricional',
                ),
              ),
              TextField(
                controller: fechaAplicacionController,
                decoration: InputDecoration(
                  labelText: 'Fecha de aplicación',
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
                        fechaAplicacionController.text = picked
                            .toIso8601String()
                            .substring(0, 10);
                      }
                    },
                  ),
                ),
              ),
              TextField(
                controller: metodoAplicacionController,
                decoration: const InputDecoration(
                  labelText: 'Método de aplicación',
                ),
              ),
              TextField(
                controller: operadorController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del operador',
                ),
              ),
              TextField(
                controller: areaController,
                decoration: const InputDecoration(labelText: 'Área (ha)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad (sacos/kg)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: codigoController,
                decoration: const InputDecoration(labelText: 'Código'),
              ),
              TextField(
                controller: productorController,
                decoration: const InputDecoration(labelText: 'Productor'),
              ),
            ],
            if (actividadSeleccionada == 'Cosecha') ...[
              TextField(
                controller: fechaCosechaController,
                decoration: InputDecoration(
                  labelText: 'Fecha',
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
                        fechaCosechaController.text = picked
                            .toIso8601String()
                            .substring(0, 10);
                      }
                    },
                  ),
                ),
              ),
              TextField(
                controller: tipoController,
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              TextField(
                controller: cantidadCosechaController,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: clienteController,
                decoration: const InputDecoration(labelText: 'Cliente'),
              ),
              TextField(
                controller: numeroLiquidacionController,
                decoration: const InputDecoration(
                  labelText: 'Nº de liquidación',
                ),
              ),
            ],
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
