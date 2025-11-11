import 'package:flutter/material.dart';
import 'package:flutter_application_1/user_page.dart';
import 'package:flutter_application_1/lista_productores.dart'; // Asegúrate de importar la página de selección de productor
import 'main.dart'; // Importa el archivo donde está LoginPage
import 'package:flutter_application_1/nueva_actividad_diaria.dart'; // Importa la página de nueva actividad diaria
import 'package:flutter_application_1/ver_registros.dart'; // Importa la página de ver registros
import 'package:flutter_application_1/database_productores.dart'; // Importa tu clase de base de datos
import 'reportes_page.dart';
import 'firestore_sync_manager.dart';
import 'admin_users_page.dart';

class HomePage extends StatelessWidget {
  final String? productorSeleccionado;
  final String usuarioLogueado;
  final bool isAdmin;
  const HomePage({
    super.key,
    this.productorSeleccionado,
    required this.usuarioLogueado,
    this.isAdmin = false,
  });

  void _cerrarSesion(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _mostrarAlerta(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Atención'),
        content: const Text('Primero tienes que elegir productor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
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
        title: Image.asset('assets/logo.png', height: 100),
        centerTitle: true,
        actions: [
          // { changed code } botón pequeño de sincronización
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.black),
            tooltip: 'Sincronizar ahora',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Iniciando sincronización...')),
              );
              try {
                await FirestoreSyncManager.runSync();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sincronización completada.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error en sincronización: ${e.toString()}'),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: () {
              // Al abrir el perfil:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserPage(usuario: usuarioLogueado),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF6B2B2B),
          child: Column(
            children: [
              const SizedBox(height: 40),
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
                  if (productorSeleccionado == null) {
                    _mostrarAlerta(context);
                  } else {
                    // Aquí podrías navegar a una pantalla de inspecciones
                    // Por ahora, navega a actividades diarias como ejemplo
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NuevaActividadDiariaPage(
                          nombreProductor: productorSeleccionado!,
                        ),
                      ),
                    );
                  }
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
                children: [
                  ListTile(
                    title: const Text(
                      '> Seleccionar productor',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      final productor = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SelectProductorPage(
                            productores: [
                              'Productor 1',
                              'Productor 2',
                              'Productor 3',
                              // ...agrega tu lista real aquí...
                            ],
                          ),
                        ),
                      );
                      if (productor != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomePage(
                              productorSeleccionado: productor,
                              usuarioLogueado: usuarioLogueado,
                              isAdmin: isAdmin,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    title: const Text(
                      '> Actividades Diarias',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      if (productorSeleccionado == null) {
                        _mostrarAlerta(context);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NuevaActividadDiariaPage(
                              nombreProductor: productorSeleccionado!,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    title: const Text(
                      '> Registro de riego',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      if (productorSeleccionado == null) {
                        _mostrarAlerta(context);
                      } else {
                        // Navegar a registro de riego
                      }
                    },
                  ),
                  ListTile(
                    title: const Text(
                      '> Registro de fertilización',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      if (productorSeleccionado == null) {
                        _mostrarAlerta(context);
                      } else {
                        // Navegar a registro de fertilización
                      }
                    },
                  ),
                  ListTile(
                    title: const Text(
                      '> Registro de compra de insumos',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      if (productorSeleccionado == null) {
                        _mostrarAlerta(context);
                      } else {
                        // Navegar a registro de compra de insumos
                      }
                    },
                  ),
                  ListTile(
                    title: const Text(
                      '> Registro de cosecha y venta',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      if (productorSeleccionado == null) {
                        _mostrarAlerta(context);
                      } else {
                        // Navegar a registro de cosecha y venta
                      }
                    },
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
                children: [
                  ListTile(
                    title: const Text(
                      '> Generar informe PDF',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      if (productorSeleccionado == null) {
                        _mostrarAlerta(context);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportesPage(),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    title: const Text(
                      '> Generar informe Excel',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      if (productorSeleccionado == null) {
                        _mostrarAlerta(context);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportesPage(),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    title: const Text(
                      '> Ver informes anteriores',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      if (productorSeleccionado == null) {
                        _mostrarAlerta(context);
                      } else {
                        // Navegar a ver informes anteriores
                      }
                    },
                  ),
                  ListTile(
                    title: const Text(
                      '> Compartir / exportar',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      if (productorSeleccionado == null) {
                        _mostrarAlerta(context);
                      } else {
                        // Navegar a compartir/exportar informes
                      }
                    },
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
                children: [
                  ListTile(
                    title: const Text(
                      '> Guardar localmente',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      // Aquí podrías implementar la lógica de guardado local
                    },
                  ),
                  ListTile(
                    title: const Text(
                      '> Sincronizar con servidor',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      // Aquí podrías implementar la lógica de sincronización con Firebase
                    },
                  ),
                ],
              ),
              const Spacer(),
              Container(
                color: const Color(0xFFFFB266),
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
              // Botón para administrar usuarios (sólo accesible por admin)
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                ),
                title: const Text(
                  'Administrar usuarios',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  if (!isAdmin) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Acceso denegado'),
                        content: const Text(
                          'Solo el administrador puede gestionar usuarios.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context); // cerrar drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminUsersPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 80, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.redAccent,
                    child: Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              productorSeleccionado != null
                  ? 'Productor: $productorSeleccionado'
                  : 'Usuario 1',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              '¿Qué deseas hacer ahora?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                children: [
                  _HomeButton(
                    icon: Icons.person_search,
                    label: 'PRODUCTORES',
                    onTap: () async {
                      final productor = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SelectProductorPage(
                            productores: [
                              'Productor 1',
                              'Productor 2',
                              'Productor 3',
                              // ...agrega tu lista real aquí...
                            ],
                          ),
                        ),
                      );
                      if (productor != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomePage(
                              productorSeleccionado:
                                  productor, // solo para actividades
                              usuarioLogueado:
                                  usuarioLogueado, // solo para perfil
                              isAdmin: isAdmin, // mantener estado admin
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _HomeButton(
                    icon: Icons.event_note,
                    label: 'NUEVA ACTIVIDAD DIARIA',
                    onTap: () {
                      if (productorSeleccionado == null) {
                        _mostrarAlerta(context);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NuevaActividadDiariaPage(
                              nombreProductor: productorSeleccionado!,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _HomeButton(
                    icon: Icons.insert_chart,
                    label: 'VER REGISTROS',
                    onTap: () async {
                      if (productorSeleccionado == null) {
                        _mostrarAlerta(context);
                      } else {
                        // Aquí obtienes el ID del productor por su nombre
                        final productorId =
                            await DBProductores.obtenerIdPorNombre(
                              productorSeleccionado!,
                            );
                        if (productorId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No se encontró el productor en la base de datos.',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VerRegistrosPage(productorId: productorId),
                          ),
                        );
                      }
                    },
                  ),
                  _HomeButton(
                    icon: Icons.cloud,
                    label: 'REPORTES',
                    onTap: () {
                      if (productorSeleccionado == null) {
                        _mostrarAlerta(context);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportesPage(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'La naturaleza nos regala, día tras día, retratos de lo que es la auténtica belleza.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF008060),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
