import 'package:flutter/material.dart';

import 'pokemon.dart';
import 'region.dart';

/// Pokémon que el entrenador puede elegir como compañero al iniciar sesión.
class Companero {
  final int id;
  final String nombre;
  final PokemonType tipo;

  Companero(this.id, this.nombre, String tipo)
    : tipo = PokemonType.fromName(tipo);

  Color get color => tipo.color;

  String get imagenUrl => Pokemon.artworkUrl(id);

  static final todos = [
    Companero(25, 'Pikachu', 'electric'),
    Companero(1, 'Bulbasaur', 'grass'),
    Companero(4, 'Charmander', 'fire'),
    Companero(7, 'Squirtle', 'water'),
    Companero(133, 'Eevee', 'normal'),
    Companero(448, 'Lucario', 'fighting'),
  ];

  static Companero porId(int id) =>
      todos.firstWhere((c) => c.id == id, orElse: () => todos.first);
}

class Trainer {
  final String nombre;
  final String trainerId;
  final Companero companero;
  final Region region;
  final DateTime desde;

  const Trainer({
    required this.nombre,
    required this.trainerId,
    required this.companero,
    required this.region,
    required this.desde,
  });

  factory Trainer.fromJson(Map<String, dynamic> json) => Trainer(
    nombre: json['nombre'] as String,
    trainerId: json['trainerId'] as String,
    companero: Companero.porId(json['companero'] as int),
    region: Region.porNombre(json['region'] as String),
    desde: DateTime.parse(json['desde'] as String),
  );

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'trainerId': trainerId,
    'companero': companero.id,
    'region': region.nombre,
    'desde': desde.toIso8601String(),
  };
}
