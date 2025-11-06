import 'package:flutter/material.dart';
import 'database_usuarios.dart';

class UserPage extends StatefulWidget {
  final String usuario; // Recibe el nombre del usuario
  const UserPage({super.key, required this.usuario});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  Map<String, dynamic>? datosUsuario;

  @override
  void initState() {
    super.initState();
    cargarDatosUsuario();
  }

  Future<void> cargarDatosUsuario() async {
    final datos = await DBHelper.obtenerUsuario(widget.usuario);
    setState(() {
      datosUsuario = datos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          'Perfil de Usuario',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: datosUsuario == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icono de usuario con estilo
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '¡Hola!\n${datosUsuario!['usuario']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Sección de datos personales
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mis datos personales',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // DNI
                        ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: Text(
                            datosUsuario!['dni'] ?? 'No especificado',
                            style: const TextStyle(fontSize: 16),
                          ),
                          subtitle: const Text('DNI'),
                        ),
                        const Divider(),

                        // Cargo
                        ListTile(
                          leading: const Icon(Icons.work_outline),
                          title: Text(
                            datosUsuario!['cargo'] ?? 'No especificado',
                            style: const TextStyle(fontSize: 16),
                          ),
                          subtitle: const Text('Cargo'),
                        ),
                        const Divider(),

                        // Correo
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: Text(
                            datosUsuario!['correo'] ?? 'No especificado',
                            style: const TextStyle(fontSize: 16),
                          ),
                          subtitle: const Text('Correo electrónico'),
                        ),
                        const Divider(),

                        // Teléfono
                        ListTile(
                          leading: const Icon(Icons.phone_outlined),
                          title: Text(
                            datosUsuario!['telefono'] ?? 'No especificado',
                            style: const TextStyle(fontSize: 16),
                          ),
                          subtitle: const Text('Teléfono'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Sección de sugerencias
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¿Cómo podemos mejorar esta aplicación?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          maxLength: 100,
                          decoration: const InputDecoration(
                            hintText: 'Escribe aquí tu sugerencia...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            // Acción para enviar sugerencia
                          },
                          child: const Text('Enviar'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Botón de cerrar sesión
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Cerrar sesión'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'La belleza real no se crea, se descubre en la naturaleza que nos rodea.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
    );
  }
}
