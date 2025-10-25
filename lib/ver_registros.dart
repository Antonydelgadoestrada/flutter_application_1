import 'package:flutter/material.dart';
import 'database_actividades.dart';

class VerRegistrosPage extends StatefulWidget {
  final int
  productorId; // Pasa el id del productor seleccionado si quieres filtrar por productor
  const VerRegistrosPage({
    super.key,
    required this.productorId,
    String? nombreProductor,
  });

  @override
  State<VerRegistrosPage> createState() => _VerRegistrosPageState();
}

class _VerRegistrosPageState extends State<VerRegistrosPage> {
  List<Map<String, dynamic>> actividades = [];

  @override
  void initState() {
    super.initState();
    cargarActividades();
  }

  Future<void> cargarActividades() async {
    final data = await DBActividades.obtenerActividadesPorProductor(
      widget.productorId,
    );
    setState(() {
      actividades = data;
    });
  }

  void mostrarDetalles(Map<String, dynamic> actividad) async {
    if (actividad['actividad'] == 'Riego') {
      final riego = await DBActividades.obtenerRiegoPorActividad(
        actividad['id'],
      );
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Detalle de Riego'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cantidad de agua: ${riego?['cantidad_agua'] ?? ''}'),
              Text('Método: ${riego?['metodo'] ?? ''}'),
              Text('Hora: ${riego?['hora'] ?? ''}'),
              Text('Observaciones: ${riego?['observaciones'] ?? ''}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } else if (actividad['actividad'] == 'Fertilización') {
      final fert = await DBActividades.obtenerFertilizacionPorActividad(
        actividad['id'],
      );
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Detalle de Fertilización'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sector: ${fert?['sector'] ?? ''}'),
                Text('Cultivo y variedad: ${fert?['cultivo_variedad'] ?? ''}'),
                Text(
                  'Contenido nutricional: ${fert?['contenido_nutricional'] ?? ''}',
                ),
                Text('Fecha de aplicación: ${fert?['fecha_aplicacion'] ?? ''}'),
                Text(
                  'Método de aplicación: ${fert?['metodo_aplicacion'] ?? ''}',
                ),
                Text('Operador: ${fert?['operador'] ?? ''}'),
                Text('Área: ${fert?['area'] ?? ''}'),
                Text('Cantidad: ${fert?['cantidad'] ?? ''}'),
                Text('Código: ${fert?['codigo'] ?? ''}'),
                Text('Productor: ${fert?['productor'] ?? ''}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } else if (actividad['actividad'] == 'Cosecha') {
      final cosecha = await DBActividades.obtenerCosechaPorActividad(
        actividad['id'],
      );
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Detalle de Cosecha'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fecha: ${cosecha?['fecha'] ?? ''}'),
                Text('Tipo: ${cosecha?['tipo'] ?? ''}'),
                Text('Cantidad: ${cosecha?['cantidad'] ?? ''}'),
                Text('Cliente: ${cosecha?['cliente'] ?? ''}'),
                Text(
                  'Nº de liquidación: ${cosecha?['numero_liquidacion'] ?? ''}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registros de Actividades')),
      body: actividades.isEmpty
          ? const Center(child: Text('No hay actividades registradas.'))
          : ListView.builder(
              itemCount: actividades.length,
              itemBuilder: (context, index) {
                final actividad = actividades[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      '${actividad['actividad']} - ${actividad['fecha']}',
                    ),
                    subtitle: Text('Responsable: ${actividad['responsable']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => mostrarDetalles(actividad),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
