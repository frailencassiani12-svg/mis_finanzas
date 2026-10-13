import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/cuenta.dart';
import '../models/movimiento.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'movimientos_screen.dart';
import 'cuentas_screen.dart';
import 'graficos_screen.dart';
import 'agregar_movimiento_screen.dart';
import 'admin_usuarios_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final AuthService _auth = AuthService();
  List<Cuenta> _cuentas = [];
  List<Movimiento> _movimientos = [];
  bool _cargando = true;
  bool _esAdmin = false;
  int _indiceActual = 0;

  final _formatoMoneda = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _verificarAdmin();
  }

  Future<void> _verificarAdmin() async {
    final esAdmin = await _auth.esAdmin();
    if (mounted) setState(() => _esAdmin = esAdmin);
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final cuentas = await _storage.cargarCuentas();
    final movimientos = await _storage.cargarMovimientos();
    setState(() {
      _cuentas = cuentas;
      _movimientos = movimientos;
      _cargando = false;
    });
  }

  double get _saldoTotal {
    double total = 0;
    for (final cuenta in _cuentas) {
      total += cuenta.saldoInicial;
      for (final mov in _movimientos.where((m) => m.cuentaId == cuenta.id)) {
        total += mov.esIngreso ? mov.monto : -mov.monto;
      }
    }
    return total;
  }

  double get _ingresosMes {
    final ahora = DateTime.now();
    return _movimientos
        .where((m) =>
            m.esIngreso &&
            DateTime.parse(m.fecha).month == ahora.month &&
            DateTime.parse(m.fecha).year == ahora.year)
        .fold(0.0, (sum, m) => sum + m.monto);
  }

  double get _gastosMes {
    final ahora = DateTime.now();
    return _movimientos
        .where((m) =>
            m.esGasto &&
            DateTime.parse(m.fecha).month == ahora.month &&
            DateTime.parse(m.fecha).year == ahora.year)
        .fold(0.0, (sum, m) => sum + m.monto);
  }

  Future<void> _importarRespaldo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final contenido = await file.readAsString();
      final data = jsonDecode(contenido) as Map<String, dynamic>;

      await _storage.importarRespaldo(data);
      await _cargarDatos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Respaldo importado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportarRespaldo() async {
    try {
      final data = await _storage.exportarRespaldo();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      final dir = await getTemporaryDirectory();
      final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File('${dir.path}/respaldo-mis-finanzas-$fecha.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Respaldo de Mis Finanzas',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Finanzas'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'importar') _importarRespaldo();
              if (value == 'exportar') _exportarRespaldo();
              if (value == 'actualizar') _cargarDatos();
              if (value == 'usuarios') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUsuariosScreen()),
                );
              }
              if (value == 'cerrar') {
                await _auth.logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'importar',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Importar respaldo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'exportar',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Exportar respaldo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'actualizar',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Actualizar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (_esAdmin)
                const PopupMenuItem(
                  value: 'usuarios',
                  child: ListTile(
                    leading: Icon(Icons.people),
                    title: Text('Administrar usuarios'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'cerrar',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _indiceActual,
              children: [
                _buildResumen(colorScheme),
                MovimientosScreen(
                  movimientos: _movimientos,
                  cuentas: _cuentas,
                  onActualizar: _cargarDatos,
                ),
                CuentasScreen(
                  cuentas: _cuentas,
                  movimientos: _movimientos,
                  onActualizar: _cargarDatos,
                ),
                GraficosScreen(
                  movimientos: _movimientos,
                  cuentas: _cuentas,
                ),
              ],
            ),
      floatingActionButton: _indiceActual == 0 || _indiceActual == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AgregarMovimientoScreen(
                      cuentas: _cuentas,
                    ),
                  ),
                );
                if (resultado == true) _cargarDatos();
              },
              icon: const Icon(Icons.add),
              label: const Text('Movimiento'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: (i) => setState(() => _indiceActual = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Movimientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Cuentas',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Gráficos',
          ),
        ],
      ),
    );
  }

  Widget _buildResumen(ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjeta de saldo total
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo total',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatoMoneda.format(_saldoTotal),
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_cuentas.length} cuenta${_cuentas.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ingresos y Gastos del mes
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.arrow_downward, color: Colors.green.shade600, size: 20),
                            const SizedBox(width: 6),
                            const Text('Ingresos', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatoMoneda.format(_ingresosMes),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const Text('este mes', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.arrow_upward, color: Colors.red.shade600, size: 20),
                            const SizedBox(width: 6),
                            const Text('Gastos', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatoMoneda.format(_gastosMes),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const Text('este mes', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Últimos movimientos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Últimos movimientos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () => setState(() => _indiceActual = 1),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_movimientos.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No hay movimientos aún',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Importa un respaldo o agrega tu primer movimiento',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._movimientos
                .take(8)
                .map((mov) => _buildMovimientoTile(mov))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildMovimientoTile(Movimiento mov) {
    final cuentaList = _cuentas.where((c) => c.id == mov.cuentaId).toList();
    final cuenta = cuentaList.isNotEmpty ? cuentaList.first : null;
    final esIngreso = mov.esIngreso;

    return Card(
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${esIngreso ? '+' : '-'}${_formatoMoneda.format(mov.monto)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: esIngreso ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ),
    );
  }
}
