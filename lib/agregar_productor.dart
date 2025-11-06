import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_productores.dart';

class AddProductorPage extends StatefulWidget {
  const AddProductorPage({super.key});

  @override
  State<AddProductorPage> createState() => _AddProductorPageState();
}

class _AddProductorPageState extends State<AddProductorPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController areaTotalController = TextEditingController();
  final TextEditingController areaController = TextEditingController();

  // Nuevos campos
  final List<String> cultivos = ['Maracuyá', 'Cacao', 'Café', 'Banano', 'Otro'];
  String? cultivoSeleccionado;
  final TextEditingController estimadoController =
      TextEditingController(); // opcional
  final TextEditingController densidadController = TextEditingController();
  final TextEditingController anioController = TextEditingController();
  final TextEditingController ubicacionController = TextEditingController();
  final TextEditingController coordenadasController = TextEditingController();
  final TextEditingController gnnController = TextEditingController();

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

  String? _validarNombre(String? v) {
    if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
    final name = v.trim();
    final regex = RegExp(r"^[A-Za-zÁÉÍÓÚáéíóúÑñ\s]+$");
    if (!regex.hasMatch(name)) {
      return 'El nombre no puede contener números ni caracteres especiales';
    }
    return null;
  }

  String? _validarNoVacio(String? v, String campo) {
    if (v == null || v.trim().isEmpty) return 'El $campo es obligatorio';
    return null;
  }

  String? _validarNumero(String? v, String campo) {
    if (v == null || v.trim().isEmpty) return 'El $campo es obligatorio';
    final parsed = double.tryParse(v.replaceAll(',', '.'));
    if (parsed == null) return 'El $campo debe ser un número';
    return null;
  }

  Future<void> _saveProductor() async {
    if (!_formKey.currentState!.validate()) return;

    final nuevo = {
      'nombre': nombreController.text.trim(),
      'codigo': codigoController.text.trim(),
      'area_total': areaTotalController.text.trim(),
      'area': areaController.text.trim(),
      'cultivo': cultivoSeleccionado ?? '',
      // Campos adicionales que antes no se guardaban y causaban null en Firestore
      'estimado_cosecha': estimadoController.text.trim(),
      'densidad': densidadController.text.trim(),
      // En la base de datos la columna se llama `anio_siembra`
      'anio_siembra': anioController.text.trim(),
      'ubicacion': ubicacionController.text.trim(),
      'coordenadas': coordenadasController.text.trim(),
      'gnn': gnnController.text.trim(),
    };

    try {
      // Ajusta el nombre del método si tu servicio usa otro
      await DBProductores.agregarProductor(nuevo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Productor guardado correctamente')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error guardando productor: $e');
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                'CUADERNO DE CAMPO',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const Text(
                'DATOS DEL PRODUCTOR',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: _validarNombre,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: codigoController,
                decoration: const InputDecoration(labelText: 'Código'),
                validator: (v) => _validarNoVacio(v, 'código'),
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
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]')),
                ],
                validator: (v) => _validarNumero(v, 'área total'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: areaController,
                decoration: const InputDecoration(labelText: 'Área (has)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]')),
                ],
                validator: (v) => _validarNumero(v, 'área'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: cultivoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Cultivo principal',
                ),
                items: cultivos.map((String cultivo) {
                  return DropdownMenuItem<String>(
                    value: cultivo,
                    child: Text(cultivo),
                  );
                }).toList(),
                onChanged: (String? nuevoValor) {
                  setState(() {
                    cultivoSeleccionado = nuevoValor;
                  });
                },
                validator: (v) =>
                    v == null ? 'El cultivo es obligatorio' : null,
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
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]')),
                ],
                validator: (v) => _validarNumero(v, 'densidad'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: anioController,
                decoration: const InputDecoration(labelText: 'Año de siembra'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d]')),
                ],
                validator: (v) => _validarNumero(v, 'año'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ubicacionController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación exacta',
                ),
                validator: (v) => _validarNoVacio(v, 'ubicación'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: coordenadasController,
                decoration: const InputDecoration(
                  labelText: 'Coordenadas (lat, long)',
                ),
                validator: (v) => _validarNoVacio(v, 'coordenadas'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: gnnController,
                decoration: const InputDecoration(labelText: 'GNN'),
                validator: (v) => _validarNoVacio(v, 'GNN'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProductor,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Guardar'),
              ),
              const SizedBox(height: 20),
              const Text(
                'El campo no solo produce alimentos, también siembra vida y futuro.',
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
