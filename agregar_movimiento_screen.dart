import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/cuenta.dart';
import '../models/movimiento.dart';
import '../services/storage_service.dart';

class AgregarMovimientoScreen extends StatefulWidget {
  final List<Cuenta> cuentas;

  const AgregarMovimientoScreen({super.key, required this.cuentas});

  @override
  State<AgregarMovimientoScreen> createState() => _AgregarMovimientoScreenState();
}

class _AgregarMovimientoScreenState extends State<AgregarMovimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();

  String _tipo = 'gasto';
  String? _cuentaId;
  DateTime _fecha = DateTime.now();

  final List<String> _categoriasSugeridas = [
    'Trabajo',
    'Compra de mercancía',
    'Transporte',
    'Alimentación',
    'Servicios',
    'Salud',
    'Educación',
    'Ocio',
    'Ropa',
    'Hogar',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.cuentas.isNotEmpty) {
      _cuentaId = widget.cuentas.first.id;
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notaCtrl.dispose();
    _categoriaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cuentaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una cuenta')),
      );
      return;
    }

    final mov = Movimiento(
      id: const Uuid().v4().replaceAll('-', '').substring(0, 20),
      categoria: _categoriaCtrl.text.trim(),
      creado: DateTime.now().millisecondsSinceEpoch,
      cuentaId: _cuentaId!,
      fecha: DateFormat('yyyy-MM-dd').format(_fecha),
      monto: double.parse(_montoCtrl.text.replaceAll('.', '').replaceAll(',', '')),
      nota: _notaCtrl.text.trim(),
      tipo: _tipo,
    );

    final storage = StorageService();
    await storage.agregarMovimiento(mov);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo movimiento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tipo
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'gasto',
                  label: Text('Gasto'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: 'ingreso',
                  label: Text('Ingreso'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 20),

            // Monto
            TextFormField(
              controller: _montoCtrl,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa el monto';
                if (double.tryParse(v.replaceAll('.', '').replaceAll(',', '')) == null) {
                  return 'Monto inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Categoría
            TextFormField(
              controller: _categoriaCtrl,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                hintText: 'Ej: Transporte, Trabajo...',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Ingresa una categoría' : null,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _categoriasSugeridas
                  .map((cat) => ActionChip(
                        label: Text(cat, style: const TextStyle(fontSize: 12)),
                        onPressed: () => _categoriaCtrl.text = cat,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Cuenta
            if (widget.cuentas.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No tienes cuentas. Ve a la pestaña Cuentas y crea una primero.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _cuentaId,
                decoration: const InputDecoration(labelText: 'Cuenta'),
                items: widget.cuentas
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.nombre),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _cuentaId = v),
              ),
            const SizedBox(height: 16),

            // Fecha
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_fecha)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fecha,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _fecha = picked);
              },
            ),
            const SizedBox(height: 8),

            // Nota
            TextFormField(
              controller: _notaCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'Descripción del movimiento',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save),
              label: const Text('Guardar movimiento'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
