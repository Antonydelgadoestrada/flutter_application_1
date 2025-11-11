import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio mínimo para solicitar a la Cloud Function que genere un reporte.
class ExportService {
  final String functionUrl;

  ExportService(this.functionUrl);

  /// Llama a la función (POST) y devuelve la URL del archivo generado.
  /// Requiere que el usuario esté autenticado con Firebase Auth; el ID token
  /// se envía en Authorization: Bearer <token>.
  Future<String> generateReport() async {
    final user = FirebaseAuth.instance.currentUser;
    String? idToken;
    if (user != null) {
      idToken = await user.getIdToken();
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    final resp = await http
        .post(Uri.parse(functionUrl), headers: headers)
        .timeout(const Duration(seconds: 120));

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = json.decode(resp.body) as Map<String, dynamic>;
      final url = body['url'] as String?;
      if (url != null) return url;
      throw Exception('La función no devolvió la URL del archivo');
    } else {
      throw Exception(
        'Error al generar reporte: ${resp.statusCode} ${resp.body}',
      );
    }
  }
}
