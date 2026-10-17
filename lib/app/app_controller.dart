import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/region.dart';
import '../models/trainer.dart';

/// Sesión del entrenador y aspecto elegido, guardados en el dispositivo.
class AppController extends ChangeNotifier {
  AppController(this._prefs) {
    final guardado = _prefs.getString(_claveTrainer);
    if (guardado != null) {
      try {
        _trainer = Trainer.fromJson(
          jsonDecode(guardado) as Map<String, dynamic>,
        );
      } on FormatException {
        _prefs.remove(_claveTrainer);
      }
    }
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == _prefs.getString(_claveTema),
      orElse: () => ThemeMode.system,
    );
  }

  static const _claveTrainer = 'trainer';
  static const _claveTema = 'theme';

  final SharedPreferences _prefs;
  Trainer? _trainer;
  late ThemeMode _themeMode;

  Trainer? get trainer => _trainer;
  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode modo) async {
    if (modo == _themeMode) return;
    _themeMode = modo;
    notifyListeners();
    await _prefs.setString(_claveTema, modo.name);
  }

  Future<void> iniciarSesion({
    required String nombre,
    required Companero companero,
    required Region region,
  }) async {
    final trainer = Trainer(
      nombre: nombre.trim(),
      trainerId: math.Random().nextInt(100000).toString().padLeft(5, '0'),
      companero: companero,
      region: region,
      desde: DateTime.now(),
    );
    await _prefs.setString(_claveTrainer, jsonEncode(trainer.toJson()));
    _trainer = trainer;
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    await _prefs.remove(_claveTrainer);
    _trainer = null;
    notifyListeners();
  }
}
