import 'package:flutter/material.dart';
import 'database_usuarios.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final list = await DBHelper.obtenerTodosUsuarios();
    setState(() {
      _users = list;
      _loading = false;
    });
  }

  Future<void> _showAddDialog() async {
    final usuarioController = TextEditingController();
    final passwordController = TextEditingController();
    final dniController = TextEditingController();
    final correoController = TextEditingController();
    final telefonoController = TextEditingController();
    final cargoController = TextEditingController();
    String role = 'user';

    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar usuario'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usuarioController,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dniController,
                decoration: const InputDecoration(labelText: 'DNI'),
              ),
              TextField(
                controller: correoController,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: cargoController,
                decoration: const InputDecoration(labelText: 'Cargo'),
              ),
              const SizedBox(height: 8),
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
                decoration: const InputDecoration(labelText: 'Rol'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final usuario = usuarioController.text.trim();
              final pass = passwordController.text.trim();
              final dni = dniController.text.trim();
              final correo = correoController.text.trim();
              final telefono = telefonoController.text.trim();
              final cargo = cargoController.text.trim();
              if (usuario.isEmpty || pass.isEmpty) return;
              // Validar contraseña en cliente antes de intentar crear
              if (!DBHelper.validarPassword(pass)) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Contraseña insegura'),
                    content: const Text(
                      'La contraseña debe tener al menos 8 caracteres, incluir mayúscula, minúscula, un número y un carácter especial.',
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
              final id = await DBHelper.registrarUsuario(
                usuario,
                pass,
                dni: dni.isNotEmpty ? dni : null,
                correo: correo.isNotEmpty ? correo : null,
                telefono: telefono.isNotEmpty ? telefono : null,
                cargo: cargo.isNotEmpty ? cargo : null,
                role: role,
              );
              if (id > 0) {
                // update role if admin
                // role already saved via registrarUsuario
                Navigator.pop(context, true);
              } else if (id == -2) {
                // contraseña inválida (doble verificación)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contraseña no cumple requisitos'),
                  ),
                );
              } else {
                // usuario existe
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El usuario ya existe')),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (res == true) await _loadUsers();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar usuarios'),
        actions: [
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.person_add),
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
