import 'dart:io';

import 'package:pokedex_server/api.dart';
import 'package:pokedex_server/repositorio_postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Variables de entorno:
/// - `DATABASE_URL` (obligatoria): `postgresql://usuario:clave@host:5432/db`.
///   Agrega `?sslmode=require` si el servidor de base de datos exige SSL.
/// - `PORT` (opcional, 8080 por defecto).
/// - `WEB_DIR` (opcional): carpeta con la app compilada para web (`public`).
/// - `MIGRATIONS_DIR` (opcional): carpeta de migraciones (`migrations`).
Future<void> main() async {
  final env = Platform.environment;
  final url = env['DATABASE_URL'];
  if (url == null || url.isEmpty) {
    stderr.writeln('Falta la variable de entorno DATABASE_URL');
    exit(1);
  }

  final repo = await RepositorioPostgres.conectar(
    url,
    carpetaMigraciones: env['MIGRATIONS_DIR'] ?? 'migrations',
  );
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(crearHandler(repo, carpetaWeb: env['WEB_DIR'] ?? 'public'));

  final puerto = int.tryParse(env['PORT'] ?? '') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, puerto);
  stdout.writeln('Pokédex escuchando en el puerto ${server.port}');

  ProcessSignal.sigterm.watch().listen((_) async {
    await server.close();
    await repo.cerrar();
    exit(0);
  });
}
