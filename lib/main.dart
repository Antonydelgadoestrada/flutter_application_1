import 'package:flutter/material.dart';
import 'home_page.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'database_usuarios.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  Future<List<Map<String, dynamic>>> cargarUsuariosDesdeJson() async {
    final String jsonString = await rootBundle.loadString(
      'assets/usuarios.json',
    );
    final List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.cast<Map<String, dynamic>>();
  }

  Future<bool> validarUsuarioJson(String usuario, String password) async {
    final String jsonString = await rootBundle.loadString(
      'assets/usuarios.json',
    );
    final List<dynamic> usuarios = json.decode(jsonString);
    return usuarios.any(
      (u) => u['usuario'] == usuario && u['password'] == password,
    );
  }

  Future<Map<String, dynamic>?> obtenerDatosUsuarioJson(String usuario) async {
    final usuarios = await cargarUsuariosDesdeJson();
    try {
      return usuarios.firstWhere((u) => u['usuario'] == usuario);
    } catch (e) {
      return null;
    }
  }

  Future<bool> validarUsuarioSQLite(String usuario, String password) async {
    return await DBHelper.validarUsuario(usuario, password);
  }

  Future<void> _login() async {
    final usuario = userController.text.trim();
    final password = passController.text.trim();
    final valido = await validarUsuarioSQLite(usuario, password);
    if (valido) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(usuarioLogueado: usuario)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario o contraseña incorrectos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment
                        .centerRight, // O usa Alignment(0.6, 0.0) para un poco a la derecha
                    child: Image.asset(
                      'assets/logo.png',
                      height: 250,
                      width: 310555,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: userController,
                    decoration: InputDecoration(
                      labelText: 'Usuario',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Comunicate con soporte, para que te ayuden a recuperar tu contraseña',
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      '¿Olvidaste tu contraseña? Recuperar contraseña',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      bool valido = await validarUsuarioJson(
                        userController.text,
                        passController.text,
                      );
                      if (valido) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HomePage(usuarioLogueado: userController.text),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Usuario o contraseña incorrectos'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 15,
                      ),
                    ),
                    child: const Text('Ingresar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
