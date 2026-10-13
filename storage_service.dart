import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cuenta.dart';
import '../models/movimiento.dart';
import 'auth_service.dart';

class StorageService {
  final AuthService _auth = AuthService();

  Future<String> _key(String tipo) async {
    final uid = await _auth.getCurrentUserId();
    if (uid == null) throw Exception('Usuario no autenticado');
    return '${tipo}_$uid';
  }

  Future<List<Cuenta>> cargarCuentas() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key('cuentas');
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return [];
    final List list = jsonDecode(jsonStr);
    return list.map((e) => Cuenta.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Movimiento>> cargarMovimientos() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key('movimientos');
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return [];
    final List list = jsonDecode(jsonStr);
    return list.map((e) => Movimiento.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _guardarCuentas(List<Cuenta> cuentas) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key('cuentas');
    await prefs.setString(key, jsonEncode(cuentas.map((e) => e.toJson()).toList()));
  }

  Future<void> _guardarMovimientos(List<Movimiento> movimientos) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key('movimientos');
    await prefs.setString(key, jsonEncode(movimientos.map((e) => e.toJson()).toList()));
  }

  Future<void> agregarCuenta(Cuenta cuenta) async {
    final cuentas = await cargarCuentas();
    cuentas.add(cuenta);
    await _guardarCuentas(cuentas);
  }

  Future<void> agregarMovimiento(Movimiento movimiento) async {
    final movimientos = await cargarMovimientos();
    movimientos.add(movimiento);
    await _guardarMovimientos(movimientos);
  }

  Future<void> eliminarMovimiento(String id) async {
    final movimientos = await cargarMovimientos();
    movimientos.removeWhere((m) => m.id == id);
    await _guardarMovimientos(movimientos);
  }

  Future<void> eliminarCuenta(String id) async {
    final cuentas = await cargarCuentas();
    cuentas.removeWhere((c) => c.id == id);
    await _guardarCuentas(cuentas);
  }

  Future<void> importarRespaldo(Map<String, dynamic> data) async {
    if (data['formato'] != 'mis-finanzas-respaldo-v1') {
      throw Exception('Formato de respaldo no compatible');
    }

    final cuentas = (data['cuentas'] as List)
        .map((e) => Cuenta.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final movimientos = (data['movimientos'] as List)
        .map((e) => Movimiento.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    await _guardarCuentas(cuentas);
    await _guardarMovimientos(movimientos);
  }

  Future<Map<String, dynamic>> exportarRespaldo() async {
    final cuentas = await cargarCuentas();
    final movimientos = await cargarMovimientos();

    return {
      'formato': 'mis-finanzas-respaldo-v1',
      'exportado': DateTime.now().toIso8601String(),
      'cuentas': cuentas.map((e) => e.toJson()).toList(),
      'movimientos': movimientos.map((e) => e.toJson()).toList(),
    };
  }
}
