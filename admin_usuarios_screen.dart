import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  final _auth = AuthService();
  List<Map<String, dynamic>> _usuarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final lista = await _auth.listarUsuarios();
    setState(() {
      _usuarios = lista;
      _cargando = false;
    });
  }

  Future<void> _crearUsuario() async {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar nueva persona'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Esta persona podrá iniciar sesión en este dispositivo y manejar sus propias finanzas.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outlined),
                  helperText: 'Mínimo 4 caracteres',
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (nombreCtrl.text.trim().isEmpty ||
                  emailCtrl.text.trim().isEmpty ||
                  passwordCtrl.text.length < 4) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Crear usuario'),
          ),
        ],
      ),
    );

    if (resultado != true) return;

    try {
      await _auth.crearUsuario(
        email: emailCtrl.text,
        password: passwordCtrl.text,
        nombre: nombreCtrl.text,
      );
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario ${nombreCtrl.text} creado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar usuarios')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _usuarios.isEmpty
              ? const Center(child: Text('No hay usuarios registrados'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _usuarios.length,
                  itemBuilder: (context, index) {
                    final data = _usuarios[index];
                    final esAdmin = data['rol'] == 'admin';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: esAdmin
                              ? Colors.amber.withOpacity(0.2)
                              : Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            esAdmin ? Icons.star : Icons.person,
                            color: esAdmin
                                ? Colors.amber.shade800
                                : Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(data['nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(data['email'] ?? ''),
                        trailing: Chip(
                          label: Text(esAdmin ? 'Admin' : 'Usuario', style: const TextStyle(fontSize: 12)),
                          backgroundColor: esAdmin ? Colors.amber.withOpacity(0.15) : Colors.blue.withOpacity(0.1),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearUsuario,
        icon: const Icon(Icons.person_add),
        label: const Text('Registrar persona'),
      ),
    );
  }
}
