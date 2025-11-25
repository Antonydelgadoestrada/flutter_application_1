import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_usuarios.dart';
import 'sync_usuarios.dart';
import 'connectivity_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _connectivityService.addListener(_onConnectivityChanged);
    _loadUsers();
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    _connectivityService.dispose();
    super.dispose();
  }

  void _onConnectivityChanged() {
    setState(() {});
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final list = await DBHelper.obtenerTodosUsuarios();
    debugPrint('📱 Usuarios en BD: ${list.length}');
    for (final u in list) {
      debugPrint('   - ${u['usuario']} (role: ${u['role']})');
    }
    setState(() {
      _users = list;
      _loading = false;
    });
  }

  Future<void> _limpiarBDNow() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🔧 LIMPIAR BD'),
        content: const Text(
          'Esto borrará todos los usuarios y recreará la tabla.\nSolo quedará admin.\n\n¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SÍ, LIMPIAR'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DBHelper.limpiarTablaUsuarios();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ BD limpiada correctamente')),
        );
        await _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  Future<void> _descargarUsuariosFirestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('📥 Descargar de Firestore'),
        content: const Text(
          'Esto descargará TODOS los usuarios de Firestore y los guardará localmente.\n\n¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SÍ, DESCARGAR'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Descargando usuarios...')),
        );
        await SyncUsuarios.descargarUsuariosDelServidor();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Usuarios descargados correctamente')),
        );
        await _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  // Validar email
  bool _esEmailValido(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  // Validar DNI (8 dígitos)
  bool _esDNIValido(String dni) {
    return dni.length == 8 && int.tryParse(dni) != null;
  }

  Future<void> _showAddDialog() async {
    if (!_connectivityService.hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ No hay conexión a internet. La gestión de usuarios requiere conexión.',
          ),
        ),
      );
      return;
    }

    final usuarioController = TextEditingController();
    final passwordController = TextEditingController();
    final dniController = TextEditingController();
    final correoController = TextEditingController();
    final telefonoController = TextEditingController();
    final cargoController = TextEditingController();
    String role = 'user';
    final _formKey = GlobalKey<FormState>();

    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar usuario'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: usuarioController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Usuario es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña *',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Contraseña es obligatoria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: dniController,
                  decoration: const InputDecoration(
                    labelText: 'DNI (8 dígitos) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'DNI es obligatorio';
                    }
                    if (!_esDNIValido(value.trim())) {
                      return 'DNI debe tener exactamente 8 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: correoController,
                  decoration: const InputDecoration(
                    labelText: 'Correo *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Correo es obligatorio';
                    }
                    if (!_esEmailValido(value.trim())) {
                      return 'Correo no válido (ej: usuario@example.com)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: cargoController,
                  decoration: const InputDecoration(
                    labelText: 'Cargo (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('Usuario')),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Administrador'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) role = v;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Rol *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) {
                return;
              }

              final usuario = usuarioController.text.trim();
              final pass = passwordController.text.trim();
              final dni = dniController.text.trim();
              final correo = correoController.text.trim();
              final telefono = telefonoController.text.trim();
              final cargo = cargoController.text.trim();

              // Validar contraseña
              if (!DBHelper.validarPassword(pass)) {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('❌ Contraseña insegura'),
                      content: const Text(
                        'La contraseña debe tener:\n- Al menos 8 caracteres\n- Mayúscula\n- Minúscula\n- Un número\n- Un carácter especial',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
                return;
              }

              final id = await DBHelper.registrarUsuario(
                usuario,
                pass,
                dni: dni,
                correo: correo,
                telefono: telefono.isNotEmpty ? telefono : null,
                cargo: cargo.isNotEmpty ? cargo : null,
                role: role,
              );

              if (id > 0) {
                try {
                  await SyncUsuarios.subirUsuariosAlServidor();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Usuario creado y sincronizado'),
                    ),
                  );
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '⚠️ Usuario creado pero error en sincronización: $e',
                      ),
                    ),
                  );
                  Navigator.pop(context, true);
                }
              } else if (id == -2) {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('❌ Contraseña insegura'),
                      content: const Text(
                        'La contraseña debe cumplir todos los requisitos.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              } else if (id == -1) {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('❌ Usuario ya existe'),
                      content: const Text('El usuario ya está registrado.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (res == true) {
      await _loadUsers();
    }
  }

  Future<void> _deleteUser(String usuario) async {
    if (usuario == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar el admin por seguridad'),
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(
          '¿Eliminar usuario $usuario? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DBHelper.eliminarUsuario(usuario);
      await _loadUsers();
    }
  }

  Future<void> _deleteAllUsers() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Advertencia'),
        content: const Text(
          'Esto eliminará TODOS los usuarios excepto admin. ¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, eliminar todos'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DBHelper.eliminarTodosUsuariosExceptoAdmin();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todos los usuarios eliminados')),
        );
        await _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _limpiarTodoSinRecuperar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ BORRAR TODO (INCLUYENDO ADMIN)'),
        content: const Text(
          'Esto eliminará TODOS los usuarios incluyendo admin de SQLite. Deberás reinstalar la app. ¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, borrar TODO'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Borrar TODO de la tabla usuarios
        final dbClient = await DBHelper.db;
        await dbClient.delete('usuarios');
        print('TODOS los usuarios eliminados de SQLite');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'TODOS los usuarios han sido eliminados. Reinicia la app.',
            ),
          ),
        );
        await _loadUsers();
      } catch (e) {
        print('Error borrando: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _limpiarFirestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🔥 Limpiar Firestore'),
        content: const Text(
          'Esto eliminará TODOS los usuarios de Firestore. ¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, limpiar Firestore'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .get();

        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firestore limpiado correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error limpiando Firestore: $e')),
        );
      }
    }
  }

  Future<void> _resetearTodoCompletamente() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ RESETEAR TODO'),
        content: const Text(
          'Esto eliminará COMPLETAMENTE la base de datos local (SQLite) Y Firestore. Se recreará la BD con solo admin. ¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, resetear TODO'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 1. Limpiar Firestore
        final snapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
        print('Firestore limpiado');

        // 2. Resetear SQLite (eliminar y recrear)
        await DBHelper.resetearBaseDatos();
        print('SQLite reseteado');

        // 3. Esperar un poco para que SQLite se reinicie correctamente
        await Future.delayed(const Duration(milliseconds: 500));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Base de datos reseteada completamente'),
            duration: Duration(seconds: 2),
          ),
        );
        await _loadUsers();
      } catch (e) {
        print('Error en reseteo: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error reseteando: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar usuarios'),
        actions: [
          // Indicador de conectividad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Tooltip(
                message: _connectivityService.hasInternet
                    ? '🌐 Conectado - Gestión disponible'
                    : '❌ Sin conexión - Gestión deshabilitada',
                child: Icon(
                  _connectivityService.hasInternet
                      ? Icons.cloud_done
                      : Icons.cloud_off,
                  color: _connectivityService.hasInternet
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _connectivityService.hasInternet ? _showAddDialog : null,
            icon: const Icon(Icons.person_add),
            tooltip: _connectivityService.hasInternet
                ? 'Agregar usuario'
                : 'Sin internet - Deshabilitado',
          ),
          IconButton(
            onPressed: _connectivityService.hasInternet ? _limpiarBDNow : null,
            icon: const Icon(Icons.cleaning_services),
            tooltip: _connectivityService.hasInternet
                ? 'LIMPIAR BD AHORA'
                : 'Sin internet - Deshabilitado',
          ),
          PopupMenuButton(
            enabled: _connectivityService.hasInternet,
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _descargarUsuariosFirestore,
                child: const Text('📥 Descargar de Firestore'),
              ),
              PopupMenuItem(
                onTap: _deleteAllUsers,
                child: const Text('Eliminar todos'),
              ),
              PopupMenuItem(
                onTap: _limpiarFirestore,
                child: const Text('Limpiar Firestore'),
              ),
              PopupMenuItem(
                onTap: _resetearTodoCompletamente,
                child: const Text('Resetear TODO'),
              ),
              PopupMenuItem(
                onTap: _limpiarTodoSinRecuperar,
                child: const Text('⚠️ Borrar TODO (incluyendo admin)'),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (_, i) {
                  final u = _users[i];
                  final usuario = u['usuario'] ?? '';
                  final role = u['role'] ?? 'user';
                  final cargo = u['cargo'] ?? '';
                  final correo = u['correo'] ?? '';
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        usuario.isNotEmpty ? usuario[0].toUpperCase() : '?',
                      ),
                    ),
                    title: Text(usuario),
                    subtitle: Text(
                      'Rol: $role${cargo.isNotEmpty ? ' · $cargo' : ''}${correo.isNotEmpty ? ' · $correo' : ''}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteUser(usuario),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
