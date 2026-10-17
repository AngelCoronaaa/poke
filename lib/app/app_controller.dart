import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/region.dart';
import '../models/trainer.dart';
import '../services/auth_service.dart';

export '../services/auth_service.dart' show CuentaException;

/// Sesión del entrenador y aspecto elegido.
///
/// Las cuentas viven en PostgreSQL (a través de [AuthService]); en el
/// dispositivo solo se guarda el token de sesión, una copia del entrenador
/// para abrir la app al instante y el último nombre usado.
class AppController extends ChangeNotifier {
  AppController(this._prefs, this._auth) {
    // Datos de versiones anteriores, cuando las cuentas eran locales.
    for (final clave in ['trainer', 'cuentas', 'sesion']) {
      _prefs.remove(clave);
    }

    _token = _prefs.getString(_claveToken);
    final copia = _prefs.getString(_claveTrainer);
    if (_token != null && copia != null) {
      try {
        _trainer = Trainer.fromJson(jsonDecode(copia) as Map<String, dynamic>);
      } on FormatException {
        _token = null;
      }
    }

    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == _prefs.getString(_claveTema),
      orElse: () => ThemeMode.system,
    );
  }

  static const _claveToken = 'auth_token';
  static const _claveTrainer = 'auth_trainer';
  static const _claveUltimo = 'ultimo_entrenador';
  static const _claveTema = 'theme';

  final SharedPreferences _prefs;
  final AuthService _auth;
  String? _token;
  Trainer? _trainer;
  late ThemeMode _themeMode;

  Trainer? get trainer => _trainer;
  ThemeMode get themeMode => _themeMode;

  /// Último nombre con el que se entró en este dispositivo.
  String? get ultimoEntrenador => _prefs.getString(_claveUltimo);

  Future<void> setThemeMode(ThemeMode modo) async {
    if (modo == _themeMode) return;
    _themeMode = modo;
    notifyListeners();
    await _prefs.setString(_claveTema, modo.name);
  }

  /// Confirma con el servidor que la sesión guardada sigue vigente.
  /// Sin conexión se conserva la sesión; si expiró, se cierra.
  Future<void> validarSesion() async {
    final token = _token;
    if (token == null) return;
    try {
      final trainer = await _auth.validarSesion(token);
      if (token != _token) return; // la sesión cambió mientras tanto
      if (trainer == null) {
        await _limpiarSesion();
      } else {
        await _guardar(token, trainer);
      }
    } on CuentaException {
      // Sin servidor por ahora: se sigue con la copia local.
    }
  }

  Future<void> registrar({
    required String nombre,
    required String password,
    required Companero companero,
    required Region region,
  }) async {
    final sesion = await _auth.registrar(
      nombre: nombre.trim(),
      password: password,
      companero: companero,
      region: region,
    );
    await _guardar(sesion.token, sesion.trainer);
  }

  Future<void> iniciarSesion({
    required String nombre,
    required String password,
  }) async {
    final sesion = await _auth.iniciarSesion(
      nombre: nombre.trim(),
      password: password,
    );
    await _guardar(sesion.token, sesion.trainer);
  }

  Future<void> cerrarSesion() async {
    final token = _token;
    await _limpiarSesion();
    if (token != null) await _auth.cerrarSesion(token);
  }

  Future<void> _guardar(String token, Trainer trainer) async {
    _token = token;
    _trainer = trainer;
    notifyListeners();
    await _prefs.setString(_claveToken, token);
    await _prefs.setString(_claveTrainer, jsonEncode(trainer.toJson()));
    await _prefs.setString(_claveUltimo, trainer.nombre);
  }

  Future<void> _limpiarSesion() async {
    _token = null;
    _trainer = null;
    notifyListeners();
    await _prefs.remove(_claveToken);
    await _prefs.remove(_claveTrainer);
  }
}
