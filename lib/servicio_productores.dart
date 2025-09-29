import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<List<Map<String, dynamic>>> cargarProductores() async {
  final String jsonString = await rootBundle.loadString('assets/productores.json');
  final List<dynamic> jsonData = json.decode(jsonString);
  return jsonData.cast<Map<String, dynamic>>();
}

Future<void> guardarProductor(Map<String, dynamic> nuevoProductor) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/productores.json';

  List<Map<String, dynamic>> productores = [];
  if (await File(path).exists()) {
    final contenido = await File(path).readAsString();
    productores = List<Map<String, dynamic>>.from(json.decode(contenido));
  } else {
    // Si el archivo no existe, carga el de assets como base
    productores = await cargarProductores();
  }

  productores.add(nuevoProductor);
  await File(path).writeAsString(json.encode(productores));
}