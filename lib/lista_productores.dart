import 'package:flutter/material.dart';
import 'agregar_productor.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'database_productores.dart';

class SelectProductorPage extends StatefulWidget {
  const SelectProductorPage({super.key, required List<String> productores});

  @override
  State<SelectProductorPage> createState() => _SelectProductorPageState();
}

class _SelectProductorPageState extends State<SelectProductorPage> {
  List<Map<String, dynamic>> productores = [];
  bool cargando = true;
  String filtro = '';

  @override
  void initState() {
    super.initState();
    cargarProductores();
  }

  Future<void> cargarProductores() async {
    List<Map<String, dynamic>> lista = await DBProductores.obtenerProductores();
    setState(() {
      productores = lista;
      cargando = false;
    });
  }

  void _seleccionarProductor(Map<String, dynamic> productor) {
    Navigator.of(context).pop(productor['nombre']);
  }

  @override
  Widget build(BuildContext context) {
    final listaFiltrada = filtro.isEmpty
        ? productores
        : productores
              .where(
                (p) => (p['nombre'] ?? '').toLowerCase().contains(
                  filtro.toLowerCase(),
                ),
              )
              .toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Cuaderno de campo',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'ANTES DE EMPEZAR SELECCIONE EL PRODUCTOR A INSPECCIONAR',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar productor...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        filtro = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: listaFiltrada.isEmpty
                        ? const Center(
                            child: Text('No hay productores registrados'),
                          )
                        : ListView.builder(
                            itemCount: listaFiltrada.length,
                            itemBuilder: (context, index) {
                              final productor = listaFiltrada[index];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.person,
                                    color: Colors.green,
                                  ),
                                  title: Text(productor['nombre'] ?? ''),
                                  subtitle: Text(
                                    'Cultivo: ${productor['cultivo'] ?? ''}',
                                  ),
                                  onTap: () => _seleccionarProductor(productor),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'Eliminar productor',
                                          ),
                                          content: const Text(
                                            '¿Estás seguro de que deseas eliminar este productor?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              child: const Text(
                                                'Eliminar',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await DBProductores.eliminarProductor(
                                          productor['id'],
                                        );
                                        cargarProductores();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Productor eliminado',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductorPage(),
                        ),
                      );
                      cargarProductores(); // Recargar lista al volver
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Añadir productor'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'En cada cultivo hay una historia de trabajo, esperanza y vida.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
    );
  }
}
