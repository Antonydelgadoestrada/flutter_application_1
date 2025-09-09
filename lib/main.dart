import 'package:flutter/material.dart';
import 'database.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // AGREGAMOS LOS USUARIOS PREDEFINIDOS
  await DBHelper.registrarUsuario('admin', '1234');
  await DBHelper.registrarUsuario('usuario', 'abcd');
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

  Future<void> _login() async {
    final usuario = userController.text.trim();
    final password = passController.text.trim();
    final valido = await DBHelper.validarUsuario(usuario, password);
    if (valido) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 110,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment
                        .centerRight, // O usa Alignment(0.6, 0.0) para un poco a la derecha
                    child: Image.asset(
                      'assets/logo.png',
                      height: 250,
                      width: 250,
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
