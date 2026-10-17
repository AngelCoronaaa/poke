# Imagen única: la app Flutter compilada para web + el API en Dart.
# El servidor lee DATABASE_URL (PostgreSQL) y PORT del entorno, aplica
# server/migrations al arrancar y sirve la app web en la misma dirección.

# 1) App Flutter para web
FROM ghcr.io/cirruslabs/flutter:stable AS web
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release

# 2) Servidor Dart compilado a ejecutable nativo
FROM dart:stable AS server
WORKDIR /server
COPY server/pubspec.yaml server/pubspec.lock ./
RUN dart pub get
COPY server/ .
RUN dart compile exe bin/server.dart -o /server/pokedex_server

# 3) Imagen final
FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=server /server/pokedex_server ./pokedex_server
COPY server/migrations ./migrations
COPY --from=web /app/build/web ./public

ENV PORT=8080
EXPOSE 8080
CMD ["./pokedex_server"]
