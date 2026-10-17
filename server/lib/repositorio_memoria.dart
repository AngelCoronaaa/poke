import 'repositorio.dart';

/// Repositorio en memoria para las pruebas del API.
class RepositorioMemoria implements Repositorio {
  final _entrenadores = <String, Entrenador>{};
  final _sesiones = <String, (int, DateTime)>{};
  var _siguienteId = 1;

  @override
  Future<Entrenador> crearEntrenador({
    required String usuario,
    required String nombre,
    required String passwordHash,
    required String trainerId,
    required int companero,
    required String region,
  }) async {
    if (_entrenadores.containsKey(usuario)) throw UsuarioDuplicado();
    return _entrenadores[usuario] = Entrenador(
      id: _siguienteId++,
      usuario: usuario,
      nombre: nombre,
      passwordHash: passwordHash,
      trainerId: trainerId,
      companero: companero,
      region: region,
      creadoEn: DateTime.now(),
    );
  }

  @override
  Future<Entrenador?> buscarPorUsuario(String usuario) async =>
      _entrenadores[usuario];

  @override
  Future<void> crearSesion({
    required String tokenHash,
    required int entrenadorId,
    required DateTime expira,
  }) async => _sesiones[tokenHash] = (entrenadorId, expira);

  @override
  Future<Entrenador?> entrenadorDeSesion(String tokenHash) async {
    final sesion = _sesiones[tokenHash];
    if (sesion == null || sesion.$2.isBefore(DateTime.now())) return null;
    return _entrenadores.values.where((e) => e.id == sesion.$1).firstOrNull;
  }

  @override
  Future<void> borrarSesion(String tokenHash) async =>
      _sesiones.remove(tokenHash);

  /// Para las pruebas: cuántas filas hay guardadas.
  int get totalEntrenadores => _entrenadores.length;
  Iterable<Entrenador> get entrenadores => _entrenadores.values;
}
