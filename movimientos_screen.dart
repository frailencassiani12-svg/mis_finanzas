import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cuenta.dart';
import '../models/movimiento.dart';
import '../services/storage_service.dart';

class MovimientosScreen extends StatefulWidget {
  final List<Movimiento> movimientos;
  final List<Cuenta> cuentas;
  final VoidCallback onActualizar;

  const MovimientosScreen({
    super.key,
    required this.movimientos,
    required this.cuentas,
    required this.onActualizar,
  });

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  String _filtroTipo = 'todos';
  String? _filtroCategoria;
  final _formatoMoneda = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  List<Movimiento> get _filtrados {
    var lista = List<Movimiento>.from(widget.movimientos);

    if (_filtroTipo != 'todos') {
      lista = lista.where((m) => m.tipo == _filtroTipo).toList();
    }
    if (_filtroCategoria != null) {
      lista = lista.where((m) => m.categoria == _filtroCategoria).toList();
    }

    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  Set<String> get _categorias {
    return widget.movimientos.map((m) => m.categoria).toSet();
  }

  Future<void> _eliminarMovimiento(Movimiento mov) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: Text('¿Eliminar "${mov.categoria}" por ${_formatoMoneda.format(mov.monto)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final storage = StorageService();
      await storage.eliminarMovimiento(mov.id);
      widget.onActualizar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtros
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'todos', label: Text('Todos')),
                    ButtonSegment(value: 'ingreso', label: Text('Ingresos')),
                    ButtonSegment(value: 'gasto', label: Text('Gastos')),
                  ],
                  selected: {_filtroTipo},
                  onSelectionChanged: (s) => setState(() => _filtroTipo = s.first),
                ),
              ),
            ],
          ),
        ),
        if (_categorias.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                FilterChip(
                  label: const Text('Todas'),
                  selected: _filtroCategoria == null,
                  onSelected: (_) => setState(() => _filtroCategoria = null),
                ),
                const SizedBox(width: 8),
                ..._categorias.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: _filtroCategoria == cat,
                        onSelected: (_) => setState(() {
                          _filtroCategoria = _filtroCategoria == cat ? null : cat;
                        }),
                      ),
                    )),
              ],
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: _filtrados.isEmpty
              ? const Center(
                  child: Text('No hay movimientos con estos filtros'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filtrados.length,
                  itemBuilder: (context, index) {
                    final mov = _filtrados[index];
                    final cuentaList = widget.cuentas
                        .where((c) => c.id == mov.cuentaId)
                        .toList();
                    final cuenta = cuentaList.isNotEmpty ? cuentaList.first : null;
                    final esIngreso = mov.esIngreso;

                    return Dismissible(
                      key: Key(mov.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        await _eliminarMovimiento(mov);
                        return false;
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: esIngreso
                                ? Colors.green.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15),
                            child: Icon(
                              esIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                              color: esIngreso ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            mov.categoria,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            [
                              if (mov.nota.isNotEmpty) mov.nota,
                              mov.fecha,
                              if (cuenta != null) cuenta.nombre,
                            ].where((e) => e.isNotEmpty).join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '${esIngreso ? '+' : '-'}${_formatoMoneda.format(mov.monto)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: esIngreso
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
