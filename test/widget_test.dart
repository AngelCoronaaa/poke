import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_app/app/app_controller.dart';
import 'package:mi_app/main.dart';
import 'package:mi_app/models/pokeball_style.dart';
import 'package:mi_app/models/pokemon.dart';
import 'package:mi_app/models/resumen.dart';
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

Future<(AppController, SharedPreferences)> _arrancar(
  WidgetTester tester, {
  Map<String, Object> guardado = const {},
  _FakeService? service,
}) async {
  tester.view.physicalSize = const Size(430, 932) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(guardado);
  final prefs = await SharedPreferences.getInstance();
  final controller = AppController(prefs);
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

final _sesionGuardada = {
  'trainer': jsonEncode({
    'nombre': 'Misty',
    'trainerId': '04821',
    'companero': 7,
    'region': 'Kanto',
    'desde': '2026-10-01T10:00:00.000',
  }),
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

  testWidgets('Sin sesión se muestra el login, no un Pokémon', (tester) async {
    final service = _FakeService();
    await _arrancar(tester, service: service);

    expect(find.text('Inicia sesión como entrenador Pokémon'), findsOneWidget);
    expect(find.text('Comenzar aventura'), findsOneWidget);
    expect(service.pedidos, isEmpty);
  });

  testWidgets('Login valida el nombre y abre la pantalla de inicio', (
    tester,
  ) async {
    final (controller, prefs) = await _arrancar(tester);

    await tester.tap(find.text('Comenzar aventura'));
    await _esperar(tester, 2);
    expect(find.text('Escribe al menos 3 caracteres'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Ash');
    await tester.tap(find.text('Charmander'));
    await tester.tap(find.text('Johto'));
    await tester.tap(find.text('Comenzar aventura'));
    await _esperar(tester, 15);

    expect(find.text('¡Hola, Ash!'), findsOneWidget);
    expect(find.text('Entrenador de Johto'), findsOneWidget);
    expect(find.text('LICENCIA DE ENTRENADOR'), findsOneWidget);
    expect(controller.trainer?.companero.nombre, 'Charmander');
    expect(prefs.getString('trainer'), contains('"nombre":"Ash"'));
  });

  testWidgets('Con sesión guardada abre el inicio con datos generales', (
    tester,
  ) async {
    await _arrancar(tester, guardado: _sesionGuardada);

    expect(find.text('¡Hola, Misty!'), findsOneWidget);
    expect(find.text('04821'), findsOneWidget);
    expect(find.text('Squirtle'), findsOneWidget);
    expect(find.text('1,025'), findsOneWidget);
    expect(find.text('2,223'), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
  });

  testWidgets('Desde el inicio se abre la Pokédex y se navega', (tester) async {
    final service = _FakeService();
    await _arrancar(tester, guardado: _sesionGuardada, service: service);

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
    await _arrancar(tester, guardado: _sesionGuardada, service: service);

    await _irA(tester, 'Johto');
    await tester.tap(find.text('Johto'));
    await _esperar(tester);

    expect(service.pedidos.last, '152');
    expect(find.text('Chikorita'), findsOneWidget);
  });

  testWidgets('La galería de pokébolas cambia de tipo y muestra la API', (
    tester,
  ) async {
    await _arrancar(tester, guardado: _sesionGuardada);

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
      guardado: _sesionGuardada,
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

  testWidgets('Cerrar sesión regresa al login', (tester) async {
    final (_, prefs) = await _arrancar(tester, guardado: _sesionGuardada);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await _esperar(tester, 3);
    await tester.tap(find.text('Cerrar sesión').last);
    await _esperar(tester, 8);

    expect(find.text('Comenzar aventura'), findsOneWidget);
    expect(prefs.getString('trainer'), isNull);
  });
}
