import 'package:flutter/material.dart';

/// Patrón que dibuja el shader sobre la mitad superior.
/// El orden importa: el índice se envía al shader.
enum PokeballPattern { plain, great, ultra, master, net, safari, luxury }

/// Apariencia y datos locales de cada pokébola. El nombre oficial y la
/// descripción en español se piden a la PokeAPI (endpoint `item/<slug>`).
class PokeballStyle {
  final String slug;
  final String nombre;
  final Color top;
  final Color bottom;
  final Color band;
  final Color accent;
  final Color accent2;
  final PokeballPattern pattern;
  final double captura;
  final String capturaTexto;
  final String descripcion;
  final String dato;

  const PokeballStyle({
    required this.slug,
    required this.nombre,
    required this.top,
    this.bottom = const Color(0xFFF5F5F7),
    this.band = const Color(0xFF1D1D21),
    this.accent = Colors.transparent,
    this.accent2 = Colors.white,
    this.pattern = PokeballPattern.plain,
    required this.captura,
    required this.capturaTexto,
    required this.descripcion,
    required this.dato,
  });

  /// Color que tiñe el fondo cuando esta pokébola está seleccionada.
  Color get colorFondo => switch (pattern) {
    PokeballPattern.ultra || PokeballPattern.luxury => accent,
    _ when top.computeLuminance() > 0.8 => band,
    _ => top,
  };

  static const pokeBall = PokeballStyle(
    slug: 'poke-ball',
    nombre: 'Poké Ball',
    top: Color(0xFFE3350D),
    captura: 1,
    capturaTexto: '×1',
    descripcion: 'Dispositivo con diseño capsular que atrapa Pokémon salvajes.',
    dato: 'Es la primera que recibe todo entrenador al iniciar su aventura.',
  );

  static const todas = [
    pokeBall,
    PokeballStyle(
      slug: 'great-ball',
      nombre: 'Super Ball',
      top: Color(0xFF2F6BDB),
      accent: Color(0xFFE23A3A),
      pattern: PokeballPattern.great,
      captura: 1.5,
      capturaTexto: '×1.5',
      descripcion: 'Poké Ball de alto rendimiento.',
      dato: 'Sus franjas rojas la distinguen a simple vista en la mochila.',
    ),
    PokeballStyle(
      slug: 'ultra-ball',
      nombre: 'Ultra Ball',
      top: Color(0xFF26262B),
      accent: Color(0xFFF4C430),
      pattern: PokeballPattern.ultra,
      captura: 2,
      capturaTexto: '×2',
      descripcion: 'Poké Ball de rendimiento superior.',
      dato: 'La "H" amarilla de su parte superior es su sello característico.',
    ),
    PokeballStyle(
      slug: 'master-ball',
      nombre: 'Master Ball',
      top: Color(0xFF7A3FC0),
      accent: Color(0xFFE965A9),
      pattern: PokeballPattern.master,
      captura: 255,
      capturaTexto: 'Infalible',
      descripcion: 'Atrapa cualquier Pokémon salvaje sin fallar.',
      dato: 'Normalmente solo se consigue una por aventura: úsala con cuidado.',
    ),
    PokeballStyle(
      slug: 'premier-ball',
      nombre: 'Honor Ball',
      top: Color(0xFFF5F5F7),
      band: Color(0xFFD8262F),
      captura: 1,
      capturaTexto: '×1',
      descripcion: 'Poké Ball conmemorativa.',
      dato: 'Te la regalan al comprar 10 Poké Balls de una sola vez.',
    ),
    PokeballStyle(
      slug: 'luxury-ball',
      nombre: 'Lujo Ball',
      top: Color(0xFF1F1F24),
      bottom: Color(0xFF1F1F24),
      accent: Color(0xFFD52A3A),
      accent2: Color(0xFFE7B54A),
      pattern: PokeballPattern.luxury,
      captura: 1,
      capturaTexto: '×1',
      descripcion: 'Hace más amistosos a los Pokémon capturados.',
      dato: 'El Pokémon atrapado con ella gana amistad más rápido.',
    ),
    PokeballStyle(
      slug: 'net-ball',
      nombre: 'Malla Ball',
      top: Color(0xFF39B7C8),
      accent: Color(0xFF16161A),
      pattern: PokeballPattern.net,
      captura: 3.5,
      capturaTexto: '×3.5',
      descripcion: 'Funciona mejor con Pokémon de tipo Agua y Bicho.',
      dato: 'Su bonificación ×3.5 solo aplica a los tipos Agua y Bicho.',
    ),
    PokeballStyle(
      slug: 'safari-ball',
      nombre: 'Safari Ball',
      top: Color(0xFF5F8F33),
      bottom: Color(0xFFE6D6A8),
      accent: Color(0xFF3A5C1E),
      pattern: PokeballPattern.safari,
      captura: 1.5,
      capturaTexto: '×1.5',
      descripcion: 'Poké Ball especial de la Zona Safari.',
      dato: 'Solo puede usarse dentro de la Zona Safari o el Gran Pantano.',
    ),
  ];
}

/// Datos de la pokébola obtenidos de la PokeAPI.
class PokeballInfo {
  final String nombre;
  final String? descripcion;
  final String? spriteUrl;

  const PokeballInfo({required this.nombre, this.descripcion, this.spriteUrl});

  factory PokeballInfo.fromJson(Map<String, dynamic> json) {
    String? enEspanol(List? lista, String campo) {
      final entradas = (lista ?? [])
          .where((e) => e['language']?['name'] == 'es')
          .toList();
      return entradas.isEmpty ? null : entradas.last[campo] as String?;
    }

    return PokeballInfo(
      nombre:
          enEspanol(json['names'] as List?, 'name') ?? json['name'] as String,
      descripcion: enEspanol(
        json['flavor_text_entries'] as List?,
        'text',
      )?.replaceAll(RegExp(r'\s+'), ' '),
      spriteUrl: json['sprites']?['default'] as String?,
    );
  }
}
