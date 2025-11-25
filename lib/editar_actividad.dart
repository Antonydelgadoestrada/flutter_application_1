import 'package:flutter/material.dart';
import 'database_actividades.dart';

class EditarActividadPage extends StatefulWidget {
  final Map<String, dynamic> actividad;
  final int productorId;

  const EditarActividadPage({
    super.key,
    required this.actividad,
    required this.productorId,
  });

  @override
  State<EditarActividadPage> createState() => _EditarActividadPageState();
}

class _EditarActividadPageState extends State<EditarActividadPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _observacionesController;
  late TextEditingController _responsableController;
  late DateTime _fecha;
  String? _actividad;
  int? _idActividad;
  Map<String, dynamic>? _detalles;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _idActividad = widget.actividad['id'] as int?;
    _observacionesController = TextEditingController(
      text: widget.actividad['observaciones'] as String?,
    );
    _responsableController = TextEditingController(
      text: widget.actividad['responsable'] as String?,
    );
    try {
      _fecha = DateTime.parse(widget.actividad['fecha'] as String);
    } catch (e) {
      _fecha = DateTime.now(); // fallback a fecha actual si hay error de parseo
    }
    _actividad = widget.actividad['actividad'] as String?;
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    setState(() => _isLoading = true);
    try {
      if (_actividad == 'Riego') {
        _detalles = await DBActividades.obtenerRiegoPorActividad(
          widget.actividad['id'] as int,
        );
      } else if (_actividad == 'Fertilización') {
        _detalles = await DBActividades.obtenerFertilizacionPorActividad(
          widget.actividad['id'] as int,
        );
      } else if (_actividad == 'Cosecha') {
        _detalles = await DBActividades.obtenerCosechaPorActividad(
          widget.actividad['id'] as int,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Actualizar actividad principal (solo campos editables)
      final datosActividad = {
        ...widget.actividad,
        'fecha': _fecha.toIso8601String(),
        'responsable': _responsableController.text.trim(),
        'observaciones': _observacionesController.text.trim(),
      };

      await DBActividades.actualizarActividad(_idActividad!, datosActividad);

      // Actualizar detalles específicos si existen
      if (_detalles != null) {
        if (_actividad == 'Riego') {
          await DBActividades.actualizarRiego(_idActividad!, _detalles!);
        } else if (_actividad == 'Fertilización') {
          await DBActividades.actualizarFertilizacion(
            _idActividad!,
            _detalles!,
          );
        } else if (_actividad == 'Cosecha') {
          await DBActividades.actualizarCosecha(_idActividad!, _detalles!);
        }
        // Recargar detalles desde la BD para asegurar que reflejamos cambios
        await _cargarDetalles();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detalles actualizados: ${_detalles ?? {}}')),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true); // true indica que se actualizó
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Actividad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _guardar,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nota: el ID interno no se muestra ni se edita en este formulario.

                    // Tipo de actividad (no editable)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tipo de Actividad',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _actividad ?? 'N/A',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Fecha (editable)
                    ListTile(
                      title: const Text('Fecha'),
                      subtitle: Text(
                        '${_fecha.day}/${_fecha.month}/${_fecha.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: _fecha,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now(),
                        );
                        if (fecha != null) {
                          setState(() => _fecha = fecha);
                        }
                      },
                    ),
                    const Divider(),

                    // Responsable (editable)
                    TextFormField(
                      controller: _responsableController,
                      decoration: const InputDecoration(
                        labelText: 'Responsable',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese el responsable';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Observaciones (editable)
                    TextFormField(
                      controller: _observacionesController,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese observaciones';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Detalles específicos según el tipo de actividad (editables)
                    if (_detalles != null) ...[
                      const Divider(),
                      Text(
                        'Detalles específicos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      // Excluir campos metadata/relacionales que no deben editarse aquí
                      ..._detalles!.entries
                          .where(
                            (e) => !{
                              'id',
                              'actividadId',
                              'id_remoto',
                              'sync_status',
                              'updated_at',
                              'deleted_at',
                            }.contains(e.key),
                          )
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: TextFormField(
                                initialValue: e.value?.toString() ?? '',
                                decoration: InputDecoration(
                                  labelText: e.key,
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _detalles![e.key] = value;
                                  });
                                },
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _responsableController.dispose();
    super.dispose();
  }
}
