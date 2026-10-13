import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/cuenta.dart';
import '../models/movimiento.dart';
import '../services/storage_service.dart';

class CuentasScreen extends StatelessWidget {
  final List<Cuenta> cuentas;
  final List<Movimiento> movimientos;
  final VoidCallback onActualizar;

  const CuentasScreen({
    super.key,
    required this.cuentas,
    required this.movimientos,
    required this.onActualizar,
  });

  final _formatoMoneda = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  double _saldoCuenta(Cuenta cuenta) {
    double saldo = cuenta.saldoInicial;
    for (final mov in movimientos.where((m) => m.cuentaId == cuenta.id)) {
      saldo += mov.esIngreso ? mov.monto : -mov.monto;
    }
    return saldo;
  }

  Future<void> _agregarCuenta(BuildContext context) async {
    final nombreCtrl = TextEditingController();
    String tipo = 'Banco';
    final saldoCtrl = TextEditingController(text: '0');

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nueva cuenta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la cuenta',
                  hintText: 'Ej: Bancolombia, Efectivo...',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'Banco', child: Text('Banco')),
                  DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                  DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                  DropdownMenuItem(value: 'Ahorros', child: Text('Ahorros')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: (v) => setState(() => tipo = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: saldoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Saldo inicial',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (nombreCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (resultado == true && nombreCtrl.text.trim().isNotEmpty) {
      final nueva = Cuenta(
        id: const Uuid().v4().replaceAll('-', '').substring(0, 20),
        creada: DateTime.now().millisecondsSinceEpoch,
        nombre: nombreCtrl.text.trim(),
        saldoInicial: double.tryParse(saldoCtrl.text.replaceAll(',', '')) ?? 0,
        tipo: tipo,
      );

      final storage = StorageService();
      await storage.agregarCuenta(nueva);
      onActualizar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: cuentas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No tienes cuentas aún'),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea una cuenta o importa un respaldo',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cuentas.length,
              itemBuilder: (context, index) {
                final cuenta = cuentas[index];
                final saldo = _saldoCuenta(cuenta);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        _iconoTipo(cuenta.tipo),
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      cuenta.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(cuenta.tipo),
                    trailing: Text(
                      _formatoMoneda.format(saldo),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: saldo >= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _agregarCuenta(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'banco':
        return Icons.account_balance;
      case 'efectivo':
        return Icons.payments;
      case 'tarjeta':
        return Icons.credit_card;
      case 'ahorros':
        return Icons.savings;
      default:
        return Icons.wallet;
    }
  }
}
