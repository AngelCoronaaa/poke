/// Un entrenador tal como se guarda en la base de datos.
class Entrenador {
  final int id;
  final String usuario;
  final String nombre;
  final String passwordHash;
  final String trainerId;
  final int companero;
  final String region;
  final DateTime creadoEn;

  const Entrenador({
    required this.id,
    required this.usuario,
    required this.nombre,
    required this.passwordHash,
    required this.trainerId,
    required this.companero,
    required this.region,
    required this.creadoEn,
  });

  /// Datos públicos que recibe la app (sin el hash).
  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'trainerId': trainerId,
    'companero': companero,
    'region': region,
    'desde': creadoEn.toUtc().toIso8601String(),
  };
}

class UsuarioDuplicado implements Exception {}

/// Acceso a datos. La implementación real usa PostgreSQL; las pruebas usan
/// una en memoria.
abstract class Repositorio {
  /// Lanza [UsuarioDuplicado] si el usuario ya existe.
  Future<Entrenador> crearEntrenador({
    required String usuario,
    required String nombre,
    required String passwordHash,
    required String trainerId,
    required int companero,
    required String region,
  });

  Future<Entrenador?> buscarPorUsuario(String usuario);

  Future<void> crearSesion({
    required String tokenHash,
    required int entrenadorId,
    required DateTime expira,
  });

  /// Devuelve el entrenador si la sesión existe y no ha expirado.
  Future<Entrenador?> entrenadorDeSesion(String tokenHash);

  Future<void> borrarSesion(String tokenHash);
}
