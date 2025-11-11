import 'package:flutter/material.dart';
import 'database_actividades.dart';
import 'editar_actividad.dart';

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

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'Sin fecha';
    try {
      final date = DateTime.parse(fecha.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return fecha.toString();
    }
  }

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

  Future<void> _confirmarEliminar(Map<String, dynamic> actividad) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta actividad?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DBActividades.eliminarActividad(actividad['id'] as int);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Actividad eliminada')));
        cargarActividades(); // Recargar lista
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  Future<void> _editarActividad(Map<String, dynamic> actividad) async {
    final actualizado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarActividadPage(
          actividad: actividad,
          productorId: widget.productorId,
        ),
      ),
    );

    if (actualizado == true) {
      cargarActividades(); // Recargar lista
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Actividad actualizada')));
    }
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
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          '${actividad['actividad'] ?? 'Sin tipo'} - ${_formatearFecha(actividad['fecha'])}',
                        ),
                        subtitle: Text(
                          'Responsable: ${actividad['responsable']}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Info
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () => mostrarDetalles(actividad),
                            ),
                            // Editar
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editarActividad(actividad),
                            ),
                            // Eliminar
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmarEliminar(actividad),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
