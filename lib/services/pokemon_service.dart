import 'package:dio/dio.dart';

import '../models/pokeball_style.dart';
import '../models/pokemon.dart';
import '../models/resumen.dart';

class PokemonException implements Exception {
  final String message;
  const PokemonException(this.message);

  @override
  String toString() => message;
}

/// Realiza las peticiones de red a la PokeAPI usando Dio.
class PokemonService {
  PokemonService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://pokeapi.co/api/v2/',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  /// Pokémon disponibles en la Pokédex nacional.
  static const total = 1025;

  /// Modelos 3D (.glb) del proyecto Pokemon-3D-api (licencia MIT).
  static String modelo3DUrl(int id) =>
      'https://raw.githubusercontent.com/Pokemon-3D-api/assets/main/models/opt/regular/$id.glb';

  final Dio _dio;
  final Map<String, Pokemon> _cache = {};
  final Map<String, PokeballInfo> _cachePokeballs = {};
  final Map<int, bool> _cacheModelos = {};
  ResumenPokedex? _resumen;
  List<PokemonResumen>? _lista;
  Map<int, List<PokemonType>>? _tipos;

  /// Obtiene un Pokémon por número o por nombre,
  /// p. ej. `https://pokeapi.co/api/v2/pokemon/1/`.
  Future<Pokemon> getPokemon(String idOrName) async {
    final clave = idOrName.trim().toLowerCase();
    final enCache = _cache[clave];
    if (enCache != null) return enCache;

    final pokemon = await _ejecutar(() async {
      final response = await _dio.get<Map<String, dynamic>>('pokemon/$clave/');
      return Pokemon.fromJson(response.data!);
    });
    _cache['${pokemon.id}'] = pokemon;
    _cache[pokemon.name] = pokemon;
    return pokemon;
  }

  /// Número y nombre de todos los Pokémon, en una sola petición.
  Future<List<PokemonResumen>> getLista() async {
    final enCache = _lista;
    if (enCache != null) return enCache;
    final lista = await _ejecutar(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        'pokemon-species/',
        queryParameters: {'limit': total},
      );
      return (response.data!['results'] as List)
          .map((e) => PokemonResumen.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
    });
    return _lista = lista;
  }

  /// Tipos de cada Pokémon (por número), armados con 18 peticiones
  /// `type/<tipo>/` en lugar de una por Pokémon.
  Future<Map<int, List<PokemonType>>> getTipos() async {
    final enCache = _tipos;
    if (enCache != null) return enCache;
    final tipos = await _ejecutar(() async {
      final porId = <int, List<(int, PokemonType)>>{};
      await Future.wait(
        PokemonType.todos.map((tipo) async {
          final response = await _dio.get<Map<String, dynamic>>(
            'type/${tipo.name}/',
          );
          for (final entrada in response.data!['pokemon'] as List) {
            final resumen = PokemonResumen.fromJson(
              entrada['pokemon'] as Map<String, dynamic>,
            );
            // Las formas alternativas tienen números arriba de 10000.
            if (resumen.id > total) continue;
            porId.putIfAbsent(resumen.id, () => []).add((
              entrada['slot'] as int,
              tipo,
            ));
          }
        }),
      );
      return porId.map(
        (id, lista) => MapEntry(
          id,
          (lista..sort((a, b) => a.$1.compareTo(b.$1)))
              .map((e) => e.$2)
              .toList(),
        ),
      );
    });
    return _tipos = tipos;
  }

  /// Conteos generales (Pokémon, movimientos, habilidades…) pedidos en paralelo.
  Future<ResumenPokedex> getResumen() async {
    final enCache = _resumen;
    if (enCache != null) return enCache;
    final resumen = await _ejecutar(() async {
      final conteos = await Future.wait(
        ResumenPokedex.recursos.map((recurso) async {
          final response = await _dio.get<Map<String, dynamic>>(
            '$recurso/',
            queryParameters: {'limit': 1},
          );
          return response.data!['count'] as int;
        }),
      );
      return ResumenPokedex.fromCounts(conteos);
    });
    return _resumen = resumen;
  }

  /// Nombre y descripción oficiales en español de una pokébola.
  Future<PokeballInfo> getPokeball(String slug) async {
    final enCache = _cachePokeballs[slug];
    if (enCache != null) return enCache;

    return _cachePokeballs[slug] = await _ejecutar(() async {
      final response = await _dio.get<Map<String, dynamic>>('item/$slug/');
      return PokeballInfo.fromJson(response.data!);
    });
  }

  /// Comprueba (con una petición HEAD) si existe modelo 3D para el Pokémon.
  Future<bool> tieneModelo3D(int id) async {
    final enCache = _cacheModelos[id];
    if (enCache != null) return enCache;
    try {
      final response = await _dio.head<void>(
        modelo3DUrl(id),
        options: Options(validateStatus: (_) => true),
      );
      return _cacheModelos[id] = response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<T> _ejecutar<T>(Future<T> Function() peticion) async {
    try {
      return await peticion();
    } on DioException catch (e) {
      throw PokemonException(_mensaje(e));
    }
  }

  String _mensaje(DioException e) {
    if (e.response?.statusCode == 404) {
      return 'No encontramos ese Pokémon';
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => 'La conexión tardó demasiado',
      DioExceptionType.connectionError => 'Sin conexión a internet',
      _ => 'Ocurrió un error al consultar la PokeAPI',
    };
  }
}
