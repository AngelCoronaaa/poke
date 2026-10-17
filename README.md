# Pokédex

App en Flutter que consume la [PokeAPI](https://pokeapi.co/) con **Dio**.

- **Login de entrenador:** nombre, compañero y región, guardados en el dispositivo (`shared_preferences`).
- **Inicio:** licencia de entrenador, datos generales de la PokeAPI, Pokémon del día y regiones.
- **Pokédex:** ficha de cada Pokémon (`pokemon/<id>/` convertido a la clase `Pokemon`) con su modelo 3D animado (Android, iOS y web) o su ilustración con volumen.
- **Pokéballs 3D:** 8 tipos dibujados con un shader propio, que se giran arrastrando. Su nombre y descripción vienen del endpoint `item/<slug>/`.
- Diseño *liquid glass* con modo claro, oscuro o del sistema.

## Ejecutar

```bash
flutter pub get
flutter run
```

## Estructura

- `lib/services/pokemon_service.dart`: peticiones con Dio.
- `lib/models/`: clases `Pokemon`, `Trainer`, `Region`, `PokeballStyle`, etc.
- `lib/screens/`: login, inicio, Pokédex, visor 3D y pokébolas.
- `lib/widgets/`: vidrio, pokébola 3D, figura del Pokémon y animaciones.
- `shaders/pokeball.frag`: render 3D de las pokébolas.

Los modelos 3D vienen del proyecto [Pokemon-3D-api](https://github.com/Pokemon-3D-api/assets).
