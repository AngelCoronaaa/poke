import 'package:flutter/material.dart';

/// Región principal de cada generación y su rango en la Pokédex nacional.
class Region {
  final String nombre;
  final String generacion;
  final int primero;
  final int ultimo;
  final Color color;

  const Region(
    this.nombre,
    this.generacion,
    this.primero,
    this.ultimo,
    this.color,
  );

  int get total => ultimo - primero + 1;

  String get rango =>
      '#${primero.toString().padLeft(3, '0')} – #${ultimo.toString().padLeft(3, '0')}';

  static const todas = [
    Region('Kanto', 'I', 1, 151, Color(0xFFE3350D)),
    Region('Johto', 'II', 152, 251, Color(0xFFC9A227)),
    Region('Hoenn', 'III', 252, 386, Color(0xFF2E9E6A)),
    Region('Sinnoh', 'IV', 387, 493, Color(0xFF6C63C7)),
    Region('Teselia', 'V', 494, 649, Color(0xFF4B5563)),
    Region('Kalos', 'VI', 650, 721, Color(0xFF2F6BDB)),
    Region('Alola', 'VII', 722, 809, Color(0xFFF08A24)),
    Region('Galar', 'VIII', 810, 905, Color(0xFFB0306A)),
    Region('Paldea', 'IX', 906, 1025, Color(0xFF8E3FC0)),
  ];

  static Region porNombre(String nombre) =>
      todas.firstWhere((r) => r.nombre == nombre, orElse: () => todas.first);
}
