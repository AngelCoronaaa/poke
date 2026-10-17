import 'dart:convert';

import 'package:pokedex_server/api.dart';
import 'package:pokedex_server/repositorio_memoria.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late RepositorioMemoria repo;
  late Handler api;

  setUp(() {
    repo = RepositorioMemoria();
    api = crearHandler(repo, rondasBcrypt: 4);
  });

  Future<(int, Map<String, dynamic>)> post(
    String ruta,
    Object body, {
    String? token,
  }) async {
    final r = await api(
      Request(
        'POST',
        Uri.parse('http://localhost$ruta'),
        body: jsonEncode(body),
        headers: {if (token != null) 'authorization': 'Bearer $token'},
      ),
    );
    final texto = await r.readAsString();
    return (
      r.statusCode,
      texto.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(texto) as Map<String, dynamic>,
    );
  }

  Future<(int, Map<String, dynamic>)> get(String ruta, {String? token}) async {
    final r = await api(
      Request(
        'GET',
        Uri.parse('http://localhost$ruta'),
        headers: {if (token != null) 'authorization': 'Bearer $token'},
      ),
    );
    return (
      r.statusCode,
      jsonDecode(await r.readAsString()) as Map<String, dynamic>,
    );
  }

  const misty = {
    'nombre': 'Misty',
    'password': 'agua123',
    'companero': 7,
    'region': 'Kanto',
  };

  test('registro guarda el entrenador con la contraseña en bcrypt', () async {
    final (status, body) = await post('/api/registro', misty);

    expect(status, 201);
    expect(body['token'], isA<String>());
    expect(body['trainer']['nombre'], 'Misty');
    expect(body['trainer']['companero'], 7);
    expect(body['trainer']['trainerId'], hasLength(5));
    expect(body['trainer'], isNot(contains('passwordHash')));

    final guardado = repo.entrenadores.single;
    expect(guardado.usuario, 'misty');
    expect(guardado.passwordHash, startsWith(r'$2'));
    expect(guardado.passwordHash, isNot(contains('agua123')));
  });

  test('no permite nombres repetidos sin importar mayúsculas', () async {
    await post('/api/registro', misty);
    final (status, body) = await post('/api/registro', {
      ...misty,
      'nombre': '  MISTY ',
    });

    expect(status, 409);
    expect(body['error'], 'Ese nombre de entrenador ya está registrado');
    expect(repo.totalEntrenadores, 1);
  });

  test('valida los datos del registro', () async {
    expect((await post('/api/registro', {...misty, 'nombre': 'Al'})).$1, 400);
    expect(
      (await post('/api/registro', {...misty, 'password': '123'})).$1,
      400,
    );
    expect((await post('/api/registro', {...misty, 'companero': 150})).$1, 400);
    expect((await post('/api/registro', {...misty, 'region': 'Orre'})).$1, 400);
    expect(repo.totalEntrenadores, 0);
  });

  test('login con contraseña correcta e incorrecta', () async {
    await post('/api/registro', misty);

    final (ok, body) = await post('/api/login', {
      'nombre': 'misty',
      'password': 'agua123',
    });
    expect(ok, 200);
    expect(body['trainer']['nombre'], 'Misty');

    final (mal, error) = await post('/api/login', {
      'nombre': 'Misty',
      'password': 'fuego',
    });
    expect(mal, 401);
    expect(error['error'], 'Nombre o contraseña incorrectos');

    final (noExiste, _) = await post('/api/login', {
      'nombre': 'Brock',
      'password': 'agua123',
    });
    expect(noExiste, 401);
  });

  test('la sesión se valida con el token y se cierra con logout', () async {
    final (_, registro) = await post('/api/registro', misty);
    final token = registro['token'] as String;

    final (ok, sesion) = await get('/api/sesion', token: token);
    expect(ok, 200);
    expect(sesion['trainer']['nombre'], 'Misty');

    expect((await get('/api/sesion', token: 'inventado')).$1, 401);
    expect((await get('/api/sesion')).$1, 401);

    expect((await post('/api/logout', {}, token: token)).$1, 204);
    expect((await get('/api/sesion', token: token)).$1, 401);
  });
}
