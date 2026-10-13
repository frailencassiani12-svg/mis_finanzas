import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/cuenta.dart';
import '../models/movimiento.dart';

class GraficosScreen extends StatelessWidget {
  final List<Movimiento> movimientos;
  final List<Cuenta> cuentas;

  const GraficosScreen({
    super.key,
    required this.movimientos,
    required this.cuentas,
  });

  final _formatoMoneda = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  Map<String, double> get _gastosPorCategoria {
    final map = <String, double>{};
    for (final mov in movimientos.where((m) => m.esGasto)) {
      map[mov.categoria] = (map[mov.categoria] ?? 0) + mov.monto;
    }
    return map;
  }

  Map<String, double> get _ingresosPorCategoria {
    final map = <String, double>{};
    for (final mov in movimientos.where((m) => m.esIngreso)) {
      map[mov.categoria] = (map[mov.categoria] ?? 0) + mov.monto;
    }
    return map;
  }

  List<Color> get _colores => [
        Colors.teal,
        Colors.orange,
        Colors.blue,
        Colors.purple,
        Colors.red,
        Colors.green,
        Colors.indigo,
        Colors.pink,
        Colors.amber,
        Colors.cyan,
      ];

  @override
  Widget build(BuildContext context) {
    final gastos = _gastosPorCategoria;
    final ingresos = _ingresosPorCategoria;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Gastos por categoría',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (gastos.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No hay gastos registrados')),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _buildSections(gastos),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...gastos.entries.toList().asMap().entries.map((entry) {
                    final i = entry.key;
                    final e = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _colores[i % _colores.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.key)),
                          Text(
                            _formatoMoneda.format(e.value),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        const SizedBox(height: 28),

        Text(
          'Ingresos por categoría',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (ingresos.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No hay ingresos registrados')),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _buildSections(ingresos),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...ingresos.entries.toList().asMap().entries.map((entry) {
                    final i = entry.key;
                    final e = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _colores[i % _colores.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.key)),
                          Text(
                            _formatoMoneda.format(e.value),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        const SizedBox(height: 28),

        Text(
          'Resumen general',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _filaResumen(
                  'Total ingresos',
                  movimientos
                      .where((m) => m.esIngreso)
                      .fold(0.0, (s, m) => s + m.monto),
                  Colors.green,
                ),
                const Divider(),
                _filaResumen(
                  'Total gastos',
                  movimientos
                      .where((m) => m.esGasto)
                      .fold(0.0, (s, m) => s + m.monto),
                  Colors.red,
                ),
                const Divider(),
                _filaResumen(
                  'Balance',
                  movimientos.fold(
                    0.0,
                    (s, m) => s + (m.esIngreso ? m.monto : -m.monto),
                  ),
                  Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(Map<String, double> data) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    return data.entries.toList().asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      final porcentaje = total > 0 ? (e.value / total * 100) : 0;

      return PieChartSectionData(
        color: _colores[i % _colores.length],
        value: e.value,
        title: '${porcentaje.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _filaResumen(String label, double valor, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(
            _formatoMoneda.format(valor),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
