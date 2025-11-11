import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_productores.dart';

class EditarProductorPage extends StatefulWidget {
  final Map<String, dynamic> productor;

  const EditarProductorPage({super.key, required this.productor});

  @override
  State<EditarProductorPage> createState() => _EditarProductorPageState();
}

class _EditarProductorPageState extends State<EditarProductorPage> {
  final _formKey = GlobalKey<FormState>();

  // Controles que coinciden con `AddProductorPage`
  late TextEditingController nombreController;
  late TextEditingController codigoController;
  late TextEditingController areaTotalController;
  late TextEditingController areaController;
  List<String> cultivos = ['Maracuyá', 'Cacao', 'Café', 'Banano', 'Otro'];
  String? cultivoSeleccionado;
  late TextEditingController estimadoController;
  late TextEditingController densidadController;
  late TextEditingController anioController;
  late TextEditingController ubicacionController;
  late TextEditingController coordenadasController;
  late TextEditingController gnnController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.productor;
    nombreController = TextEditingController(
      text: (p['nombre'] ?? '').toString(),
    );
    codigoController = TextEditingController(
      text: (p['codigo'] ?? '').toString(),
    );
    areaTotalController = TextEditingController(
      text: (p['area_total'] ?? '').toString(),
    );
    areaController = TextEditingController(text: (p['area'] ?? '').toString());
    cultivoSeleccionado = (p['cultivo'] ?? p['cultivoSeleccionado'] ?? '')
        .toString();
    estimadoController = TextEditingController(
      text: (p['estimado_cosecha'] ?? '').toString(),
    );
    densidadController = TextEditingController(
      text: (p['densidad'] ?? '').toString(),
    );
    anioController = TextEditingController(
      text: (p['anio_siembra'] ?? p['anio'] ?? '').toString(),
    );
    ubicacionController = TextEditingController(
      text: (p['ubicacion'] ?? '').toString(),
    );
    coordenadasController = TextEditingController(
      text: (p['coordenadas'] ?? '').toString(),
    );
    gnnController = TextEditingController(text: (p['gnn'] ?? '').toString());
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final datosActualizados = {
        ...widget.productor,
        'nombre': nombreController.text.trim(),
        'codigo': codigoController.text.trim(),
        'area_total': areaTotalController.text.trim(),
        'area': areaController.text.trim(),
        'cultivo': cultivoSeleccionado ?? '',
        'estimado_cosecha': estimadoController.text.trim(),
        'densidad': densidadController.text.trim(),
        'anio_siembra': anioController.text.trim(),
        'ubicacion': ubicacionController.text.trim(),
        'coordenadas': coordenadasController.text.trim(),
        'gnn': gnnController.text.trim(),
      };

      await DBProductores.actualizarProductor(
        widget.productor['id'] as int,
        datosActualizados,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Productor actualizado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.green),
            onPressed: _isLoading ? null : _guardar,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'DATOS DEL PRODUCTOR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'El nombre es obligatorio';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: codigoController,
                      decoration: const InputDecoration(labelText: 'Código'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: areaTotalController,
                      decoration: const InputDecoration(
                        labelText: 'Área total (has)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\\d\\.,]')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: areaController,
                      decoration: const InputDecoration(
                        labelText: 'Área (has)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\\d\\.,]')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: cultivoSeleccionado == ''
                          ? null
                          : cultivoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Cultivo principal',
                      ),
                      items: cultivos
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => cultivoSeleccionado = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: densidadController,
                      decoration: const InputDecoration(
                        labelText: 'Densidad (plantas/ha)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\\d\\.,]')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: anioController,
                      decoration: const InputDecoration(
                        labelText: 'Año de siembra',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\\d]')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: ubicacionController,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación exacta',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: coordenadasController,
                      decoration: const InputDecoration(
                        labelText: 'Coordenadas (lat, long)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: gnnController,
                      decoration: const InputDecoration(labelText: 'GNN'),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: estimadoController,
                      decoration: const InputDecoration(
                        labelText: 'Estimado de cosecha',
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    codigoController.dispose();
    areaTotalController.dispose();
    areaController.dispose();
    estimadoController.dispose();
    densidadController.dispose();
    anioController.dispose();
    ubicacionController.dispose();
    coordenadasController.dispose();
    gnnController.dispose();
    super.dispose();
  }
}
