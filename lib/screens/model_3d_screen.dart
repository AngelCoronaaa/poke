import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/glass.dart';
import '../widgets/pokemon_model_view.dart';

/// Visor 3D a pantalla completa: girar, acercar y ver en realidad aumentada.
class Model3DScreen extends StatelessWidget {
  const Model3DScreen({super.key, required this.pokemon});

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    final atenuado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.55);

    return LiquidBackground(
      accent: pokemon.color,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GlassButton(
                      circular: true,
                      tooltip: 'Regresar',
                      onPressed: () => Navigator.maybePop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pokemon.displayName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${pokemon.number} · Modelo 3D',
                            style: TextStyle(color: atenuado, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PokemonModelView(
                  src: PokemonService.modelo3DUrl(pokemon.id),
                  nombre: pokemon.displayName,
                  poster: pokemon.imageUrl,
                  interactivo: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GlassContainer(
                  radius: 22,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 18, color: atenuado),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Arrastra para girar · pellizca para acercar',
                          style: TextStyle(color: atenuado, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
