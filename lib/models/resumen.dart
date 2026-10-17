/// Conteos generales que se piden a la PokeAPI para la pantalla de inicio.
class ResumenPokedex {
  final int pokemon;
  final int movimientos;
  final int habilidades;
  final int objetos;
  final int generaciones;
  final int regiones;

  const ResumenPokedex({
    required this.pokemon,
    required this.movimientos,
    required this.habilidades,
    required this.objetos,
    required this.generaciones,
    required this.regiones,
  });

  /// Endpoints consultados, en el mismo orden que [ResumenPokedex.fromCounts].
  static const recursos = [
    'pokemon-species',
    'move',
    'ability',
    'item',
    'generation',
    'region',
  ];

  factory ResumenPokedex.fromCounts(List<int> c) => ResumenPokedex(
    pokemon: c[0],
    movimientos: c[1],
    habilidades: c[2],
    objetos: c[3],
    generaciones: c[4],
    regiones: c[5],
  );
}
