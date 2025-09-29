import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'database_productores.dart';

class AddProductorPage extends StatefulWidget {
  const AddProductorPage({super.key});

  @override
  State<AddProductorPage> createState() => _AddProductorPageState();
}

class _AddProductorPageState extends State<AddProductorPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController areaTotalController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController estimadoController = TextEditingController();
  final TextEditingController densidadController = TextEditingController();
  final TextEditingController anioController = TextEditingController();
  final TextEditingController ubicacionController = TextEditingController();
  final TextEditingController coordenadasController = TextEditingController();
  final TextEditingController gnnController = TextEditingController();

  String? cultivoSeleccionado;

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
            TextField(
              controller: nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre',
                hintText: 'escribe aquí...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () {
                    // Acción para reconocimiento de voz
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: codigoController,
              decoration: InputDecoration(
                labelText: 'Código',
                hintText: 'escribe aquí...',
                suffixIcon: DropdownButton<String>(
                  value: null,
                  items: [],
                  onChanged: null,
                  icon: const Icon(Icons.arrow_drop_down),
                  underline: Container(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: areaTotalController,
                    decoration: const InputDecoration(
                      labelText: 'Área total (has)',
                      hintText: 'escribe aquí...',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: areaController,
                    decoration: const InputDecoration(
                      labelText: 'Área (has)',
                      hintText: 'escribe aquí...',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Cultivo',
                hintText: 'Selecciona cultivo',
              ),
              value: cultivoSeleccionado,
              items: const [
                DropdownMenuItem(value: 'Maracuyá', child: Text('Maracuyá')),
                DropdownMenuItem(value: 'Mango', child: Text('Mango')),
              ],
              onChanged: (value) {
                setState(() {
                  cultivoSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: estimadoController,
                    decoration: const InputDecoration(
                      labelText: 'Estimado de cosecha',
                      hintText: 'escribe aquí...',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: densidadController,
                    decoration: const InputDecoration(
                      labelText: 'Densidad',
                      hintText: 'escribe aquí...',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: anioController,
              decoration: const InputDecoration(
                labelText: 'Año de siembra',
                hintText: 'escribe aquí...',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ubicacionController,
              decoration: InputDecoration(
                labelText: 'Ubicación',
                hintText: 'escribe aquí...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: () {
                    // Acción para obtener ubicación
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: coordenadasController,
              decoration: InputDecoration(
                labelText: 'Coordenadas',
                hintText: 'escribe aquí...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: () {
                    // Acción para obtener coordenadas
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: gnnController,
              decoration: InputDecoration(
                labelText: 'GNN',
                hintText: 'escribe aquí...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Acción para buscar GNN
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final nuevoProductor = {
                  "nombre": nombreController.text,
                  "cultivo": cultivoSeleccionado,
                  "ubicacion": ubicacionController.text,
                  "telefono": "", // Puedes agregar más campos si lo deseas
                  "correo": "",
                };
                await DBProductores.agregarProductor(nuevoProductor);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Productor guardado exitosamente'),
                  ),
                );
                Navigator.of(context).pop();
              },
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
    );
  }
}
