# Pokédex

App en Flutter que consume la [PokeAPI](https://pokeapi.co/) con **Dio**, con cuentas de entrenador guardadas en **PostgreSQL**.

- **Cuentas de entrenador:** registro con nombre, contraseña, compañero y región, e inicio de sesión. Las cuentas viven en PostgreSQL a través de un API propio (`server/`). Las contraseñas se guardan con bcrypt; en el dispositivo solo queda el token de sesión.
- **Inicio:** licencia de entrenador, datos generales de la PokeAPI, Pokémon del día y regiones.
- **Pokédex:** ficha de cada Pokémon (`pokemon/<id>/` convertido a la clase `Pokemon`) con su modelo 3D animado (Android, iOS y web) o su ilustración con volumen.
- **Pokéballs 3D:** 8 tipos dibujados con un shader propio, que se giran arrastrando. Su nombre y descripción vienen del endpoint `item/<slug>/`.
- Diseño *liquid glass* con modo claro, oscuro o del sistema.

## Deploy

El `Dockerfile` de la raíz genera una sola imagen: compila la app para web y el servidor en Dart, y el servidor sirve ambos en la misma dirección.

| Variable | Uso |
|---|---|
| `DATABASE_URL` | **Obligatoria.** `postgresql://usuario:clave@host:5432/db` (agrega `?sslmode=require` si la base exige SSL) |
| `PORT` | Puerto HTTP (8080 por defecto) |

Al arrancar, el servidor espera a que PostgreSQL esté listo y ejecuta `server/migrations/*.sql`, que son idempotentes.

## Ejecutar en local

Todo con Docker (app web + API + PostgreSQL) en http://localhost:8080:

```bash
docker compose up --build
```

Para desarrollar la app contra ese servidor:

```bash
flutter pub get
flutter run                                       # Android (emulador) / iOS / escritorio
flutter run -d chrome --dart-define=API_URL=http://localhost:8080
```

Para apuntar a la versión desplegada: `--dart-define=API_URL=https://tu-dominio`.

### API (`server/`)

| Método | Ruta | Cuerpo / encabezado | Respuesta |
|---|---|---|---|
| POST | `/api/registro` | `{nombre, password, companero, region}` | 201 `{token, trainer}` · 409 si el nombre ya existe |
| POST | `/api/login` | `{nombre, password}` | 200 `{token, trainer}` · 401 |
| GET | `/api/sesion` | `Authorization: Bearer <token>` | 200 `{trainer}` · 401 |
| POST | `/api/logout` | `Authorization: Bearer <token>` | 204 |
| GET | `/health` | | 200 |

Pruebas del servidor: `cd server && dart test`.

## Estructura

- `lib/services/pokemon_service.dart`: peticiones a la PokeAPI con Dio.
- `lib/services/auth_service.dart`: registro e inicio de sesión contra el API.
- `lib/models/`: clases `Pokemon`, `Trainer`, `Region`, `PokeballStyle`, etc.
- `lib/screens/`: login, inicio, Pokédex, visor 3D y pokébolas.
- `lib/widgets/`: vidrio, pokébola 3D, figura del Pokémon y animaciones.
- `shaders/pokeball.frag`: render 3D de las pokébolas.
- `server/`: API en Dart (shelf + postgres + bcrypt) y migraciones SQL.

Los modelos 3D vienen del proyecto [Pokemon-3D-api](https://github.com/Pokemon-3D-api/assets).
