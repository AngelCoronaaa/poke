import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/region.dart';
import '../models/trainer.dart';

/// Error de registro o inicio de sesión, con un mensaje para mostrar.
class CuentaException implements Exception {
  final String message;
  const CuentaException(this.message);

  @override
  String toString() => message;
}

/// Respuesta del servidor al registrarse o iniciar sesión.
typedef Sesion = ({String token, Trainer trainer});

/// Cuentas de entrenador en el servidor propio (PostgreSQL).
///
/// La dirección se configura con `--dart-define=API_URL=https://...`. Si no
/// se indica: en web se usa el mismo dominio desde el que se sirve la app y,
/// en el emulador de Android, la computadora local (`10.0.2.2`).
class AuthService {
  AuthService({Dio? dio, String? baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? urlPorDefecto,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              contentType: Headers.jsonContentType,
            ),
          );

  final Dio _dio;

  static String get urlPorDefecto {
    const configurada = String.fromEnvironment('API_URL');
    if (configurada.isNotEmpty) return configurada;
    if (kIsWeb) return Uri.base.origin;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  Future<Sesion> registrar({
    required String nombre,
    required String password,
    required Companero companero,
    required Region region,
  }) => _sesion('/api/registro', {
    'nombre': nombre,
    'password': password,
    'companero': companero.id,
    'region': region.nombre,
  });

  Future<Sesion> iniciarSesion({
    required String nombre,
    required String password,
  }) => _sesion('/api/login', {'nombre': nombre, 'password': password});

  /// Devuelve el entrenador si el token sigue siendo válido, o `null` si
  /// expiró. Lanza [CuentaException] si no hay conexión.
  Future<Trainer?> validarSesion(String token) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '/api/sesion',
        options: _auth(token),
      );
      return Trainer.fromJson(r.data!['trainer'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      throw CuentaException(_mensaje(e));
    }
  }

  Future<void> cerrarSesion(String token) async {
    try {
      await _dio.post<void>('/api/logout', options: _auth(token));
    } on DioException {
      // Sin conexión: la sesión expira sola en el servidor.
    }
  }

  Future<Sesion> _sesion(String ruta, Map<String, dynamic> datos) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(ruta, data: datos);
      return (
        token: r.data!['token'] as String,
        trainer: Trainer.fromJson(r.data!['trainer'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw CuentaException(_mensaje(e));
    }
  }

  Options _auth(String token) =>
      Options(headers: {'authorization': 'Bearer $token'});

  String _mensaje(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => 'El servidor tardó demasiado',
      DioExceptionType.connectionError => 'No se pudo conectar con el servidor',
      _ => 'Ocurrió un error con el servidor',
    };
  }
}
