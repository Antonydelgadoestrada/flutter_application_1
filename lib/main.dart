import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

import 'database_usuarios.dart';
import 'firebase_options.dart';
import 'sync_usuarios.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Seed admin user in the local usuarios DB (creates admin/administrado1234 if missing)
  try {
    await DBHelper.seedAdmin();
    // debug: listar usuarios existentes tras seed
    try {
      final all = await DBHelper.obtenerTodosUsuarios();
      debugPrint('Usuarios en usuarios.db después de seed: $all');
    } catch (e) {
      debugPrint('No se pudieron listar usuarios tras seed: $e');
    }
  } catch (e) {
    // ignore seed errors during startup
  }

  // Descargar usuarios de Firestore la PRIMERA VEZ que se abre la app
  try {
    final prefs = await SharedPreferences.getInstance();
    final esLaPrimeraVez = prefs.getBool('primera_vez_app') ?? true;

    if (esLaPrimeraVez) {
      debugPrint(
        '=== Primera vez abriendo la app, descargando usuarios de Firestore ===',
      );
      await SyncUsuarios.descargarUsuariosDelServidor();
      // Marcar que ya no es primera vez
      await prefs.setBool('primera_vez_app', false);
      debugPrint(
        '=== Usuarios descargados y primera_vez marcada como false ===',
      );
    } else {
      debugPrint('No es primera vez, saltando descarga de usuarios');
    }
  } catch (e) {
    debugPrint('Error descargando usuarios en main: $e');
    // No bloquea el inicio de la app si hay error
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

  Future<Map<String, dynamic>?> validarUsuarioSQLite(
    String usuario,
    String password,
  ) async {
    return await DBHelper.validarUsuario(usuario, password);
  }

  Future<void> _login() async {
    final usuario = userController.text.trim();
    final password = passController.text.trim();
    final userData = await validarUsuarioSQLite(usuario, password);

    if (userData != null) {
      debugPrint('Login exitoso: $userData'); // Debug info
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            productorSeleccionado: null,
            usuarioLogueado: userData['usuario'] as String,
            isAdmin: userData['role'] == 'admin',
          ),
        ),
      );
    } else {
      // debug info: mostrar usuario buscado y si existe en DB
      try {
        final found = await DBHelper.obtenerUsuario(usuario);
        debugPrint('Login fallido para $usuario. Registro en DB: $found');
      } catch (e) {
        debugPrint('Error al comprobar usuario en DB: $e');
      }
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
                      width: 310,
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
                    onPressed: _login,
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
