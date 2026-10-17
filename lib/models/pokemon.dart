import 'package:flutter/material.dart';

/// Clase personalizada en la que se convierte la respuesta JSON de la PokeAPI.
class Pokemon {
  final int id;
  final String name;
  final int height; // decímetros
  final int weight; // hectogramos
  final int? baseExperience;
  final List<PokemonType> types;
  final List<PokemonStat> stats;
  final List<PokemonAbility> abilities;
  final String? imageUrl;
  final String? shinyImageUrl;

  const Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.baseExperience,
    required this.types,
    required this.stats,
    required this.abilities,
    required this.imageUrl,
    required this.shinyImageUrl,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final sprites = json['sprites'] as Map<String, dynamic>? ?? {};
    final other = sprites['other'] as Map<String, dynamic>? ?? {};
    final artwork = other['official-artwork'] as Map<String, dynamic>? ?? {};

    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      height: json['height'] as int? ?? 0,
      weight: json['weight'] as int? ?? 0,
      baseExperience: json['base_experience'] as int?,
      types: (json['types'] as List? ?? [])
          .map((t) => PokemonType.fromName(t['type']['name'] as String))
          .toList(),
      stats: (json['stats'] as List? ?? [])
          .map((s) => PokemonStat.fromJson(s as Map<String, dynamic>))
          .toList(),
      abilities: (json['abilities'] as List? ?? [])
          .map((a) => PokemonAbility.fromJson(a as Map<String, dynamic>))
          .toList(),
      imageUrl:
          artwork['front_default'] as String? ??
          sprites['front_default'] as String?,
      shinyImageUrl:
          artwork['front_shiny'] as String? ??
          sprites['front_shiny'] as String?,
    );
  }

  static String artworkUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String get displayName => _capitalizar(name.replaceAll('-', ' '));

  String get number => '#${id.toString().padLeft(3, '0')}';

  double get heightMeters => height / 10;

  double get weightKg => weight / 10;

  Color get color =>
      types.isNotEmpty ? types.first.color : PokemonType.fallbackColor;
}

class PokemonStat {
  final String name;
  final int value;

  const PokemonStat({required this.name, required this.value});

  factory PokemonStat.fromJson(Map<String, dynamic> json) => PokemonStat(
    name: json['stat']['name'] as String,
    value: json['base_stat'] as int,
  );

  static const maxValue = 255;

  String get label =>
      const {
        'hp': 'PS',
        'attack': 'Ataque',
        'defense': 'Defensa',
        'special-attack': 'At. Esp.',
        'special-defense': 'Def. Esp.',
        'speed': 'Velocidad',
      }[name] ??
      _capitalizar(name);
}

class PokemonAbility {
  final String name;
  final bool hidden;

  const PokemonAbility({required this.name, required this.hidden});

  factory PokemonAbility.fromJson(Map<String, dynamic> json) => PokemonAbility(
    name: json['ability']['name'] as String,
    hidden: json['is_hidden'] as bool? ?? false,
  );

  String get displayName => _capitalizar(name.replaceAll('-', ' '));
}

class PokemonType {
  final String name;
  final String label;
  final Color color;

  const PokemonType._(this.name, this.label, this.color);

  static const fallbackColor = Color(0xFF8A8FA3);

  static const _tipos = {
    'normal': PokemonType._('normal', 'Normal', Color(0xFFA8A77A)),
    'fire': PokemonType._('fire', 'Fuego', Color(0xFFF08030)),
    'water': PokemonType._('water', 'Agua', Color(0xFF6390F0)),
    'electric': PokemonType._('electric', 'Eléctrico', Color(0xFFF7D02C)),
    'grass': PokemonType._('grass', 'Planta', Color(0xFF5FBD58)),
    'ice': PokemonType._('ice', 'Hielo', Color(0xFF96D9D6)),
    'fighting': PokemonType._('fighting', 'Lucha', Color(0xFFC22E28)),
    'poison': PokemonType._('poison', 'Veneno', Color(0xFFA33EA1)),
    'ground': PokemonType._('ground', 'Tierra', Color(0xFFE2BF65)),
    'flying': PokemonType._('flying', 'Volador', Color(0xFFA98FF3)),
    'psychic': PokemonType._('psychic', 'Psíquico', Color(0xFFF95587)),
    'bug': PokemonType._('bug', 'Bicho', Color(0xFFA6B91A)),
    'rock': PokemonType._('rock', 'Roca', Color(0xFFB6A136)),
    'ghost': PokemonType._('ghost', 'Fantasma', Color(0xFF735797)),
    'dragon': PokemonType._('dragon', 'Dragón', Color(0xFF6F35FC)),
    'dark': PokemonType._('dark', 'Siniestro', Color(0xFF705746)),
    'steel': PokemonType._('steel', 'Acero', Color(0xFFB7B7CE)),
    'fairy': PokemonType._('fairy', 'Hada', Color(0xFFD685AD)),
  };

  factory PokemonType.fromName(String name) =>
      _tipos[name] ?? PokemonType._(name, _capitalizar(name), fallbackColor);
}

String _capitalizar(String texto) => texto
    .split(' ')
    .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
    .join(' ');
