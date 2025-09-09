import 'package:flutter/material.dart';
import 'main.dart'; // Importa el archivo donde está LoginPage

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _cerrarSesion(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Image.asset('assets/logo.png', height: 120),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: () {
              // Acción para el perfil de usuario
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF6B2B2B), // Marrón elegante
          child: Column(
            children: [
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.assignment_turned_in,
                        color: Colors.white,
                      ),
                      title: const Text(
                        'Mis inspecciones',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        // Acción para Mis inspecciones
                      },
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.menu_book, color: Colors.white),
                      title: const Text(
                        'Cuaderno de campo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      collapsedIconColor: Colors.white,
                      iconColor: Colors.white,
                      children: const [
                        ListTile(
                          title: Text(
                            '> Datos del productor',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            '> Actividades Diarias',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            '> Registro de riego',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            '> Registro de fertilización',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            '> Registro de compra de insumos',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            '> Registro de cosecha y venta',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.bar_chart, color: Colors.white),
                      title: const Text(
                        'Reportes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      collapsedIconColor: Colors.white,
                      iconColor: Colors.white,
                      children: const [
                        ListTile(
                          title: Text(
                            '> Generar informe PDF',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            '> Generar informe Excel',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            '> Ver informes anteriores',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            '> Compartir / exportar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.sync, color: Colors.white),
                      title: const Text(
                        'Sincronizar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      collapsedIconColor: Colors.white,
                      iconColor: Colors.white,
                      children: const [
                        ListTile(
                          title: Text(
                            '> Guardar localmente',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            '> Sincronizar con servidor',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Botón de cerrar sesión
              Container(
                color: const Color(0xFFFFB266), // Naranja elegante
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.black),
                  title: const Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _cerrarSesion(context),
                ),
              ),
            ],
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Bienvenido a la página principal',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
