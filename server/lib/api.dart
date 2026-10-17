import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import 'repositorio.dart';

/// Mismos compañeros y regiones que ofrece la app.
const companerosValidos = {25, 1, 4, 7, 133, 448};
const regionesValidas = {
  'Kanto', 'Johto', 'Hoenn', 'Sinnoh', 'Teselia', //
  'Kalos', 'Alola', 'Galar', 'Paldea',
};

const duracionSesion = Duration(days: 30);

/// API de cuentas de entrenador:
///
/// - `POST /api/registro` `{nombre, password, companero, region}` → 201 `{token, trainer}`
/// - `POST /api/login`    `{nombre, password}`                     → 200 `{token, trainer}`
/// - `GET  /api/sesion`   (Authorization: Bearer)                 → 200 `{trainer}`
/// - `POST /api/logout`   (Authorization: Bearer)                 → 204
/// - `GET  /health`                                               → 200
///
/// Si existe [carpetaWeb], también sirve la app compilada para web.
Handler crearHandler(
  Repositorio repo, {
  String? carpetaWeb,
  int rondasBcrypt = 11,
}) {
  final random = Random.secure();
  // Hash de relleno para que un usuario inexistente tarde lo mismo que uno real.
  final hashFicticio = BCrypt.hashpw(
    'ficticio',
    BCrypt.gensalt(logRounds: rondasBcrypt),
  );

  Future<Response> abrirSesion(Entrenador e, {int status = 200}) async {
    final token = base64Url.encode(
      List.generate(32, (_) => random.nextInt(256)),
    );
    await repo.crearSesion(
      tokenHash: _sha256(token),
      entrenadorId: e.id,
      expira: DateTime.now().add(duracionSesion),
    );
    return _json(status, {'token': token, 'trainer': e.toJson()});
  }

  final router = Router()
    ..get('/health', (Request _) => Response.ok('ok'))
    ..post('/api/registro', (Request request) async {
      final body = await _leerJson(request);
      if (body == null) return _error(400, 'Solicitud inválida');

      final nombre = _limpiar(body['nombre']);
      final password = body['password'];
      final companero = body['companero'];
      final region = body['region'];

      final problema =
          _validarNombre(nombre) ??
          (password is! String || password.length < 6
              ? 'La contraseña debe tener al menos 6 caracteres'
              : null) ??
          (utf8.encode(password as String).length > 72
              ? 'La contraseña es demasiado larga'
              : null) ??
          (!companerosValidos.contains(companero)
              ? 'Compañero inválido'
              : null) ??
          (!regionesValidas.contains(region) ? 'Región inválida' : null);
      if (problema != null) return _error(400, problema);

      try {
        final entrenador = await repo.crearEntrenador(
          usuario: nombre.toLowerCase(),
          nombre: nombre,
          passwordHash: BCrypt.hashpw(
            password,
            BCrypt.gensalt(logRounds: rondasBcrypt),
          ),
          trainerId: random.nextInt(100000).toString().padLeft(5, '0'),
          companero: companero as int,
          region: region as String,
        );
        return await abrirSesion(entrenador, status: 201);
      } on UsuarioDuplicado {
        return _error(409, 'Ese nombre de entrenador ya está registrado');
      }
    })
    ..post('/api/login', (Request request) async {
      final body = await _leerJson(request);
      final nombre = _limpiar(body?['nombre']);
      final password = body?['password'];
      if (nombre.isEmpty || password is! String) {
        return _error(400, 'Escribe tu nombre y contraseña');
      }

      final entrenador = await repo.buscarPorUsuario(nombre.toLowerCase());
      final valida = BCrypt.checkpw(
        password,
        entrenador?.passwordHash ?? hashFicticio,
      );
      if (entrenador == null || !valida) {
        return _error(401, 'Nombre o contraseña incorrectos');
      }
      return abrirSesion(entrenador);
    })
    ..get('/api/sesion', (Request request) async {
      final token = _token(request);
      final entrenador = token == null
          ? null
          : await repo.entrenadorDeSesion(_sha256(token));
      if (entrenador == null) return _error(401, 'Sesión expirada');
      return _json(200, {'trainer': entrenador.toJson()});
    })
    ..post('/api/logout', (Request request) async {
      final token = _token(request);
      if (token != null) await repo.borrarSesion(_sha256(token));
      return Response(204);
    });

  var cascade = Cascade().add(router.call);
  if (carpetaWeb != null && Directory(carpetaWeb).existsSync()) {
    cascade = cascade.add(
      createStaticHandler(carpetaWeb, defaultDocument: 'index.html'),
    );
  }

  return const Pipeline()
      .addMiddleware(_cors())
      .addMiddleware(_errores())
      .addHandler(cascade.handler);
}

String _sha256(String valor) => sha256.convert(utf8.encode(valor)).toString();

String _limpiar(Object? valor) =>
    valor is String ? valor.trim().replaceAll(RegExp(r'\s+'), ' ') : '';

String? _validarNombre(String nombre) {
  if (nombre.length < 3 || nombre.length > 12) {
    return 'El nombre debe tener entre 3 y 12 caracteres';
  }
  if (!RegExp(r"^[\p{L}\p{N} .'-]+$", unicode: true).hasMatch(nombre)) {
    return 'Usa solo letras, números y espacios';
  }
  return null;
}

String? _token(Request request) {
  final header = request.headers['authorization'];
  if (header == null || !header.startsWith('Bearer ')) return null;
  final token = header.substring(7).trim();
  return token.isEmpty ? null : token;
}

Future<Map<String, dynamic>?> _leerJson(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString());
    return body is Map<String, dynamic> ? body : null;
  } on FormatException {
    return null;
  }
}

Response _json(int status, Object body) => Response(
  status,
  body: jsonEncode(body),
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Response _error(int status, String mensaje) =>
    _json(status, {'error': mensaje});

/// La app usa tokens en el encabezado (no cookies), así que se permite
/// cualquier origen; útil al desarrollar la versión web en otro puerto.
Middleware _cors() {
  const headers = {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, POST, OPTIONS',
    'access-control-allow-headers': 'authorization, content-type',
  };
  return (inner) => (request) async {
    if (request.method == 'OPTIONS') return Response(204, headers: headers);
    final response = await inner(request);
    return response.change(headers: headers);
  };
}

Middleware _errores() =>
    (inner) => (request) async {
      try {
        return await inner(request);
      } catch (e, st) {
        stderr.writeln('Error en ${request.method} ${request.url}: $e\n$st');
        return _error(500, 'Error interno del servidor');
      }
    };
