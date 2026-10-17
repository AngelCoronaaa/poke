import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_app/app/app_controller.dart';
import 'package:mi_app/main.dart';
import 'package:mi_app/models/pokeball_style.dart';
import 'package:mi_app/models/pokemon.dart';
import 'package:mi_app/models/region.dart';
import 'package:mi_app/models/trainer.dart';
import 'package:mi_app/models/resumen.dart';
import 'package:mi_app/services/auth_service.dart';
import 'package:mi_app/services/pokemon_service.dart';

Map<String, dynamic> _json(int id, String name, List<String> types) => {
  'id': id,
  'name': name,
  'height': 7,
  'weight': 69,
  'base_experience': 64,
  'types': [
    for (final t in types)
      {
        'type': {'name': t},
      },
  ],
  'stats': [
    {
      'base_stat': 45,
      'stat': {'name': 'hp'},
    },
    {
      'base_stat': 49,
      'stat': {'name': 'attack'},
    },
  ],
  'abilities': [
    {
      'ability': {'name': 'overgrow'},
      'is_hidden': false,
    },
    {
      'ability': {'name': 'chlorophyll'},
      'is_hidden': true,
    },
  ],
  'sprites': {
    'front_default': 'https://example.com/$id.png',
    'other': {
      'official-artwork': {
        'front_default': 'https://example.com/art/$id.png',
        'front_shiny': 'https://example.com/art/shiny/$id.png',
      },
    },
  },
};

class _FakeService extends PokemonService {
  final pedidos = <String>[];

  @override
  Future<Pokemon> getPokemon(String idOrName) async {
    pedidos.add(idOrName);
    return switch (idOrName) {
      '1' || 'bulbasaur' => Pokemon.fromJson(
        _json(1, 'bulbasaur', ['grass', 'poison']),
      ),
      '2' => Pokemon.fromJson(_json(2, 'ivysaur', ['grass', 'poison'])),
      '152' => Pokemon.fromJson(_json(152, 'chikorita', ['grass'])),
      'missingno' => throw const PokemonException('No encontramos ese Pokémon'),
      // El Pokémon del día depende de la fecha.
      _ => Pokemon.fromJson(
        _json(int.tryParse(idOrName) ?? 99, 'mew', ['psychic']),
      ),
    };
  }

  @override
  Future<ResumenPokedex> getResumen() async =>
      ResumenPokedex.fromCounts([1025, 937, 374, 2223, 9, 11]);

  @override
  Future<PokeballInfo> getPokeball(String slug) async => PokeballInfo(
    nombre: PokeballStyle.todas.firstWhere((s) => s.slug == slug).nombre,
    descripcion: 'Descripción de $slug desde la API.',
  );

  @override
  Future<bool> tieneModelo3D(int id) async => false;
}

/// Las animaciones (pokébolas, figuras) son infinitas: se avanza el tiempo
/// manualmente en lugar de usar pumpAndSettle.
Future<void> _esperar(WidgetTester tester, [int pasos = 12]) async {
  for (var i = 0; i < pasos; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Simula el servidor de cuentas (PostgreSQL) en memoria.
class _FakeAuth extends AuthService {
  _FakeAuth({bool conMisty = true}) {
    if (conMisty) {
      _cuentas['misty'] = ('agua123', _misty);
      _tokens['tok-misty'] = 'misty';
    }
  }

  final _cuentas = <String, (String, Trainer)>{};
  final _tokens = <String, String>{};
  final logouts = <String>[];

  bool existe(String usuario) => _cuentas.containsKey(usuario);

  @override
  Future<Sesion> registrar({
    required String nombre,
    required String password,
    required Companero companero,
    required Region region,
  }) async {
    final clave = nombre.toLowerCase();
    if (_cuentas.containsKey(clave)) {
      throw const CuentaException(
        'Ese nombre de entrenador ya está registrado',
      );
    }
    final trainer = Trainer(
      nombre: nombre,
      trainerId: '00001',
      companero: companero,
      region: region,
      desde: DateTime(2026, 10, 17),
    );
    _cuentas[clave] = (password, trainer);
    return _abrir(clave);
  }

  @override
  Future<Sesion> iniciarSesion({
    required String nombre,
    required String password,
  }) async {
    final cuenta = _cuentas[nombre.toLowerCase()];
    if (cuenta == null || cuenta.$1 != password) {
      throw const CuentaException('Nombre o contraseña incorrectos');
    }
    return _abrir(nombre.toLowerCase());
  }

  @override
  Future<Trainer?> validarSesion(String token) async {
    final usuario = _tokens[token];
    return usuario == null ? null : _cuentas[usuario]!.$2;
  }

  @override
  Future<void> cerrarSesion(String token) async {
    logouts.add(token);
    _tokens.remove(token);
  }

  Sesion _abrir(String usuario) {
    final token = 'tok-${_tokens.length + 1}';
    _tokens[token] = usuario;
    return (token: token, trainer: _cuentas[usuario]!.$2);
  }
}

final _misty = Trainer(
  nombre: 'Misty',
  trainerId: '04821',
  companero: Companero.porId(7),
  region: Region.porNombre('Kanto'),
  desde: DateTime(2026, 10, 1),
);

Future<(AppController, SharedPreferences)> _arrancar(
  WidgetTester tester, {
  Map<String, Object> guardado = const {},
  _FakeService? service,
  _FakeAuth? auth,
}) async {
  tester.view.physicalSize = const Size(430, 932) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(guardado);
  final prefs = await SharedPreferences.getInstance();
  final controller = AppController(prefs, auth ?? _FakeAuth());
  await controller.validarSesion();
  await tester.pumpWidget(
    PokedexApp(
      controller: controller,
      service: service ?? _FakeService(),
      modelos3D: false,
    ),
  );
  await _esperar(tester);
  return (controller, prefs);
}

/// La pantalla de inicio es una lista: desplaza hasta que aparezca [texto].
Future<void> _irA(WidgetTester tester, String texto) async {
  await tester.dragUntilVisible(
    find.text(texto),
    find.byType(ListView).first,
    const Offset(0, -250),
  );
  await tester.pump();
}

/// Hace scroll hasta el elemento (el formulario puede ser más alto que la
/// pantalla) y lo toca.
Future<void> _tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

/// Lo que queda guardado en el dispositivo tras entrar como Misty.
Map<String, Object> _cuentaMisty({bool sesionActiva = true}) => {
  'ultimo_entrenador': 'Misty',
  if (sesionActiva) ...{
    'auth_token': 'tok-misty',
    'auth_trainer': jsonEncode(_misty.toJson()),
  },
};

void main() {
  group('Modelos', () {
    test('Pokemon.fromJson convierte la respuesta de la API', () {
      final p = Pokemon.fromJson(_json(1, 'bulbasaur', ['grass', 'poison']));

      expect(p.displayName, 'Bulbasaur');
      expect(p.number, '#001');
      expect(p.heightMeters, 0.7);
      expect(p.weightKg, 6.9);
      expect(p.types.map((t) => t.label), ['Planta', 'Veneno']);
      expect(p.abilities.last.hidden, isTrue);
      expect(p.imageUrl, 'https://example.com/art/1.png');
    });

    test('PokeballInfo toma el nombre y la descripción en español', () {
      final info = PokeballInfo.fromJson({
        'name': 'great-ball',
        'names': [
          {
            'name': 'Great Ball',
            'language': {'name': 'en'},
          },
          {
            'name': 'Super Ball',
            'language': {'name': 'es'},
          },
        ],
        'flavor_text_entries': [
          {
            'text': 'Viejo texto',
            'language': {'name': 'es'},
          },
          {
            'text': 'Poké Ball de alto\nrendimiento.',
            'language': {'name': 'es'},
          },
        ],
        'sprites': {'default': 'https://example.com/great-ball.png'},
      });

      expect(info.nombre, 'Super Ball');
      expect(info.descripcion, 'Poké Ball de alto rendimiento.');
      expect(info.spriteUrl, 'https://example.com/great-ball.png');
    });
  });

  group('PokemonService (Dio simulado)', () {
    PokemonService servicioCon(
      void Function(RequestOptions, RequestInterceptorHandler) responder,
    ) {
      final dio = Dio(BaseOptions(baseUrl: 'https://pokeapi.co/api/v2/'))
        ..interceptors.add(InterceptorsWrapper(onRequest: responder));
      return PokemonService(dio: dio);
    }

    test('pide pokemon/<id>/ y guarda en caché', () async {
      final rutas = <String>[];
      final service = servicioCon((options, handler) {
        rutas.add(options.path);
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: _json(1, 'bulbasaur', ['grass']),
          ),
        );
      });

      await service.getPokemon('1');
      await service.getPokemon('Bulbasaur');
      expect(rutas, ['pokemon/1/']);
    });

    test('getResumen lee el campo count de cada recurso', () async {
      final rutas = <String>[];
      final service = servicioCon((options, handler) {
        rutas.add(options.path);
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'count': rutas.length * 10},
          ),
        );
      });

      final r = await service.getResumen();
      expect(rutas, ResumenPokedex.recursos.map((e) => '$e/'));
      expect(r.pokemon, greaterThan(0));
    });

    test('un 404 se traduce a un mensaje claro', () async {
      final service = servicioCon((options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 404),
          ),
        );
      });

      expect(
        () => service.getPokemon('missingno'),
        throwsA(
          isA<PokemonException>().having(
            (e) => e.message,
            'message',
            'No encontramos ese Pokémon',
          ),
        ),
      );
    });
  });

  testWidgets('Sin cuentas se muestra el registro, no un Pokémon', (
    tester,
  ) async {
    final service = _FakeService();
    await _arrancar(tester, service: service);

    expect(find.text('Crea tu cuenta de entrenador Pokémon'), findsOneWidget);
    expect(find.text('Crear cuenta y comenzar'), findsOneWidget);
    expect(service.pedidos, isEmpty);
  });

  testWidgets('El registro valida, guarda la cuenta y abre el inicio', (
    tester,
  ) async {
    final auth = _FakeAuth();
    final (controller, prefs) = await _arrancar(tester, auth: auth);
    final campos = find.byType(TextFormField);

    await _tocar(tester, find.text('Crear cuenta y comenzar'));
    await _esperar(tester, 2);
    expect(find.text('Escribe al menos 3 caracteres'), findsOneWidget);
    expect(find.text('Escribe tu contraseña'), findsOneWidget);

    await tester.enterText(campos.at(0), 'Ash');
    await tester.enterText(campos.at(1), 'pika');
    await tester.enterText(campos.at(2), 'otra');
    await _tocar(tester, find.text('Crear cuenta y comenzar'));
    await _esperar(tester, 2);
    expect(find.text('Usa al menos 6 caracteres'), findsOneWidget);
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);

    await tester.enterText(campos.at(1), 'pikachu');
    await tester.enterText(campos.at(2), 'pikachu');
    await _tocar(tester, find.text('Charmander'));
    await _tocar(tester, find.text('Johto'));
    await _tocar(tester, find.text('Crear cuenta y comenzar'));
    await _esperar(tester, 15);

    expect(find.text('¡Hola, Ash!'), findsOneWidget);
    expect(find.text('Entrenador de Johto'), findsOneWidget);
    expect(controller.trainer?.companero.nombre, 'Charmander');

    expect(auth.existe('ash'), isTrue); // la cuenta quedó en el servidor
    expect(prefs.getString('auth_token'), isNotNull);
    // En el dispositivo nunca se guarda la contraseña.
    for (final clave in prefs.getKeys()) {
      expect('${prefs.get(clave)}', isNot(contains('pikachu')));
    }
  });

  testWidgets('Iniciar sesión pide la contraseña correcta', (tester) async {
    await _arrancar(tester, guardado: _cuentaMisty(sesionActiva: false));
    final campos = find.byType(TextFormField);

    expect(find.text('Inicia sesión como entrenador Pokémon'), findsOneWidget);

    await tester.enterText(campos.at(0), 'Brock');
    await tester.enterText(campos.at(1), 'agua123');
    await _tocar(tester, find.text('Iniciar sesión').last);
    await _esperar(tester, 3);
    expect(find.text('Nombre o contraseña incorrectos'), findsOneWidget);

    await tester.enterText(campos.at(0), 'misty');
    await tester.enterText(campos.at(1), 'fuego99');
    await _tocar(tester, find.text('Iniciar sesión').last);
    await _esperar(tester, 3);
    expect(find.text('Nombre o contraseña incorrectos'), findsOneWidget);

    await tester.enterText(campos.at(1), 'agua123');
    await _tocar(tester, find.text('Iniciar sesión').last);
    await _esperar(tester, 15);
    expect(find.text('¡Hola, Misty!'), findsOneWidget);
    expect(find.text('04821'), findsOneWidget);
  });

  testWidgets('No se puede registrar un nombre que ya existe', (tester) async {
    await _arrancar(tester, guardado: _cuentaMisty(sesionActiva: false));
    final campos = find.byType(TextFormField);

    await tester.tap(find.text('Crear cuenta'));
    await _esperar(tester, 3);
    await tester.enterText(campos.at(0), 'MISTY');
    await tester.enterText(campos.at(1), 'otra123');
    await tester.enterText(campos.at(2), 'otra123');
    await _tocar(tester, find.text('Crear cuenta y comenzar'));
    await _esperar(tester, 3);

    expect(
      find.text('Ese nombre de entrenador ya está registrado'),
      findsOneWidget,
    );
  });

  testWidgets('Con sesión guardada abre el inicio con datos generales', (
    tester,
  ) async {
    await _arrancar(tester, guardado: _cuentaMisty());

    expect(find.text('¡Hola, Misty!'), findsOneWidget);
    expect(find.text('04821'), findsOneWidget);
    expect(find.text('Squirtle'), findsOneWidget);
    expect(find.text('1,025'), findsOneWidget);
    expect(find.text('2,223'), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
  });

  testWidgets('Desde el inicio se abre la Pokédex y se navega', (tester) async {
    final service = _FakeService();
    await _arrancar(tester, guardado: _cuentaMisty(), service: service);

    await _irA(tester, 'Pokédex');
    await tester.tap(find.text('Pokédex'));
    await _esperar(tester);

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Planta'), findsOneWidget);
    expect(find.text('0.7 m'), findsOneWidget);

    await tester.tap(find.byTooltip('Siguiente'));
    await _esperar(tester);
    expect(find.text('Ivysaur'), findsOneWidget);

    await tester.tap(find.byTooltip('Regresar'));
    await _esperar(tester);
    expect(find.text('Pokéballs 3D'), findsOneWidget); // de vuelta en inicio
  });

  testWidgets('Una región abre la Pokédex en su primer Pokémon', (
    tester,
  ) async {
    final service = _FakeService();
    await _arrancar(tester, guardado: _cuentaMisty(), service: service);

    await _irA(tester, 'Johto');
    await _tocar(tester, find.text('Johto'));
    await _esperar(tester);

    expect(service.pedidos.last, '152');
    expect(find.text('Chikorita'), findsOneWidget);
  });

  testWidgets('La galería de pokébolas cambia de tipo y muestra la API', (
    tester,
  ) async {
    await _arrancar(tester, guardado: _cuentaMisty());

    await _irA(tester, 'Pokéballs 3D');
    await tester.tap(find.text('Pokéballs 3D'));
    await _esperar(tester);
    expect(find.text('Poké Ball'), findsOneWidget);
    expect(find.text('Descripción de poke-ball desde la API.'), findsOneWidget);

    await tester.tap(find.byTooltip('Ultra Ball'));
    await _esperar(tester);
    expect(find.text('Ultra Ball'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);

    await tester.tap(find.byTooltip('Siguiente'));
    await _esperar(tester);
    expect(find.text('Master Ball'), findsOneWidget);
    expect(find.text('Infalible'), findsOneWidget);
  });

  testWidgets('El aspecto elegido se guarda', (tester) async {
    final (controller, prefs) = await _arrancar(
      tester,
      guardado: _cuentaMisty(),
    );

    await tester.tap(find.byTooltip('Aspecto'));
    await _esperar(tester, 4);
    await tester.tap(find.text('Oscuro'));
    await _esperar(tester, 4);

    expect(controller.themeMode, ThemeMode.dark);
    expect(prefs.getString('theme'), 'dark');
    final ctx = tester.element(find.text('¡Hola, Misty!'));
    expect(Theme.of(ctx).brightness, Brightness.dark);
  });

  testWidgets('Cerrar sesión conserva la cuenta para volver a entrar', (
    tester,
  ) async {
    final auth = _FakeAuth();
    final (_, prefs) = await _arrancar(
      tester,
      guardado: _cuentaMisty(),
      auth: auth,
    );

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await _esperar(tester, 3);
    await tester.tap(find.text('Cerrar sesión').last);
    await _esperar(tester, 8);

    expect(find.text('Inicia sesión como entrenador Pokémon'), findsOneWidget);
    expect(prefs.getString('auth_token'), isNull);
    expect(auth.logouts, ['tok-misty']);
    expect(auth.existe('misty'), isTrue);
    // El nombre queda escrito para volver a entrar.
    expect(find.widgetWithText(TextFormField, 'Misty'), findsOneWidget);
  });

  testWidgets('Una sesión expirada en el servidor regresa al login', (
    tester,
  ) async {
    await _arrancar(
      tester,
      guardado: {..._cuentaMisty(), 'auth_token': 'tok-vencido'},
    );

    expect(find.text('Inicia sesión como entrenador Pokémon'), findsOneWidget);
    expect(find.text('¡Hola, Misty!'), findsNothing);
  });
}
