import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  static const String _keyUsers = 'users';
  static const String _keyCurrentUser = 'current_user_id';

  String _hash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<List<Map<String, dynamic>>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyUsers);
    if (jsonStr == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsers, jsonEncode(users));
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentUser);
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final uid = await getCurrentUserId();
    if (uid == null) return null;
    final users = await _getUsers();
    try {
      return users.firstWhere((u) => u['id'] == uid);
    } catch (_) {
      return null;
    }
  }

  Future<bool> existenUsuarios() async {
    final users = await _getUsers();
    return users.isNotEmpty;
  }

  /// Registrar el primer usuario (admin)
  Future<void> registrarPrimerUsuario({
    required String email,
    required String password,
    required String nombre,
  }) async {
    final users = await _getUsers();
    if (users.isNotEmpty) {
      throw Exception('Ya existen usuarios. Solo el administrador puede crear más.');
    }

    final nuevo = {
      'id': const Uuid().v4(),
      'email': email.trim().toLowerCase(),
      'nombre': nombre.trim(),
      'password': _hash(password),
      'rol': 'admin',
      'creado': DateTime.now().toIso8601String(),
    };

    await _saveUsers([nuevo]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUser, nuevo['id']);
  }

  /// Crear usuario (solo admin)
  Future<void> crearUsuario({
    required String email,
    required String password,
    required String nombre,
  }) async {
    final current = await getCurrentUser();
    if (current == null || current['rol'] != 'admin') {
      throw Exception('Solo el administrador puede crear usuarios');
    }

    final users = await _getUsers();
    if (users.any((u) => u['email'] == email.trim().toLowerCase())) {
      throw Exception('Ya existe un usuario con ese correo');
    }

    final nuevo = {
      'id': const Uuid().v4(),
      'email': email.trim().toLowerCase(),
      'nombre': nombre.trim(),
      'password': _hash(password),
      'rol': 'usuario',
      'creado': DateTime.now().toIso8601String(),
      'creadoPor': current['id'],
    };

    users.add(nuevo);
    await _saveUsers(users);
  }

  Future<void> login(String email, String password) async {
    final users = await _getUsers();
    final hash = _hash(password);

    Map<String, dynamic>? user;
    try {
      user = users.firstWhere(
        (u) => u['email'] == email.trim().toLowerCase() && u['password'] == hash,
      );
    } catch (_) {
      throw Exception('Correo o contraseña incorrectos');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUser, user['id']);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
  }

  Future<bool> esAdmin() async {
    final user = await getCurrentUser();
    return user?['rol'] == 'admin';
  }

  Future<List<Map<String, dynamic>>> listarUsuarios() async {
    return await _getUsers();
  }
}
