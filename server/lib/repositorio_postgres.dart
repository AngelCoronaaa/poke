import 'dart:io';

import 'package:postgres/postgres.dart';

import 'repositorio.dart';

class RepositorioPostgres implements Repositorio {
  RepositorioPostgres._(this._db);

  final Pool<void> _db;

  /// Se conecta con [url] (formato `postgresql://usuario:clave@host:5432/db`)
  /// reintentando mientras la base de datos termina de arrancar, y aplica
  /// las migraciones de [carpetaMigraciones].
  static Future<RepositorioPostgres> conectar(
    String url, {
    required String carpetaMigraciones,
    Duration espera = const Duration(seconds: 60),
  }) async {
    final limite = DateTime.now().add(espera);
    while (true) {
      final pool = Pool<void>.withUrl(url);
      try {
        await pool.execute('SELECT 1');
        final repo = RepositorioPostgres._(pool);
        await repo._migrar(carpetaMigraciones);
        return repo;
      } catch (e) {
        await pool.close();
        if (DateTime.now().isAfter(limite)) rethrow;
        stderr.writeln('Esperando a PostgreSQL… ($e)');
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> _migrar(String carpeta) async {
    final dir = Directory(carpeta);
    if (!dir.existsSync()) {
      throw StateError('No existe la carpeta de migraciones: $carpeta');
    }
    final archivos =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.sql'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final archivo in archivos) {
      await _db.execute(
        archivo.readAsStringSync(),
        queryMode: QueryMode.simple,
      );
      stdout.writeln('Migración aplicada: ${archivo.uri.pathSegments.last}');
    }
  }

  Entrenador _fila(ResultRow fila) {
    final m = fila.toColumnMap();
    return Entrenador(
      id: m['id'] as int,
      usuario: m['usuario'] as String,
      nombre: m['nombre'] as String,
      passwordHash: m['password_hash'] as String,
      trainerId: m['trainer_id'] as String,
      companero: m['companero'] as int,
      region: m['region'] as String,
      creadoEn: m['creado_en'] as DateTime,
    );
  }

  static const _columnas =
      'e.id, e.usuario, e.nombre, e.password_hash, e.trainer_id, '
      'e.companero, e.region, e.creado_en';

  @override
  Future<Entrenador> crearEntrenador({
    required String usuario,
    required String nombre,
    required String passwordHash,
    required String trainerId,
    required int companero,
    required String region,
  }) async {
    try {
      final r = await _db.execute(
        Sql.named(
          'INSERT INTO entrenadores AS e '
          '(usuario, nombre, password_hash, trainer_id, companero, region) '
          'VALUES (@usuario, @nombre, @hash, @trainerId, @companero, @region) '
          'RETURNING $_columnas',
        ),
        parameters: {
          'usuario': usuario,
          'nombre': nombre,
          'hash': passwordHash,
          'trainerId': trainerId,
          'companero': companero,
          'region': region,
        },
      );
      return _fila(r.first);
    } on UniqueViolationException {
      throw UsuarioDuplicado();
    }
  }

  @override
  Future<Entrenador?> buscarPorUsuario(String usuario) async {
    final r = await _db.execute(
      Sql.named('SELECT $_columnas FROM entrenadores e WHERE e.usuario = @u'),
      parameters: {'u': usuario},
    );
    return r.isEmpty ? null : _fila(r.first);
  }

  @override
  Future<void> crearSesion({
    required String tokenHash,
    required int entrenadorId,
    required DateTime expira,
  }) async {
    await _db.execute(
      Sql.named(
        'INSERT INTO sesiones (token_hash, entrenador_id, expira_en) '
        'VALUES (@t, @id, @expira)',
      ),
      parameters: {'t': tokenHash, 'id': entrenadorId, 'expira': expira},
    );
  }

  @override
  Future<Entrenador?> entrenadorDeSesion(String tokenHash) async {
    final r = await _db.execute(
      Sql.named(
        'SELECT $_columnas FROM sesiones s '
        'JOIN entrenadores e ON e.id = s.entrenador_id '
        'WHERE s.token_hash = @t AND s.expira_en > now()',
      ),
      parameters: {'t': tokenHash},
    );
    return r.isEmpty ? null : _fila(r.first);
  }

  @override
  Future<void> borrarSesion(String tokenHash) async {
    await _db.execute(
      Sql.named('DELETE FROM sesiones WHERE token_hash = @t'),
      parameters: {'t': tokenHash},
    );
  }

  Future<void> cerrar() => _db.close();
}
